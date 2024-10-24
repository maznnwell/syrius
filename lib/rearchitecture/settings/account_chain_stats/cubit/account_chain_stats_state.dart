part of 'account_chain_stats_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class AccountChainStatsState{
  final CubitStatus status;
  final AccountChainStats? data;
  final Object? error;

  AccountChainStatsState({
    required this.status,
    this.data,
    this.error,
  });

  AccountChainStatsState copyWith({
    CubitStatus? status,
    AccountChainStats? data,
    Object? error,
  }) {
    return AccountChainStatsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}