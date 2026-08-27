import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/block_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_for_swap/utils/htlc_info_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Fetches and validates an initial HTLC before joining a swap.
class InitialHtlcForSwapBloc extends BaseBloc<HtlcInfo> {
  /// Fetches the HTLC identified by [id] and emits it when it is valid.
  Future<void> getInitialHtlc(Hash id) async {
    try {
      final HtlcInfo htlc = await zenon!.embedded.htlc.getById(id);

      _validateParticipants(htlc);
      _validateUnusedDeposit(htlc);
      _validateExpiration(htlc.expirationTime);
      await _validateCreationDuration(htlc);
      await _validateUniqueHashLock(htlc);

      addEvent(htlc);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  void _validateParticipants(HtlcInfo htlc) {
    if (!kDefaultAddressList.contains(htlc.hashLocked.toString())) {
      throw SyriusException('This deposit is not intended for you.');
    }
    if (kDefaultAddressList.contains(htlc.timeLocked.toString())) {
      throw SyriusException('Cannot join a swap that you have started.');
    }
  }

  void _validateUnusedDeposit(HtlcInfo htlc) {
    if (htlcSwapsService!.getSwapByHtlcId(htlc.id.toString()) != null) {
      throw SyriusException(
        'This deposit is already used in another swap.',
      );
    }
    if (htlcSwapsService!.getSwapByHashLock(htlc.hashLockHex) != null) {
      throw SyriusException(
        "The deposit's hashlock is already used in another swap.",
      );
    }
  }

  void _validateExpiration(int expirationTime) {
    final Duration minimumRequiredDuration =
        kMinSafeTimeToFindPreimage + kCounterHtlcDuration;

    final Duration remainingDuration = Duration(
      seconds: expirationTime - DateTimeUtils.unixTimeNow,
    );
    if (remainingDuration.inSeconds <= 0) {
      throw SyriusException('This deposit has expired.');
    }
    if (remainingDuration < minimumRequiredDuration) {
      throw SyriusException(
        'This deposit will expire too soon for a safe swap.',
      );
    }

    _validateMaximumDuration(remainingDuration);
  }

  Future<void> _validateCreationDuration(HtlcInfo htlc) async {
    final AccountBlock? creationBlock = await zenon!.ledger
        .getAccountBlockByHash(htlc.id);
    final int? creationTime =
        creationBlock?.confirmationDetail?.momentumTimestamp;
    if (creationTime == null) {
      throw SyriusException('Unable to verify the deposit creation time.');
    }

    _validateMaximumDuration(
      Duration(seconds: htlc.expirationTime - creationTime),
    );
  }

  void _validateMaximumDuration(Duration duration) {
    if (duration > kMaxAllowedInitialHtlcDuration) {
      throw SyriusException(
        "The deposit's duration is too long. Expected "
        '${kMaxAllowedInitialHtlcDuration.inHours} hours at most.',
      );
    }
  }

  Future<void> _validateUniqueHashLock(HtlcInfo htlc) async {
    final List<AccountBlock> htlcBlocks =
        await AccountBlockUtils.getAccountBlocksAfterTime(
          htlcAddress,
          htlc.expirationTime - kMaxAllowedInitialHtlcDuration.inSeconds,
        );
    final bool hasDuplicate = htlcBlocks.any(
      (AccountBlock block) => _isConflictingHtlcBlock(block, htlc),
    );
    if (hasDuplicate) {
      throw SyriusException('The hashlock is not unique.');
    }
  }

  bool _isConflictingHtlcBlock(
    AccountBlock block,
    HtlcInfo htlc,
  ) {
    if (block.blockType != BlockTypeEnum.contractReceive.index) {
      return false;
    }

    final AccountBlock? pairedBlock = block.pairedAccountBlock;
    if (pairedBlock == null || pairedBlock.hash == htlc.id) {
      return false;
    }

    final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
      Definitions.htlc,
      pairedBlock.data,
    );
    if (blockData == null || blockData.function != 'Create') {
      return false;
    }

    final Object? encodedHashLock = blockData.params['hashLock'];
    if (encodedHashLock is! List<int>) {
      return false;
    }

    return FormatUtils.encodeHexString(encodedHashLock) == htlc.hashLockHex;
  }
}
