import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'account_chain_stats.dart';
part 'account_chain_stats_state.dart';

class AccountChainStatsCubit extends Cubit<AccountChainStatsState> {
  final Zenon zenon;

  AccountChainStatsCubit(this.zenon)
      : super(AccountChainStatsState(
    status: CubitStatus.initial,
  ));

  Future<void> getDataAsync() async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final accountInfo =
      await zenon.ledger.getAccountInfoByAddress(
        Address.parse(
            'kDemoAddress',
        ),
      );

      final pageSize = accountInfo.blockCount!;
      final pageCount = ((pageSize + 1) / rpcMaxPageSize).ceil();

      if (pageSize > 0) {
        final List<AccountBlock> allBlocks = [];

        for (var i = 0; i < pageCount; i++) {
          allBlocks.addAll((await zenon.ledger.getAccountBlocksByHeight(
            Address.parse(
              'kDemoAddress',
            ),
            (rpcMaxPageSize * i) + 1,
            rpcMaxPageSize,
          ))
              .list ??
              []);
        }

        final data = AccountChainStats(
          firstHash: allBlocks.isNotEmpty ? allBlocks.first.hash : emptyHash,
          blockCount: pageSize,
          blockTypeNumOfBlocksMap: _getNumOfBlocksForEachBlockType(allBlocks),
        );
        emit(state.copyWith(status: CubitStatus.success, data: data));
      } else {
        throw 'Empty account-chain';
      }
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }

  Map<BlockTypeEnum, int> _getNumOfBlocksForEachBlockType(
      List<AccountBlock> blocks) =>
      BlockTypeEnum.values.fold<Map<BlockTypeEnum, int>>(
        {},
            (previousValue, blockType) {
          previousValue[blockType] =
              _getNumOfBlockForBlockType(blocks, blockType);
          return previousValue;
        },
      );

  int _getNumOfBlockForBlockType(
      List<AccountBlock> blocks, BlockTypeEnum blockType) =>
      blocks.fold<int>(
        0,
            (dynamic previousValue, element) {
          if (element.blockType == blockType.index) {
            return previousValue + 1;
          }
          return previousValue;
        },
      );
}
