import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_list_state.dart';


class PillarsListCubit extends Cubit<PillarsListState> {
  final Zenon zenon;

  PillarsListCubit(this.zenon)
      : super(PillarsListState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final pillarInfoList = await zenon.embedded.pillar.getAll(
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final data = pillarInfoList.list;

      emit(state.copyWith(status: CubitStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
