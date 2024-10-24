part of 'sentinel_uncollected_rewards_cubit.dart';


enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class SentinelUncollectedRewardsState{
  final CubitStatus status;
  final UncollectedReward? data;
  final Object? error;

  SentinelUncollectedRewardsState({
    required this.status,
    this.data,
    this.error,
  });

  SentinelUncollectedRewardsState copyWith({
    CubitStatus? status,
    UncollectedReward? data,
    Object? error,
  }) {
    return SentinelUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}