part of 'general_stats_cubit.dart';

class GeneralStatsState extends DashboardState<GeneralStats>{
  GeneralStatsState({
    super.status,
    super.data,
    super.error,
  });

  @override
  DashboardState<GeneralStats> copyWith({
    CubitStatus? status,
    GeneralStats? data,
    Object? error,
  }) {
    return GeneralStatsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}