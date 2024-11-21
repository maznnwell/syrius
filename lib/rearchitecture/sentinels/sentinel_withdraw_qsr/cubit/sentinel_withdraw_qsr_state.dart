part of 'sentinel_withdraw_qsr_cubit.dart';

/// Enum representing the status of the QSR withdrawal operation.
enum SentinelsWithdrawQsrStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,

  /// {@macro failure_status}
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

  /// {@macro instance_from_json}
  factory SentinelsWithdrawQsrState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsWithdrawQsrStateFromJson(json);

  /// The current status of the QSR withdrawal operation.
  final SentinelsWithdrawQsrStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// {@macro state_copy_with}
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

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SentinelsWithdrawQsrStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
