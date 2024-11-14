part of 'sentinel_deposit_qsr_cubit.dart';

/// Enum representing the status of the deposit QSR operation.
enum SentinelsDepositQsrStatus {
  /// The initial state before any action has been taken.
  initial,

  /// The state when the deposit process is in progress.
  loading,

  /// The state when the deposit process has completed successfully.
  success,

  /// The state when the deposit process has failed.
  failure,
}

/// State class for the [SentinelsDepositQsrCubit].
@JsonSerializable(explicitToJson: true)
class SentinelsDepositQsrState extends Equatable {
  /// Constructs a [SentinelsDepositQsrState] with the given parameters.
  const SentinelsDepositQsrState({
    this.status = SentinelsDepositQsrStatus.initial,
    this.data,
    this.error,
  });

  /// Deserializes the JSON map into a [SentinelsDepositQsrState].
  factory SentinelsDepositQsrState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsDepositQsrStateFromJson(json);

  /// The current status of the deposit QSR operation.
  final SentinelsDepositQsrStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  SentinelsDepositQsrState copyWith({
    SentinelsDepositQsrStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return SentinelsDepositQsrState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SentinelsDepositQsrStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
