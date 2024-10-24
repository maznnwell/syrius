
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pillar_uncollected_rewards_state.dart';

class PillarUncollectedRewardsCubit extends Cubit<PillarUncollectedRewardsState> {
  final Zenon zenon;

  PillarUncollectedRewardsCubit(this.zenon)
      : super(PillarUncollectedRewardsState(
    status: CubitStatus.initial,
  ));


  Future<void> getDataAsync() async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final response = await zenon.embedded.pillar
          .getUncollectedReward(Address.parse('kDemoAddress'));

      emit(state.copyWith(status: CubitStatus.success, data: response));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
