part of 'sentinel_withdraw_qsr_cubit.dart';

/// Enum representing the status of the QSR withdrawal operation.
enum SentinelsWithdrawQsrStatus {
  /// The initial state before any action has been taken.
  initial,

  /// The state when the withdrawal process is in progress.
  loading,

  /// The state when the withdrawal process has completed successfully.
  success,

  /// The state when the withdrawal process has failed.
  failure,
}

/// State class for the [SentinelsWithdrawQsrCubit].
@JsonSerializable(explicitToJson: true)
class SentinelsWithdrawQsrState extends Equatable {
  /// Constructs a [SentinelsWithdrawQsrState] with the given parameters.
  const SentinelsWithdrawQsrState({
    this.status = SentinelsWithdrawQsrStatus.initial,
    this.data,
    this.error,
  });

  /// Deserializes the JSON map into a [SentinelsWithdrawQsrState].
  factory SentinelsWithdrawQsrState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsWithdrawQsrStateFromJson(json);

  /// The current status of the QSR withdrawal operation.
  final SentinelsWithdrawQsrStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// Creates a copy of this state with the given fields replaced by new values.
  SentinelsWithdrawQsrState copyWith({
    SentinelsWithdrawQsrStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return SentinelsWithdrawQsrState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Serializes this state into a JSON map.
  Map<String, dynamic> toJson() => _$SentinelsWithdrawQsrStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
