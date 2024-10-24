part of 'sentinel_rewards_history_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class SentinelRewardsHistoryState{
  final CubitStatus status;
  final RewardHistoryList? data;
  final Object? error;

  SentinelRewardsHistoryState({
    required this.status,
    this.data,
    this.error,
  });

  SentinelRewardsHistoryState copyWith({
    CubitStatus? status,
    RewardHistoryList? data,
    Object? error,
  }) {
    return SentinelRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}