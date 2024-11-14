part of 'sentinel_deploy_cubit.dart';

/// Enum representing the status of the Sentinel deployment operation.
enum SentinelsDeployStatus {
  /// The initial state before any action has been taken.
  initial,

  /// The state when the deployment process is in progress.
  loading,

  /// The state when the deployment process has completed successfully.
  success,

  /// The state when the deployment process has failed.
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

  /// Deserializes the JSON map into a [SentinelsDeployState].
  factory SentinelsDeployState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsDeployStateFromJson(json);

  /// The current status of the Sentinel deployment operation.
  final SentinelsDeployStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// Creates a copy of this state with the given fields replaced by new values.
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

  /// Serializes this state into a JSON map.
  Map<String, dynamic> toJson() => _$SentinelsDeployStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
