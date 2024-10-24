part of 'plasma_list_cubit.dart';

enum CubitStatus {
  initial,
  loading,
  failure,
  success,
}

class PlasmaListState {
  final CubitStatus status;
  final List<FusionEntry>? data;
  final Object? error;

  PlasmaListState({
    required this.status,
    this.data,
    this.error,
  });

  PlasmaListState copyWith({
    CubitStatus? status,
    List<FusionEntry>? data,
    Object? error,
  }) {
    return PlasmaListState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}