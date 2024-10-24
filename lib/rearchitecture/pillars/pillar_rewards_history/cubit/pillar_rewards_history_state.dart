part of 'pillar_rewards_history_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class PillarRewardsHistoryState{
  final CubitStatus status;
  final RewardHistoryList? data;
  final Object? error;

  PillarRewardsHistoryState({
    required this.status,
    this.data,
    this.error,
  });

  PillarRewardsHistoryState copyWith({
    CubitStatus? status,
    RewardHistoryList? data,
    Object? error,
  }) {
    return PillarRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}