import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_unlock_htlc_worker.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/block_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/date_time_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapsHandler {
  static HtlcSwapsHandler? _instance;

  bool _isRunning = false;
  Timer? _timer;
  Future<void>? _currentRun;

  static HtlcSwapsHandler getInstance() {
    _instance ??= HtlcSwapsHandler();
    return _instance!;
  }

  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _currentRun = _runPeriodically();
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    await _currentRun;
    _currentRun = null;
  }

  Future<bool> get hasActiveIncomingSwaps async =>
      (await sl<HtlcSwapRepository>().getSwapsByState(<P2pSwapState>[
        P2pSwapState.active,
      ])).any((HtlcSwap swap) => swap.direction == P2pSwapDirection.incoming);

  Future<void> _runPeriodically() async {
    try {
      await _enableWakelockIfNeeded();
      if (!zenon!.wsClient.isClosed()) {
        final List<HtlcSwap> unresolvedSwaps = await sl<HtlcSwapRepository>()
            .getSwapsByState(<P2pSwapState>[
              P2pSwapState.pending,
              P2pSwapState.active,
              P2pSwapState.reclaimable,
            ]);
        if (unresolvedSwaps.isNotEmpty) {
          if (await _areThereNewHtlcBlocks()) {
            final List<AccountBlock> newBlocks = await _getNewHtlcBlocks(
              unresolvedSwaps,
            );
            await _goThroughHtlcBlocks(newBlocks);
          }
          await _checkForExpiredSwaps();
          await _checkForAutoUnlockableSwaps();
        }
        await sl<AutoUnlockHtlcWorker>().autoUnlock();
      }
    } catch (e) {
      Logger('HtlcSwapsHandler').log(Level.WARNING, '_runPeriodically', e);
    } finally {
      if (_isRunning) {
        _timer = Timer(const Duration(seconds: 5), () {
          _currentRun = _runPeriodically();
        });
      }
    }
  }

  Future<void> _enableWakelockIfNeeded() async {
    if (await hasActiveIncomingSwaps) {
      try {
        await WakelockPlus.enable();
      } catch (e) {
        Logger(
          'HtlcSwapsHandler',
        ).log(Level.WARNING, '_enableWakelockIfNeeded', e);
      }
    }
  }

  Future<int?> _getHtlcFrontierHeight() async {
    try {
      final AccountBlock? frontier = await zenon!.ledger
          .getFrontierAccountBlock(htlcAddress);
      return frontier?.height;
    } catch (e, stackTrace) {
      Logger(
        'HtlcSwapsHandler',
      ).log(Level.WARNING, '_getHtlcFrontierHeight', e, stackTrace);
    }
    return null;
  }

  Future<bool> _areThereNewHtlcBlocks() async {
    final int? frontier = await _getHtlcFrontierHeight();
    return frontier != null &&
        frontier >
            (await sl<HtlcSwapRepository>().getLastCheckedHtlcBlockHeight());
  }

  Future<List<AccountBlock>> _getNewHtlcBlocks(List<HtlcSwap> swaps) async {
    final int lastCheckedHeight = await sl<HtlcSwapRepository>()
        .getLastCheckedHtlcBlockHeight();
    final int oldestSwapStartTime = _getOldestSwapStartTime(swaps) ?? 0;
    int lastCheckedBlockTime = 0;

    if (lastCheckedHeight > 0) {
      try {
        lastCheckedBlockTime =
            (await AccountBlockUtils.getTimeForAccountBlockHeight(
              htlcAddress,
              lastCheckedHeight,
            )) ??
            lastCheckedBlockTime;
      } catch (e, stackTrace) {
        Logger(
          'HtlcSwapsHandler',
        ).log(Level.WARNING, '_getNewHtlcBlocks', e, stackTrace);
        return <AccountBlock>[];
      }
    }

    try {
      return await AccountBlockUtils.getAccountBlocksAfterTime(
        htlcAddress,
        max(oldestSwapStartTime, lastCheckedBlockTime),
      );
    } catch (e, stackTrace) {
      Logger(
        'HtlcSwapsHandler',
      ).log(Level.WARNING, '_getNewHtlcBlocks', e, stackTrace);
      return <AccountBlock>[];
    }
  }

  Future<void> _goThroughHtlcBlocks(List<AccountBlock> blocks) async {
    for (final AccountBlock block in blocks) {
      final HtlcSwap? updatedSwap = await _getSwapUpdateFromBlock(block);
      await sl<HtlcSwapRepository>().storeProcessedHtlcBlock(
        height: block.height,
        updatedSwap: updatedSwap,
      );
    }
  }

  Future<HtlcSwap?> _getSwapUpdateFromBlock(AccountBlock htlcBlock) async {
    if (htlcBlock.blockType != BlockTypeEnum.contractReceive.index) {
      return null;
    }

    final AccountBlock pairedBlock = htlcBlock.pairedAccountBlock!;
    final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
      Definitions.htlc,
      pairedBlock.data,
    );

    if (blockData == null) {
      return null;
    }

    final HtlcSwap? swap = await _tryGetSwapFromBlockData(blockData);
    if (swap == null) {
      return null;
    }

    if (swap.chainId != pairedBlock.chainIdentifier) {
      return null;
    }

    switch (blockData.function) {
      case 'Create':
        if (swap.state == P2pSwapState.pending) {
          return swap.copyWith(state: P2pSwapState.active);
        } else if (swap.state == P2pSwapState.active &&
            pairedBlock.hash.toString() != swap.initialHtlcId &&
            swap.counterHtlcId == null) {
          if (!_isValidCounterHtlc(pairedBlock, blockData, swap)) {
            return null;
          }
          return swap.copyWith(
            counterHtlcId: pairedBlock.hash.toString(),
            toAmount: pairedBlock.amount,
            toToken: pairedBlock.token!,
            counterHtlcExpirationTime: blockData.params['expirationTime']
                .toInt(),
          );
        }
        return null;
      case 'Unlock':
        if (htlcBlock.descendantBlocks.isEmpty) {
          return null;
        }
        HtlcSwap updatedSwap = swap;
        bool wasUpdated = false;
        if (updatedSwap.preimage == null) {
          if (!blockData.params.containsKey('preimage')) {
            return null;
          }
          updatedSwap = updatedSwap.copyWith(
            preimage: FormatUtils.encodeHexString(blockData.params['preimage']),
          );
          wasUpdated = true;
        }

        if (updatedSwap.direction == P2pSwapDirection.incoming &&
            blockData.params['id'].toString() == updatedSwap.initialHtlcId) {
          return updatedSwap.copyWith(state: P2pSwapState.completed);
        }

        // Handle the situation where the counter HTLC of an outgoing swap
        // has been unlocked by someone else.
        if (updatedSwap.direction == P2pSwapDirection.outgoing &&
            updatedSwap.state == P2pSwapState.active &&
            blockData.params['id'].toString() == updatedSwap.counterHtlcId) {
          return updatedSwap.copyWith(state: P2pSwapState.completed);
        }
        return wasUpdated ? updatedSwap : null;
      case 'Reclaim':
        if (htlcBlock.descendantBlocks.isEmpty) {
          return null;
        }
        bool isSelfReclaim = false;
        if (swap.direction == P2pSwapDirection.outgoing &&
            blockData.params['id'].toString() == swap.initialHtlcId) {
          isSelfReclaim = true;
        } else if (swap.direction == P2pSwapDirection.incoming &&
            blockData.params['id'].toString() == swap.counterHtlcId) {
          isSelfReclaim = true;
        }
        if (isSelfReclaim) {
          return swap.copyWith(state: P2pSwapState.unsuccessful);
        }
        return null;
    }
    return null;
  }

  Future<HtlcSwap?> _tryGetSwapFromBlockData(BlockData data) async {
    HtlcSwap? swap;
    if (data.params.containsKey('id')) {
      swap = await sl<HtlcSwapRepository>().getSwapByHtlcId(
        data.params['id'].toString(),
      );
    }
    if (data.params.containsKey('hashLock') && swap == null) {
      swap = await sl<HtlcSwapRepository>().getSwapByHashLock(
        Hash.fromBytes(data.params['hashLock']).toString(),
      );
    }
    return swap;
  }

  bool _isValidCounterHtlc(AccountBlock block, BlockData data, HtlcSwap swap) {
    // Verify that the recipient is the initiator's address
    if (!data.params.containsKey('hashLocked') ||
        data.params['hashLocked'] != Address.parse(swap.selfAddress)) {
      return false;
    }

    // Verify that the creator is the counterparty.
    if (block.address != Address.parse(swap.counterpartyAddress)) {
      return false;
    }

    // Verify that the hash types match.
    if (!data.params.containsKey('hashType') ||
        data.params['hashType'].toInt() != swap.hashType) {
      return false;
    }

    // Verify that block data contains an expiration time parameter.
    if (!data.params.containsKey('expirationTime')) {
      return false;
    }

    return true;
  }

  Future<void> _checkForExpiredSwaps() async {
    final List<HtlcSwap> swaps = await sl<HtlcSwapRepository>().getSwapsByState(
      <P2pSwapState>[P2pSwapState.pending, P2pSwapState.active],
    );
    final int now = DateTime.now().unixTimestamp;
    for (final HtlcSwap swap in swaps) {
      if (swap.initialHtlcExpirationTime < now ||
          (swap.counterHtlcExpirationTime != null &&
              swap.counterHtlcExpirationTime! -
                      kMinSafeTimeToCompleteSwap.inSeconds <
                  now)) {
        await sl<HtlcSwapRepository>().storeSwap(
          swap.copyWith(state: P2pSwapState.reclaimable),
        );
      }
    }
  }

  Future<void> _checkForAutoUnlockableSwaps() async {
    // It is important to check swaps that are in reclaimable state as well,
    // since the counterparty may have published the preimage at the last moment
    // before the HTLC would have expired. In this situation the swap's state
    // may have already been changed to reclaimable.
    final List<HtlcSwap> swaps = await sl<HtlcSwapRepository>().getSwapsByState(
      <P2pSwapState>[P2pSwapState.active, P2pSwapState.reclaimable],
    );
    for (final HtlcSwap swap in swaps) {
      if (swap.direction == P2pSwapDirection.incoming &&
          swap.preimage != null) {
        sl<AutoUnlockHtlcWorker>().addHash(Hash.parse(swap.initialHtlcId));
      }
    }
  }

  int? _getOldestSwapStartTime(List<HtlcSwap> swaps) {
    return swaps.isNotEmpty
        ? swaps
              .reduce(
                (HtlcSwap e1, HtlcSwap e2) =>
                    e1.startTime > e2.startTime ? e1 : e2,
              )
              .startTime
        : null;
  }
}
