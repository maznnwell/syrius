part of 'cancel_stake_cubit.dart';

/// Enum representing the possible statuses of the [CancelStakeCubit].
enum CancelStakeStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,

  /// {@macro failure_status}
  failure,
}

/// The state class for the [CancelStakeCubit].
@JsonSerializable()
class CancelStakeState extends Equatable {
  /// Constructs a new instance of [CancelStakeState].
  const CancelStakeState({
    this.status = CancelStakeStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory CancelStakeState.fromJson(Map<String, dynamic> json) =>
      _$CancelStakeStateFromJson(json);

  /// The current status of the cubit.
  final CancelStakeStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// The error object in case of a failure.
  final Object? error;

  /// {@macro state_copy_with}
  CancelStakeState copyWith({
    CancelStakeStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return CancelStakeState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }


  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$CancelStakeStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
