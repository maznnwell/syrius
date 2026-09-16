import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockP2pSwapRepository extends Mock
    implements P2pSwapRepository<HtlcSwap> {}

void main() {
  group('P2pSwapsCubit', () {
    late MockP2pSwapRepository swapRepository;
    late HtlcSwap olderSwap;
    late HtlcSwap newerSwap;

    P2pSwapsCubit buildCubit() => P2pSwapsCubit(
      swapRepository: swapRepository,
    );

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
      swapRepository = MockP2pSwapRepository();
      olderSwap = buildSwap(id: 'older-swap', startTime: 1);
      newerSwap = buildSwap(id: 'newer-swap', startTime: 2);

      when(
        () => swapRepository.watchAllSwaps(),
      ).thenAnswer(
        (_) => Stream<List<HtlcSwap>>.value(<HtlcSwap>[
          newerSwap,
          olderSwap,
        ]),
      );
    });

    test('initial state is P2pSwapsLoading', () {
      final P2pSwapsCubit cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const P2pSwapsLoading());
    });

    blocTest<P2pSwapsCubit, P2pSwapsState>(
      'emits the watched swaps',
      build: buildCubit,
      verify: (_) {
        verify(() => swapRepository.watchAllSwaps()).called(1);
      },
      expect: () => <P2pSwapsState>[
        P2pSwapsPopulated(swaps: <P2pSwap>[newerSwap, olderSwap]),
      ],
    );

    blocTest<P2pSwapsCubit, P2pSwapsState>(
      'emits failure when fetching swaps throws',
      setUp: () {
        when(
          () => swapRepository.watchAllSwaps(),
        ).thenAnswer(
          (_) => Stream<List<HtlcSwap>>.error(StateError('boom')),
        );
      },
      build: buildCubit,
      expect: () => <Object>[
        isA<P2pSwapsFailure>().having(
          (P2pSwapsFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    test('emits failure when starting observation throws', () {
      when(
        () => swapRepository.watchAllSwaps(),
      ).thenThrow(StateError('boom'));

      final P2pSwapsCubit cubit = buildCubit();
      addTearDown(cubit.close);

      expect(
        cubit.state,
        isA<P2pSwapsFailure>().having(
          (P2pSwapsFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      );
    });

    late StreamController<List<HtlcSwap>> swaps;
    blocTest<P2pSwapsCubit, P2pSwapsState>(
      'emits updates from the repository stream',
      setUp: () {
        swaps = StreamController<List<HtlcSwap>>();
        when(
          () => swapRepository.watchAllSwaps(),
        ).thenAnswer((_) => swaps.stream);
      },
      build: buildCubit,
      act: (P2pSwapsCubit _) {
        swaps
          ..add(<HtlcSwap>[olderSwap])
          ..add(<HtlcSwap>[newerSwap, olderSwap]);
      },
      expect: () => <P2pSwapsState>[
        P2pSwapsPopulated(swaps: <P2pSwap>[olderSwap]),
        P2pSwapsPopulated(swaps: <P2pSwap>[newerSwap, olderSwap]),
      ],
      tearDown: () => swaps.close(),
    );

    test('cancels the repository stream when closed', () async {
      bool cancelled = false;
      final StreamController<List<HtlcSwap>> swaps =
          StreamController<List<HtlcSwap>>(
            onCancel: () => cancelled = true,
          );
      when(
        () => swapRepository.watchAllSwaps(),
      ).thenAnswer((_) => swaps.stream);
      final P2pSwapsCubit cubit = buildCubit();
      await cubit.close();

      expect(cancelled, isTrue);
      await swaps.close();
    });
  });
}
