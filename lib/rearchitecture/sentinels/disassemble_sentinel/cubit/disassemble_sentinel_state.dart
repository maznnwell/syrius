part of 'disassemble_sentinel_cubit.dart';

/// Enum representing the status of the disassemble Sentinel operation.
enum DisassembleSentinelStatus {
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// [@macro success_status}
  success,

  /// {@macro failure_status}
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

  /// {@macro instance_from_json}
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
