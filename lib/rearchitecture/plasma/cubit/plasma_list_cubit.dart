import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'plasma_list_state.dart';


class PlasmaListCubit extends Cubit<PlasmaListState> {
  final Zenon zenon;
  int? lastMomentumHeight;

  PlasmaListCubit(this.zenon)
      : super(PlasmaListState(
    status: CubitStatus.initial,
  ));

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final fusionEntryList = await zenon.embedded.plasma.getEntriesByAddress(
        Address.parse('kDemoAddress'),
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final results = fusionEntryList.list;

      final lastMomentum = await zenon.ledger.getFrontierMomentum();
      lastMomentumHeight = lastMomentum.height;
      for (final fusionEntry in results) {
        fusionEntry.isRevocable =
            lastMomentum.height > fusionEntry.expirationHeight;
      }
      emit(state.copyWith(status: CubitStatus.success, data: results));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
