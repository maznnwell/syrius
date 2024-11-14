part of 'disassemble_sentinel_cubit.dart';

/// Enum representing the status of the disassemble Sentinel operation.
enum DisassembleSentinelStatus {
  /// The initial state before any action has been taken.
  initial,

  /// The state when the disassembling process is in progress.
  loading,

  /// The state when the disassembling process has completed successfully.
  success,

  /// The state when the disassembling process has failed.
  failure,
}

/// State class for the [DisassembleSentinelCubit].
@JsonSerializable(explicitToJson: true)
class DisassembleSentinelState extends Equatable {

  /// Constructs a [DisassembleSentinelState] with the given parameters.
  const DisassembleSentinelState({
    this.status = DisassembleSentinelStatus.initial,
    this.data,
    this.error,
  });

  /// Deserializes the JSON map into a [DisassembleSentinelState].
  factory DisassembleSentinelState.fromJson(Map<String, dynamic> json) =>
      _$DisassembleSentinelStateFromJson(json);

  /// The current status of the disassemble Sentinel operation.
  final DisassembleSentinelStatus status;

  /// The data returned upon a successful operation.
  final AccountBlockTemplate? data;

  /// Any error encountered during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  DisassembleSentinelState copyWith({
    DisassembleSentinelStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return DisassembleSentinelState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DisassembleSentinelStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
