import 'package:freezed_annotation/freezed_annotation.dart';

part 'p2p_swap.freezed.dart';
part 'p2p_swap.g.dart';

enum P2pSwapType {
  native,
  crosschain,
}

enum P2pSwapState {
  pending,
  active,
  completed,
  reclaimable,
  unsuccessful,
  error,
}

enum P2pSwapMode {
  htlc,
}

enum P2pSwapDirection {
  outgoing,
  incoming,
}

enum P2pSwapChain {
  nom,
  btc,
  other,
}

@Freezed(unionKey: 'mode')
sealed class P2pSwap with _$P2pSwap {
  const P2pSwap._();

  @FreezedUnionValue('htlc')
  const factory P2pSwap.htlc({
    required String hashLock,
    required String initialHtlcId,
    required int initialHtlcExpirationTime,
    required int hashType,
    required String id,
    required int chainId,
    required P2pSwapType type,
    @Default(P2pSwapMode.htlc) P2pSwapMode mode,
    required P2pSwapDirection direction,
    required String selfAddress,
    required String counterpartyAddress,
    required BigInt fromAmount,
    required String fromTokenStandard,
    required String fromSymbol,
    required int fromDecimals,
    required P2pSwapChain fromChain,
    required P2pSwapChain toChain,
    required int startTime,
    required P2pSwapState state,
    BigInt? toAmount,
    String? toTokenStandard,
    String? toSymbol,
    int? toDecimals,
    String? counterHtlcId,
    int? counterHtlcExpirationTime,
    String? preimage,
  }) = HtlcSwap;

  factory P2pSwap.fromJson(Map<String, dynamic> json) =>
      _$P2pSwapFromJson(json);
}
