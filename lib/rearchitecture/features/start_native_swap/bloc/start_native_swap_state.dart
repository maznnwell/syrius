part of 'start_native_swap_bloc.dart';

/// Base class for start-HTLC-swap states.
sealed class StartNativeSwapState extends Equatable {
  /// Creates a [StartNativeSwapState].
  const StartNativeSwapState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an HTLC swap is requested.
final class StartNativeSwapInitial extends StartNativeSwapState {
  /// Creates a [StartNativeSwapInitial] state.
  const StartNativeSwapInitial();
}

/// Loading state while the HTLC swap is being created.
final class StartNativeSwapLoading extends StartNativeSwapState {
  /// Creates a [StartNativeSwapLoading] state.
  const StartNativeSwapLoading();
}

/// Success state emitted after the HTLC swap has been stored.
final class StartNativeSwapDone extends StartNativeSwapState {
  /// Creates a [StartNativeSwapDone] state.
  const StartNativeSwapDone({required this.swap});

  /// Newly created outgoing HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the HTLC swap cannot be started.
final class StartNativeSwapFailure extends StartNativeSwapState {
  /// Creates a [StartNativeSwapFailure] state.
  const StartNativeSwapFailure({required this.exception});

  /// Error that prevented the swap from being started.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
