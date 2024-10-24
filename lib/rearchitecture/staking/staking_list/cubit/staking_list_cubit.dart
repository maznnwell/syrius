import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_list_state.dart';


class StakingListCubit extends Cubit<StakingListState> {
  final Zenon zenon;

  StakingListCubit(this.zenon)
      : super(StakingListState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final stakeList = await zenon.embedded.stake.getEntriesByAddress(
        Address.parse('kDemoAddress'),
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final data = stakeList.list;

      emit(state.copyWith(status: CubitStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
