import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockHtlcSwapsService extends Mock implements HtlcSwapsService {}

void main() {
  group('P2pSwapDetailsBloc', () {
    const String swapId = 'swap-id';

    late MockHtlcSwapsService htlcSwapsService;
    late HtlcSwap swap;

    P2pSwapDetailsBloc buildBloc({
      Duration refreshInterval = const Duration(minutes: 1),
    }) {
      return P2pSwapDetailsBloc(
        htlcSwapsService: htlcSwapsService,
        refreshInterval: refreshInterval,
        swapId: swapId,
      );
    }

    setUp(() {
      htlcSwapsService = MockHtlcSwapsService();
      swap = HtlcSwap(
        hashLock: 'hash-lock',
        initialHtlcId: 'initial-htlc-id',
        initialHtlcExpirationTime: 100,
        hashType: htlcHashTypeSha3,
        id: swapId,
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: 'self-address',
        counterpartyAddress: 'counterparty-address',
        fromAmount: BigInt.one,
        fromTokenStandard: 'zts1',
        fromSymbol: 'ZNN',
        fromDecimals: 8,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 1,
        state: P2pSwapState.pending,
      );

      when(() => htlcSwapsService.getSwapById(swapId)).thenReturn(swap);
    });

    test('initial state is P2pSwapDetailsInitial', () {
      final P2pSwapDetailsBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const P2pSwapDetailsInitial());
    });

    blocTest<P2pSwapDetailsBloc, P2pSwapDetailsState>(
      'fetches the swap and emits loading and populated states',
      build: buildBloc,
      act: (P2pSwapDetailsBloc bloc) => bloc.add(
        const P2pSwapDetailsRequested(),
      ),
      verify: (_) {
        verify(() => htlcSwapsService.getSwapById(swapId)).called(1);
      },
      expect: () => <P2pSwapDetailsState>[
        const P2pSwapDetailsLoading(),
        P2pSwapDetailsPopulated(swap: swap),
      ],
    );

    blocTest<P2pSwapDetailsBloc, P2pSwapDetailsState>(
      'emits failure when the swap does not exist',
      setUp: () {
        when(() => htlcSwapsService.getSwapById(swapId)).thenReturn(null);
      },
      build: buildBloc,
      act: (P2pSwapDetailsBloc bloc) => bloc.add(
        const P2pSwapDetailsRequested(),
      ),
      expect: () => <Object>[
        const P2pSwapDetailsLoading(),
        isA<P2pSwapDetailsFailure>().having(
          (P2pSwapDetailsFailure state) => state.exception.message,
          'message',
          'Swap does not exist',
        ),
      ],
    );

    blocTest<P2pSwapDetailsBloc, P2pSwapDetailsState>(
      'emits generic failure when fetching throws unexpectedly',
      setUp: () {
        when(
          () => htlcSwapsService.getSwapById(swapId),
        ).thenThrow(Exception('boom'));
      },
      build: buildBloc,
      act: (P2pSwapDetailsBloc bloc) => bloc.add(
        const P2pSwapDetailsRequested(),
      ),
      expect: () => <Object>[
        const P2pSwapDetailsLoading(),
        isA<P2pSwapDetailsFailure>().having(
          (P2pSwapDetailsFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<P2pSwapDetailsBloc, P2pSwapDetailsState>(
      'periodically refreshes after the initial request',
      build: () => buildBloc(
        refreshInterval: const Duration(milliseconds: 10),
      ),
      act: (P2pSwapDetailsBloc bloc) => bloc.add(
        const P2pSwapDetailsRequested(),
      ),
      wait: const Duration(milliseconds: 25),
      verify: (_) {
        verify(
          () => htlcSwapsService.getSwapById(swapId),
        ).called(greaterThanOrEqualTo(2));
      },
    );

    test('cancels periodic refreshes when closed', () async {
      final P2pSwapDetailsBloc bloc = buildBloc(
        refreshInterval: const Duration(milliseconds: 10),
      )..add(const P2pSwapDetailsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<P2pSwapDetailsPopulated>()),
      );

      await bloc.close();
      clearInteractions(htlcSwapsService);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      verifyNever(() => htlcSwapsService.getSwapById(swapId));
    });
  });
}
