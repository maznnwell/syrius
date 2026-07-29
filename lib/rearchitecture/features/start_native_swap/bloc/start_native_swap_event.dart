part of 'start_native_swap_bloc.dart';

/// Base class for start-HTLC-swap events.
sealed class StartNativeSwapEvent extends Equatable {
  /// Creates a [StartNativeSwapEvent].
  const StartNativeSwapEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests creation of an outgoing HTLC swap.
final class StartNativeSwapRequested extends StartNativeSwapEvent {
  /// Creates a [StartNativeSwapRequested] event.
  const StartNativeSwapRequested({
    required this.selfAddress,
    required this.counterpartyAddress,
    required this.fromToken,
    required this.fromAmount,
    required this.hashType,
    required this.swapType,
    required this.fromChain,
    required this.toChain,
    required this.initialHtlcDuration,
  });

  /// Address funding the HTLC.
  final Address selfAddress;

  /// Address that can unlock the HTLC.
  final Address counterpartyAddress;

  /// Token locked in the HTLC.
  final Token fromToken;

  /// Amount locked in the HTLC.
  final BigInt fromAmount;

  /// Hash algorithm used for the hash lock.
  final int hashType;

  /// Type of P2P swap being started.
  final P2pSwapType swapType;

  /// Chain from which the swap originates.
  final P2pSwapChain fromChain;

  /// Chain on which the counterparty pays.
  final P2pSwapChain toChain;

  /// Initial HTLC lifetime in seconds.
  final int initialHtlcDuration;

  @override
  List<Object?> get props => <Object?>[
    selfAddress,
    counterpartyAddress,
    fromToken,
    fromAmount,
    hashType,
    swapType,
    fromChain,
    toChain,
    initialHtlcDuration,
  ];
}
