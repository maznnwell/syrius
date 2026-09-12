import 'dart:convert';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/p2p_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class HtlcSwapRepository extends P2pSwapRepository<HtlcSwap> {
  HtlcSwapRepository({
    required this._chainIdProvider,
    required this._dataProvider,
  });

  final int? Function() _chainIdProvider;
  final HtlcSwapLocalStorageApi _dataProvider;

  @override
  Future<List<HtlcSwap>> getAllSwaps() async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return <HtlcSwap>[];
    }

    final List<HtlcSwapEntry> entries = await _dataProvider.readAllSwapEntries(
      chainId,
    );
    return entries.map(_decodeSwap).toList();
  }

  @override
  Future<List<HtlcSwap>> getSwapsByState(
    List<P2pSwapState> states,
  ) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null || states.isEmpty) {
      return <HtlcSwap>[];
    }

    final List<HtlcSwapEntry> entries = await _dataProvider
        .readSwapEntriesByState(
          chainId,
          states.map((state) => state.name).toList(),
        );
    return entries.map(_decodeSwap).toList();
  }

  Future<HtlcSwap?> getSwapByHashLock(String hashLock) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return null;
    }

    return _decodeNullableSwap(
      await _dataProvider.readSwapEntryByHashLock(chainId, hashLock),
    );
  }

  Future<HtlcSwap?> getSwapByHtlcId(String htlcId) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return null;
    }

    return _decodeNullableSwap(
      await _dataProvider.readSwapEntryByHtlcId(chainId, htlcId),
    );
  }

  @override
  Future<HtlcSwap?> getSwapById(String id) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return null;
    }

    return _decodeNullableSwap(
      await _dataProvider.readSwapEntryById(chainId, id),
    );
  }

  Future<int> getLastCheckedHtlcBlockHeight() async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return 0;
    }

    return _dataProvider.readLastCheckedHtlcBlockHeight(chainId);
  }

  @override
  Future<void> storeSwap(HtlcSwap swap) => _dataProvider.writeSwapEntry(
    _encodeSwap(swap),
    maximumStoredSwaps: kMaxP2pSwapsToStore,
    pruneChainId: _chainIdProvider(),
    prunableStates: <String>[
      P2pSwapState.completed.name,
      P2pSwapState.unsuccessful.name,
    ],
  );

  Future<void> storeLastCheckedHtlcBlockHeight(int height) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      throw StateError('Cannot store an HTLC checkpoint without a chain id');
    }

    await _dataProvider.writeLastCheckedHtlcBlockHeight(chainId, height);
  }

  @override
  Future<void> deleteSwap(String swapId) =>
      _dataProvider.deleteSwapEntry(swapId);

  @override
  Future<void> deleteInactiveSwaps() async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return;
    }

    await _dataProvider.deleteSwapEntriesByState(chainId, <String>[
      P2pSwapState.completed.name,
      P2pSwapState.unsuccessful.name,
      P2pSwapState.error.name,
    ]);
  }

  HtlcSwapEntry _encodeSwap(HtlcSwap swap) => HtlcSwapEntry(
    id: swap.id,
    chainId: swap.chainId,
    state: swap.state.name,
    direction: swap.direction.name,
    hashLock: swap.hashLock,
    initialHtlcId: swap.initialHtlcId,
    counterHtlcId: swap.counterHtlcId,
    startTime: swap.startTime,
    payloadJson: jsonEncode(swap.toJson()),
  );

  HtlcSwap? _decodeNullableSwap(HtlcSwapEntry? entry) =>
      entry == null ? null : _decodeSwap(entry);

  HtlcSwap _decodeSwap(HtlcSwapEntry entry) {
    return P2pSwap.fromJson(
          jsonDecode(entry.payloadJson) as Map<String, dynamic>,
        )
        as HtlcSwap;
  }
}
