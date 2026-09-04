part of 'recover_swap_funds_bloc.dart';

/// Base class for recover-swap-funds states.
sealed class RecoverSwapFundsState extends Equatable {
  /// Creates a [RecoverSwapFundsState].
  const RecoverSwapFundsState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before recovery is requested.
final class RecoverSwapFundsInitial extends RecoverSwapFundsState {
  /// Creates a [RecoverSwapFundsInitial] state.
  const RecoverSwapFundsInitial();
}

/// Loading state while the recovery transaction is being submitted.
final class RecoverSwapFundsLoading extends RecoverSwapFundsState {
  /// Creates a [RecoverSwapFundsLoading] state.
  const RecoverSwapFundsLoading();
}

/// Success state emitted after the recovery transaction is submitted.
final class RecoverSwapFundsDone extends RecoverSwapFundsState {
  /// Creates a [RecoverSwapFundsDone] state.
  const RecoverSwapFundsDone();
}

/// Failure state emitted when swap funds cannot be recovered.
final class RecoverSwapFundsFailure extends RecoverSwapFundsState {
  /// Creates a [RecoverSwapFundsFailure] state.
  const RecoverSwapFundsFailure({required this.exception});

  /// Error that prevented the swap funds from being recovered.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}
