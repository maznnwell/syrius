import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';

void main() {
  group('P2pSwap', () {
    test('copyWith creates an updated value without mutating the original', () {
      final HtlcSwap swap = _buildSwap();

      final HtlcSwap updatedSwap = swap.copyWith(
        state: P2pSwapState.active,
        counterHtlcId: 'counter-htlc-id',
      );

      expect(swap.state, P2pSwapState.pending);
      expect(swap.counterHtlcId, isNull);
      expect(updatedSwap.state, P2pSwapState.active);
      expect(updatedSwap.counterHtlcId, 'counter-htlc-id');
      expect(
        updatedSwap,
        swap.copyWith(
          state: P2pSwapState.active,
          counterHtlcId: 'counter-htlc-id',
        ),
      );
    });

    test('round-trips an HTLC swap through polymorphic JSON', () {
      final HtlcSwap swap = _buildSwap();

      final Map<String, dynamic> json = swap.toJson();
      final P2pSwap decodedSwap = P2pSwap.fromJson(json);

      expect(json['mode'], 'htlc');
      expect(json['fromAmount'], '100');
      expect(json['toAmount'], '200');
      expect(decodedSwap, isA<HtlcSwap>());
      expect(decodedSwap, swap);
    });
  });
}

HtlcSwap _buildSwap() => HtlcSwap(
  hashLock: 'hash-lock',
  initialHtlcId: 'initial-htlc-id',
  initialHtlcExpirationTime: 1000,
  hashType: 1,
  id: 'swap-id',
  chainId: 1,
  type: P2pSwapType.native,
  direction: P2pSwapDirection.outgoing,
  selfAddress: 'self-address',
  counterpartyAddress: 'counterparty-address',
  fromAmount: BigInt.from(100),
  fromTokenStandard: 'zts1',
  fromSymbol: 'ZNN',
  fromDecimals: 8,
  fromChain: P2pSwapChain.nom,
  toChain: P2pSwapChain.nom,
  startTime: 100,
  state: P2pSwapState.pending,
  toAmount: BigInt.from(200),
  toTokenStandard: 'zts2',
  toSymbol: 'QSR',
  toDecimals: 8,
);
