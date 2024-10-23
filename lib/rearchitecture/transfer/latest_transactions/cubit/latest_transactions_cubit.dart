import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'latest_transactions_state.dart';

class LatestTransactionsCubit extends Cubit<LatestTransactionsState> {
  final Zenon zenon;

  LatestTransactionsCubit(this.zenon)
      : super(LatestTransactionsState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final accountBlock = await zenon.ledger.getAccountBlocksByPage(
        Address.parse('kDemoAddress'),
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final data = accountBlock.list!;

      emit(state.copyWith(status: CubitStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
