part of 'p2p_swap_details_bloc.dart';

/// Base class for swap-details events.
sealed class P2pSwapDetailsEvent extends Equatable {
  /// Creates a [P2pSwapDetailsEvent].
  const P2pSwapDetailsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests the current swap details and starts periodic refreshes.
final class P2pSwapDetailsRequested extends P2pSwapDetailsEvent {
  /// Creates a [P2pSwapDetailsRequested] event.
  const P2pSwapDetailsRequested();
}

final class _P2pSwapDetailsRefreshRequested extends P2pSwapDetailsEvent {
  const _P2pSwapDetailsRefreshRequested();
}
