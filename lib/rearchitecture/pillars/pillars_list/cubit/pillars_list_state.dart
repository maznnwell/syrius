part of 'pillars_list_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class PillarsListState {
  final CubitStatus status;
  final List<PillarInfo>? data;
  final Object? error;

  PillarsListState({
    required this.status,
    this.data,
    this.error,
  });

  PillarsListState copyWith({
    CubitStatus? status,
    List<PillarInfo>? data,
    Object? error,
  }) {
    return PillarsListState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}