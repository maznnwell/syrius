part of 'pillar_uncollected_rewards_cubit.dart';


enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class PillarUncollectedRewardsState{
  final CubitStatus status;
  final UncollectedReward? data;
  final Object? error;

  PillarUncollectedRewardsState({
    required this.status,
    this.data,
    this.error,
  });

  PillarUncollectedRewardsState copyWith({
    CubitStatus? status,
    UncollectedReward? data,
    Object? error,
  }) {
    return PillarUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}