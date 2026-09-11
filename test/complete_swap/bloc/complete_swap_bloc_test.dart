import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockHtlcSwapsService extends Mock implements HtlcSwapRepository {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class FakeHtlcSwap extends Fake implements HtlcSwap {}

void main() {
  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(FakeHtlcSwap());
  });

  group('CompleteSwapBloc', () {
    const int now = 1000;
    final Hash initialHtlcId = Hash.digest(<int>[1, 2, 3]);
    final Hash counterHtlcId = Hash.digest(<int>[4, 5, 6]);
    final Address selfAddress = emptyAddress;
    final List<int> preimage = <int>[7, 8, 9];

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockHtlcSwapsService htlcSwapsService;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late HtlcInfo htlc;
    late HtlcSwap swap;
    late CompleteSwapBloc bloc;

    HtlcInfo buildHtlc({
      required int expirationTime,
      int keyMaxSize = htlcPreimageMaxLength,
    }) => HtlcInfo(
      id: counterHtlcId,
      timeLocked: htlcAddress,
      hashLocked: selfAddress,
      tokenStandard: kQsrCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime: expirationTime,
      hashType: htlcHashTypeSha3,
      keyMaxSize: keyMaxSize,
      hashLock: Hash.digest(preimage).getBytes()!,
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      accountBlockUtils = MockAccountBlockUtils();
      htlcSwapsService = MockHtlcSwapsService();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      htlc = buildHtlc(
        expirationTime: now + kMinSafeTimeToCompleteSwap.inSeconds + 1,
      );
      swap = HtlcSwap(
        hashLock: Hash.digest(preimage).toString(),
        initialHtlcId: initialHtlcId.toString(),
        initialHtlcExpirationTime: now + kInitialHtlcDuration.inSeconds,
        hashType: htlcHashTypeSha3,
        id: initialHtlcId.toString(),
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: selfAddress.toString(),
        counterpartyAddress: htlcAddress.toString(),
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: now,
        state: P2pSwapState.active,
        toAmount: BigInt.two,
        toToken: kQsrCoin,
        counterHtlcId: counterHtlcId.toString(),
        counterHtlcExpirationTime: htlc.expirationTime,
        preimage: FormatUtils.encodeHexString(preimage),
      );

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(counterHtlcId)).thenAnswer((_) async => htlc);
      when(
        () => htlcApi.unlock(counterHtlcId, any()),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);
      when(
        () => htlcSwapsService.storeSwap(any()),
      ).thenAnswer((_) async {});
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = CompleteSwapBloc(
        accountBlockUtils: accountBlockUtils,
        htlcSwapsService: htlcSwapsService,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        unixTimeProvider: () => now,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const CompleteSwapInitial());
    });

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'unlocks the counter HTLC, stores the completed swap, and refreshes',
      build: () => bloc,
      act: (CompleteSwapBloc bloc) => bloc.add(
        CompleteSwapRequested(swap: swap),
      ),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapDone>()
            .having(
              (CompleteSwapDone state) => state.block,
              'submitted block',
              transactionParams,
            )
            .having(
              (CompleteSwapDone state) => state.swap.state,
              'swap state',
              P2pSwapState.completed,
            ),
      ],
      verify: (_) {
        verify(() => htlcApi.getById(counterHtlcId)).called(1);
        final List<int> unlockedPreimage =
            verify(
                  () => htlcApi.unlock(counterHtlcId, captureAny()),
                ).captured.single
                as List<int>;
        expect(unlockedPreimage, preimage);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'complete swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        final HtlcSwap storedSwap =
            verify(
                  () => htlcSwapsService.storeSwap(captureAny()),
                ).captured.single
                as HtlcSwap;
        expect(storedSwap.state, P2pSwapState.completed);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'rejects a swap at the safe expiration cutoff',
      setUp: () {
        htlc = buildHtlc(
          expirationTime: now + kMinSafeTimeToCompleteSwap.inSeconds,
        );
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) => bloc.add(
        CompleteSwapRequested(swap: swap),
      ),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception.message,
          'message',
          'The swap will expire too soon for a safe swap.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.unlock(counterHtlcId, any()));
        verifyNever(() => htlcSwapsService.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'rejects a secret that exceeds the HTLC key size',
      setUp: () {
        htlc = buildHtlc(
          expirationTime: now + kMinSafeTimeToCompleteSwap.inSeconds + 1,
          keyMaxSize: preimage.length - 1,
        );
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) => bloc.add(
        CompleteSwapRequested(swap: swap),
      ),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception.message,
          'message',
          'The swap secret size exceeds the maximum allowed size.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.unlock(counterHtlcId, any()));
        verifyNever(() => htlcSwapsService.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'preserves a SyriusException from transaction submission',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'complete swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(SyriusException('Unable to complete swap.'));
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) => bloc.add(
        CompleteSwapRequested(swap: swap),
      ),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception.message,
          'message',
          'Unable to complete swap.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcSwapsService.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(
          () => htlcApi.getById(counterHtlcId),
        ).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) => bloc.add(
        CompleteSwapRequested(swap: swap),
      ),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.unlock(counterHtlcId, any()));
        verifyNever(() => htlcSwapsService.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );
  });
}
