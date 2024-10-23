part of 'pending_transactions_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class PendingTransactionsState {
  final CubitStatus status;
  final List<AccountBlock>? data;
  final Object? error;

  PendingTransactionsState({
    required this.status,
    this.data,
    this.error,
  });

  PendingTransactionsState copyWith({
    CubitStatus? status,
    List<AccountBlock>? data,
    Object? error,
  }) {
    return PendingTransactionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}