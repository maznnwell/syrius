part of 'sentinel_qsr_info_cubit.dart';

/// Enum representing the status of the QSR management information.
enum SentinelsQsrInfoStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,

  /// {@macro failure_status}
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

  /// {@macro instance_from_json}
  factory SentinelsQsrInfoState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsQsrInfoStateFromJson(json);

  /// The current status of the operation.
  final SentinelsQsrInfoStatus status;

  /// The data returned upon a successful operation.
  final SentinelsQsrInfo? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// {@macro state_copy_with}
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

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SentinelsQsrInfoStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
