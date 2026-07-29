part of 'start_htlc_swap_bloc.dart';

/// Base class for start-HTLC-swap states.
sealed class StartHtlcSwapState extends Equatable {
  /// Creates a [StartHtlcSwapState].
  const StartHtlcSwapState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an HTLC swap is requested.
final class StartHtlcSwapInitial extends StartHtlcSwapState {
  /// Creates a [StartHtlcSwapInitial] state.
  const StartHtlcSwapInitial();
}

/// Loading state while the HTLC swap is being created.
final class StartHtlcSwapLoading extends StartHtlcSwapState {
  /// Creates a [StartHtlcSwapLoading] state.
  const StartHtlcSwapLoading();
}

/// Success state emitted after the HTLC swap has been stored.
final class StartHtlcSwapDone extends StartHtlcSwapState {
  /// Creates a [StartHtlcSwapDone] state.
  const StartHtlcSwapDone({required this.swap});

  /// Newly created outgoing HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the HTLC swap cannot be started.
final class StartHtlcSwapFailure extends StartHtlcSwapState {
  /// Creates a [StartHtlcSwapFailure] state.
  const StartHtlcSwapFailure({required this.exception});

  /// Error that prevented the swap from being started.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
