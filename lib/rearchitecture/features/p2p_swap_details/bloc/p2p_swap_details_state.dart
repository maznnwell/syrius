part of 'p2p_swap_details_bloc.dart';

/// Base class for swap-details states.
sealed class P2pSwapDetailsState extends Equatable {
  /// Creates a [P2pSwapDetailsState].
  const P2pSwapDetailsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before swap details have been requested.
final class P2pSwapDetailsInitial extends P2pSwapDetailsState {
  /// Creates a [P2pSwapDetailsInitial] state.
  const P2pSwapDetailsInitial();
}

/// Loading state while swap details are being fetched.
final class P2pSwapDetailsLoading extends P2pSwapDetailsState {
  /// Creates a [P2pSwapDetailsLoading] state.
  const P2pSwapDetailsLoading();
}

/// Populated state containing the latest swap details.
final class P2pSwapDetailsPopulated extends P2pSwapDetailsState {
  /// Creates a [P2pSwapDetailsPopulated] state.
  const P2pSwapDetailsPopulated({required this.swap});

  /// The latest persisted HTLC swap details.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when swap details cannot be fetched.
final class P2pSwapDetailsFailure extends P2pSwapDetailsState {
  /// Creates a [P2pSwapDetailsFailure] state.
  const P2pSwapDetailsFailure({required this.exception});

  /// Error that prevented swap details from being fetched.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
