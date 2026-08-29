part of 'join_native_swap_bloc.dart';

/// Base class for join-native-swap states.
sealed class JoinNativeSwapState extends Equatable {
  /// Creates a [JoinNativeSwapState].
  const JoinNativeSwapState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an HTLC swap is joined.
final class JoinNativeSwapInitial extends JoinNativeSwapState {
  /// Creates a [JoinNativeSwapInitial] state.
  const JoinNativeSwapInitial();
}

/// Loading state while the counter HTLC is being created.
final class JoinNativeSwapLoading extends JoinNativeSwapState {
  /// Creates a [JoinNativeSwapLoading] state.
  const JoinNativeSwapLoading();
}

/// Success state emitted after the incoming swap has been stored.
final class JoinNativeSwapDone extends JoinNativeSwapState {
  /// Creates a [JoinNativeSwapDone] state.
  const JoinNativeSwapDone({required this.swap});

  /// Newly created incoming HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the HTLC swap cannot be joined.
final class JoinNativeSwapFailure extends JoinNativeSwapState {
  /// Creates a [JoinNativeSwapFailure] state.
  const JoinNativeSwapFailure({required this.exception});

  /// Error that prevented the swap from being joined.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
