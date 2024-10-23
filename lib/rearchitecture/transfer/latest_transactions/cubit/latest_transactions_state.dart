part of 'latest_transactions_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class LatestTransactionsState {
  final CubitStatus status;
  final List<AccountBlock>? data;
  final Object? error;

  LatestTransactionsState({
    required this.status,
    this.data,
    this.error,
  });

  LatestTransactionsState copyWith({
    CubitStatus? status,
    List<AccountBlock>? data,
    Object? error,
  }) {
    return LatestTransactionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
