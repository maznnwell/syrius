import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_unlock_htlc_worker.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
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
    late HtlcSwapSyncService handler;

    setUp(() {
      swapRepository = MockHtlcSwapRepository();
      autoUnlockHtlcWorker = MockAutoUnlockHtlcWorker();
      zenon = MockZenon();
      handler = HtlcSwapSyncService(
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

      expect(await handler.hasActiveIncomingSwaps(), isTrue);

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

      expect(await handler.hasActiveIncomingSwaps(), isFalse);
    });

    test('does not start another run while already running', () async {
      final MockWsClient wsClient = MockWsClient();
      final Completer<List<HtlcSwap>> activeSwaps = Completer<List<HtlcSwap>>();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(true);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) => activeSwaps.future);

      handler..start()
      ..start();

      verify(() => swapRepository.getSwapsByState(any())).called(1);

      final Future<void> stopFuture = handler.stop();
      activeSwaps.complete(<HtlcSwap>[]);
      await stopFuture;
    });

    testWidgets(
      'stop waits for the current run and prevents rescheduling',
      (WidgetTester tester) async {
        final MockWsClient wsClient = MockWsClient();
        final Completer<List<HtlcSwap>> activeSwaps =
            Completer<List<HtlcSwap>>();
        when(() => zenon.wsClient).thenReturn(wsClient);
        when(wsClient.isClosed).thenReturn(true);
        when(
          () => swapRepository.getSwapsByState(any()),
        ).thenAnswer((_) => activeSwaps.future);

        handler.start();
        bool stopped = false;
        final Future<void> stopFuture = handler.stop().then((_) {
          stopped = true;
        });

        await tester.pump();
        expect(stopped, isFalse);

        activeSwaps.complete(<HtlcSwap>[]);
        await stopFuture;
        expect(stopped, isTrue);

        await tester.pump(const Duration(seconds: 5));
        verify(() => swapRepository.getSwapsByState(any())).called(1);
      },
    );

    test('does not poll while the injected client is closed', () async {
      final MockWsClient wsClient = MockWsClient();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(true);
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
