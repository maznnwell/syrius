import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_uncollected_rewards_state.dart';

class StakingUncollectedRewardsCubit extends Cubit<StakingUncollectedRewardsState> {
  final Zenon zenon;

  StakingUncollectedRewardsCubit(this.zenon)
      : super(StakingUncollectedRewardsState(
    status: CubitStatus.initial,
  ));


  Future<void> getDataAsync() async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final response = await zenon.embedded.stake
          .getUncollectedReward(Address.parse('kDemoAddress'));

      emit(state.copyWith(status: CubitStatus.success, data: response));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
