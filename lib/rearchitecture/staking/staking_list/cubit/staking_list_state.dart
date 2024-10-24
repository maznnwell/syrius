part of 'staking_list_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class StakingListState {
  final CubitStatus status;
  final List<StakeEntry>? data;
  final Object? error;

  StakingListState({
    required this.status,
    this.data,
    this.error,
  });

  StakingListState copyWith({
    CubitStatus? status,
    List<StakeEntry>? data,
    Object? error,
  }) {
    return StakingListState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}