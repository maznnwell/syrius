import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/bloc/p2p_swaps_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockHtlcSwapsService extends Mock implements HtlcSwapRepository {}

void main() {
  group('P2pSwapsBloc', () {
    late MockHtlcSwapsService htlcSwapsService;
    late HtlcSwap olderSwap;
    late HtlcSwap newerSwap;

    P2pSwapsBloc buildBloc({
      Duration refreshInterval = const Duration(minutes: 1),
    }) {
      return P2pSwapsBloc(
        htlcSwapsService: htlcSwapsService,
        refreshInterval: refreshInterval,
      );
    }

    HtlcSwap buildSwap({required String id, required int startTime}) {
      return HtlcSwap(
        hashLock: 'hash-lock-$id',
        initialHtlcId: 'initial-htlc-id-$id',
        initialHtlcExpirationTime: 100,
        hashType: htlcHashTypeSha3,
        id: id,
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: 'self-address',
        counterpartyAddress: 'counterparty-address',
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: startTime,
        state: P2pSwapState.pending,
      );
    }

    setUp(() {
      htlcSwapsService = MockHtlcSwapsService();
      olderSwap = buildSwap(id: 'older-swap', startTime: 1);
      newerSwap = buildSwap(id: 'newer-swap', startTime: 2);

      when(
        () => htlcSwapsService.getAllSwaps(),
      ).thenAnswer((_) async => <HtlcSwap>[olderSwap, newerSwap]);
    });

    test('initial state is P2pSwapsInitial', () {
      final P2pSwapsBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const P2pSwapsInitial());
    });

    blocTest<P2pSwapsBloc, P2pSwapsState>(
      'fetches swaps ordered newest first',
      build: buildBloc,
      act: (P2pSwapsBloc bloc) => bloc.add(
        const P2pSwapsRequested(),
      ),
      verify: (_) {
        verify(() => htlcSwapsService.getAllSwaps()).called(1);
      },
      expect: () => <P2pSwapsState>[
        const P2pSwapsLoading(),
        P2pSwapsPopulated(swaps: <P2pSwap>[newerSwap, olderSwap]),
      ],
    );

    blocTest<P2pSwapsBloc, P2pSwapsState>(
      'emits failure when fetching swaps throws',
      setUp: () {
        when(
          () => htlcSwapsService.getAllSwaps(),
        ).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (P2pSwapsBloc bloc) => bloc.add(
        const P2pSwapsRequested(),
      ),
      expect: () => <Object>[
        const P2pSwapsLoading(),
        isA<P2pSwapsFailure>().having(
          (P2pSwapsFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<P2pSwapsBloc, P2pSwapsState>(
      'periodically refreshes after the initial request',
      build: () => buildBloc(
        refreshInterval: const Duration(milliseconds: 10),
      ),
      act: (P2pSwapsBloc bloc) => bloc.add(
        const P2pSwapsRequested(),
      ),
      wait: const Duration(milliseconds: 25),
      verify: (_) {
        verify(
          () => htlcSwapsService.getAllSwaps(),
        ).called(greaterThanOrEqualTo(2));
      },
    );

    test('cancels periodic refreshes when closed', () async {
      final P2pSwapsBloc bloc = buildBloc(
        refreshInterval: const Duration(milliseconds: 10),
      )..add(const P2pSwapsRequested());

      await expectLater(
        bloc.stream,
        emitsThrough(isA<P2pSwapsPopulated>()),
      );

      await bloc.close();
      clearInteractions(htlcSwapsService);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      verifyNever(() => htlcSwapsService.getAllSwaps());
    });
  });
}
