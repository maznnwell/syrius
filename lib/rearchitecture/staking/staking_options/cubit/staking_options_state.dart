part of 'staking_options_cubit.dart';

/// Enum representing the possible statuses of the [StakingOptionsCubit].
enum StakingOptionsStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,

  /// {@macro failure_status}
  failure,
}

/// The state class for the [StakingOptionsCubit].
@JsonSerializable(explicitToJson: true)
class StakingOptionsState extends Equatable {
  /// Constructs a new instance of [StakingOptionsState].
  const StakingOptionsState({
    this.status = StakingOptionsStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory StakingOptionsState.fromJson(Map<String, dynamic> json) =>
      _$StakingOptionsStateFromJson(json);

  /// The current status of the cubit.
  final StakingOptionsStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// The error object in case of a failure.
  final Object? error;

  /// {@macro state_copy_with}
  StakingOptionsState copyWith({
    StakingOptionsStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return StakingOptionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$StakingOptionsStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
