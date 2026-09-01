part of 'p2p_swaps_bloc.dart';

/// Base class for P2P-swaps-list events.
sealed class P2pSwapsEvent extends Equatable {
  /// Creates a [P2pSwapsEvent].
  const P2pSwapsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests the current P2P swaps and starts periodic refreshes.
final class P2pSwapsRequested extends P2pSwapsEvent {
  /// Creates a [P2pSwapsRequested] event.
  const P2pSwapsRequested();
}

final class _P2pSwapsRefreshRequested extends P2pSwapsEvent {
  const _P2pSwapsRefreshRequested();
}
