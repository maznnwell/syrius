part of 'join_native_swap_bloc.dart';

/// Base class for join-native-swap events.
sealed class JoinNativeSwapEvent extends Equatable {
  /// Creates a [JoinNativeSwapEvent].
  const JoinNativeSwapEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests creation of an incoming HTLC swap.
final class JoinNativeSwapRequested extends JoinNativeSwapEvent {
  /// Creates a [JoinNativeSwapRequested] event.
  const JoinNativeSwapRequested({
    required this.initialHtlc,
    required this.fromToken,
    required this.toToken,
    required this.fromAmount,
    required this.swapType,
    required this.fromChain,
    required this.toChain,
    required this.counterHtlcExpirationTime,
  });

  /// Initial HTLC created by the counterparty.
  final HtlcInfo initialHtlc;

  /// Token that will be locked in the counter HTLC.
  final Token fromToken;

  /// Token locked in the initial HTLC.
  final Token toToken;

  /// Amount that will be locked in the counter HTLC.
  final BigInt fromAmount;

  /// Type of P2P swap being joined.
  final P2pSwapType swapType;

  /// Chain from which the counter HTLC originates.
  final P2pSwapChain fromChain;

  /// Chain on which the initial HTLC was created.
  final P2pSwapChain toChain;

  /// Expiration time of the counter HTLC.
  final int counterHtlcExpirationTime;

  @override
  List<Object?> get props => <Object?>[
    initialHtlc,
    fromToken,
    toToken,
    fromAmount,
    swapType,
    fromChain,
    toChain,
    counterHtlcExpirationTime,
  ];
}
