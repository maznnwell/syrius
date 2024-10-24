part of 'sentinel_list_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class SentinelListState {
  final CubitStatus status;
  final List<SentinelInfo>? data;
  final Object? error;

  SentinelListState({
    required this.status,
    this.data,
    this.error,
  });

  SentinelListState copyWith({
    CubitStatus? status,
    List<SentinelInfo>? data,
    Object? error,
  }) {
    return SentinelListState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}