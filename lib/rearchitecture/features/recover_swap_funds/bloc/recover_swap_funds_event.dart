part of 'recover_swap_funds_bloc.dart';

/// Base class for recover-swap-funds events.
sealed class RecoverSwapFundsEvent extends Equatable {
  /// Creates a [RecoverSwapFundsEvent].
  const RecoverSwapFundsEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests recovery of funds from an expired HTLC.
final class RecoverSwapFundsRequested extends RecoverSwapFundsEvent {
  /// Creates a [RecoverSwapFundsRequested] event.
  const RecoverSwapFundsRequested({required this.htlcId});

  /// Identifier of the HTLC whose funds should be recovered.
  final Hash htlcId;

  @override
  List<Object> get props => <Object>[htlcId];
}
