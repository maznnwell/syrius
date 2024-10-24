part of 'staking_uncollected_rewards_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class StakingUncollectedRewardsState{
  final CubitStatus status;
  final UncollectedReward? data;
  final Object? error;

  StakingUncollectedRewardsState({
    required this.status,
    this.data,
    this.error,
  });

  StakingUncollectedRewardsState copyWith({
    CubitStatus? status,
    UncollectedReward? data,
    Object? error,
  }) {
    return StakingUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}