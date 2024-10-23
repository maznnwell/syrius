import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pending_transactions_state.dart';


class PendingTransactionsCubit extends Cubit<PendingTransactionsState> {
  final Zenon zenon;

  PendingTransactionsCubit(this.zenon)
      : super(PendingTransactionsState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final accountBlock = await zenon.ledger.getUnreceivedBlocksByAddress(
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
