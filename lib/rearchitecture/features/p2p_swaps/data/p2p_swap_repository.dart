import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';

abstract class P2pSwapRepository<T extends P2pSwap> {
  Future<List<T>> getAllSwaps();

  Stream<List<T>> watchAllSwaps();

  Future<List<T>> getSwapsByState(List<P2pSwapState> states);

  Future<T?> getSwapById(String id);

  Future<void> storeSwap(T swap);

  Future<void> deleteSwap(String swapId);

  Future<void> deleteInactiveSwaps();
}
