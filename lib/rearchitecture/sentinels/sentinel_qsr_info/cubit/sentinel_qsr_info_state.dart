part of 'sentinel_qsr_info_cubit.dart';

/// Enum representing the status of the QSR management information.
enum SentinelsQsrInfoStatus {
  /// The initial state before any action has been taken.
  initial,

  /// The state when the fetching process is in progress.
  loading,

  /// The state when the fetching process has completed successfully.
  success,

  /// The state when the fetching process has failed.
  failure,
}

/// State class for the [SentinelsQsrInfoCubit].
@JsonSerializable(explicitToJson: true)
class SentinelsQsrInfoState extends Equatable {
  /// Constructs a [SentinelsQsrInfoState] with the given parameters.
  const SentinelsQsrInfoState({
    this.status = SentinelsQsrInfoStatus.initial,
    this.data,
    this.error,
  });

  /// Deserializes the JSON map into a [SentinelsQsrInfoState].
  factory SentinelsQsrInfoState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsQsrInfoStateFromJson(json);

  /// The current status of the operation.
  final SentinelsQsrInfoStatus status;

  /// The data returned upon a successful operation.
  final SentinelsQsrInfo? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// Creates a copy of this state with the given fields replaced by new values.
  SentinelsQsrInfoState copyWith({
    SentinelsQsrInfoStatus? status,
    SentinelsQsrInfo? data,
    Object? error,
  }) {
    return SentinelsQsrInfoState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Serializes this state into a JSON map.
  Map<String, dynamic> toJson() => _$SentinelsQsrInfoStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
