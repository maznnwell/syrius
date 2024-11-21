part of 'sentinel_deploy_cubit.dart';

/// Enum representing the status of the Sentinel deployment operation.
enum SentinelsDeployStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,

  /// {@macro failure_status}
  failure,
}

/// State class for the [SentinelsDeployCubit].
@JsonSerializable(explicitToJson: true)
class SentinelsDeployState extends Equatable {
  /// Constructs a [SentinelsDeployState] with the given parameters.
  const SentinelsDeployState({
    this.status = SentinelsDeployStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory SentinelsDeployState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsDeployStateFromJson(json);

  /// The current status of the Sentinel deployment operation.
  final SentinelsDeployStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  SentinelsDeployState copyWith({
    SentinelsDeployStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return SentinelsDeployState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SentinelsDeployStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
