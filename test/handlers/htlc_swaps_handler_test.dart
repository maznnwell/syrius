import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_unlock_htlc_worker.dart';
import 'package:zenon_syrius_wallet_flutter/handlers/htlc_swaps_handler.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockHtlcSwapRepository extends Mock implements HtlcSwapRepository {}

class MockAutoUnlockHtlcWorker extends Mock implements AutoUnlockHtlcWorker {}

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockHtlcSwap extends Mock implements HtlcSwap {}

void main() {
  setUpAll(() {
    registerFallbackValue(<P2pSwapState>[]);
  });

  group('HtlcSwapsHandler', () {
    late MockHtlcSwapRepository swapRepository;
    late MockAutoUnlockHtlcWorker autoUnlockHtlcWorker;
    late MockZenon zenon;
    late HtlcSwapsHandler handler;

    setUp(() {
      swapRepository = MockHtlcSwapRepository();
      autoUnlockHtlcWorker = MockAutoUnlockHtlcWorker();
      zenon = MockZenon();
      handler = HtlcSwapsHandler(
        swapRepository: swapRepository,
        autoUnlockHtlcWorker: autoUnlockHtlcWorker,
        zenon: zenon,
      );
    });

    test('reports an active incoming swap', () async {
      final MockHtlcSwap incomingSwap = MockHtlcSwap();
      when(
        () => incomingSwap.direction,
      ).thenReturn(P2pSwapDirection.incoming);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[incomingSwap]);

      expect(await handler.hasActiveIncomingSwaps, isTrue);

      verify(() => swapRepository.getSwapsByState(any())).called(1);
    });

    test('ignores active outgoing swaps', () async {
      final MockHtlcSwap outgoingSwap = MockHtlcSwap();
      when(
        () => outgoingSwap.direction,
      ).thenReturn(P2pSwapDirection.outgoing);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[outgoingSwap]);

      expect(await handler.hasActiveIncomingSwaps, isFalse);
    });

    test('does not poll while the injected client is closed', () async {
      final MockWsClient wsClient = MockWsClient();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(() => wsClient.isClosed()).thenReturn(true);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[]);

      handler.start();
      await handler.stop();

      verify(() => zenon.wsClient).called(1);
      verifyNever(() => autoUnlockHtlcWorker.autoUnlock());
    });
  });
}
