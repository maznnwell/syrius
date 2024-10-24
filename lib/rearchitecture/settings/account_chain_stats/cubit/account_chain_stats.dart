part of 'account_chain_stats_cubit.dart';

class AccountChainStats {
  final Hash firstHash;
  final int blockCount;
  final Map<BlockTypeEnum, int> blockTypeNumOfBlocksMap;

  AccountChainStats({
    required this.firstHash,
    required this.blockCount,
    required this.blockTypeNumOfBlocksMap,
  });
}