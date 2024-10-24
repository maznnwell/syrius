import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_uncollected_rewards_state.dart';

class SentinelUncollectedRewardsCubit extends Cubit<SentinelUncollectedRewardsState> {
  final Zenon zenon;

  SentinelUncollectedRewardsCubit(this.zenon)
      : super(SentinelUncollectedRewardsState(
    status: CubitStatus.initial,
  ));


  Future<void> getDataAsync() async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final response = await zenon.embedded.sentinel
          .getUncollectedReward(Address.parse('kDemoAddress'));

      emit(state.copyWith(status: CubitStatus.success, data: response));
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
