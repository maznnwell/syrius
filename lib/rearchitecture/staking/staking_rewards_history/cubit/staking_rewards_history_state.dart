part of 'staking_rewards_history_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class StakingRewardsHistoryState{
  final CubitStatus status;
  final RewardHistoryList? data;
  final Object? error;

  StakingRewardsHistoryState({
    required this.status,
    this.data,
    this.error,
  });

  StakingRewardsHistoryState copyWith({
    CubitStatus? status,
    RewardHistoryList? data,
    Object? error,
  }) {
    return StakingRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}