import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_list_state.dart';


class SentinelListCubit extends Cubit<SentinelListState> {
  final Zenon zenon;

  SentinelListCubit(this.zenon)
      : super(SentinelListState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final sentinelInfoList = await zenon.embedded.sentinel.getAllActive(
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final data = sentinelInfoList.list;

      emit(state.copyWith(status: CubitStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
