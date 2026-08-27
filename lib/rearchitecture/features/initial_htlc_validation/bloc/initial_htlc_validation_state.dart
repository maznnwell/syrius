part of 'initial_htlc_validation_bloc.dart';

/// Base class for initial HTLC validation states.
sealed class InitialHtlcValidationState extends Equatable {
  /// Creates an [InitialHtlcValidationState].
  const InitialHtlcValidationState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before validation is requested.
final class InitialHtlcValidationInitial extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationInitial] state.
  const InitialHtlcValidationInitial();
}

/// Loading state emitted while the initial HTLC is being validated.
final class InitialHtlcValidationLoading extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationLoading] state.
  const InitialHtlcValidationLoading();
}

/// Success state containing the validated initial HTLC.
final class InitialHtlcValidationDone extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationDone] state.
  const InitialHtlcValidationDone({required this._htlc});

  final HtlcInfo _htlc;

  /// The fetched and validated initial HTLC.
  HtlcInfo get htlc => _htlc;

  @override
  List<Object> get props => <Object>[_htlc];
}

/// Failure state emitted when the initial HTLC is invalid or cannot be fetched.
final class InitialHtlcValidationFailure extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationFailure] state.
  const InitialHtlcValidationFailure({required this._exception});

  final SyriusException _exception;

  /// Error that prevented validation from completing.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}
