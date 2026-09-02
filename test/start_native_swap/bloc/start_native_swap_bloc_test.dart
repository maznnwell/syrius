import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockLedger extends Mock implements LedgerApi {}

class MockMomentum extends Mock implements Momentum {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockHtlcSwapsService extends Mock implements HtlcSwapsService {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class FakeHtlcSwap extends Fake implements HtlcSwap {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(FakeHtlcSwap());
  });

  group('StartNativeSwapBloc', () {
    const Duration expirationDuration = kInitialHtlcDuration;
    const int frontierTimestamp = 1000;
    final BigInt fromAmount = BigInt.one;
    final Address selfAddress = emptyAddress;
    final Address counterpartyAddress = emptyAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockLedger ledger;
    late MockMomentum momentum;
    late MockAccountBlockUtils accountBlockUtils;
    late MockHtlcSwapsService htlcSwapsService;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late AccountBlockTemplate response;
    late StartNativeSwapBloc bloc;

    StartNativeSwapRequested buildEvent() => StartNativeSwapRequested(
      selfAddress: selfAddress,
      counterpartyAddress: counterpartyAddress,
      fromToken: kZnnCoin,
      fromAmount: fromAmount,
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      ledger = MockLedger();
      momentum = MockMomentum();
      accountBlockUtils = MockAccountBlockUtils();
      htlcSwapsService = MockHtlcSwapsService();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      response = AccountBlockTemplate(blockType: 1)
        ..hash = Hash.digest(<int>[1, 2, 3])
        ..chainIdentifier = 7;

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => zenon.ledger).thenReturn(ledger);
      when(
        () => ledger.getFrontierMomentum(),
      ).thenAnswer((_) async => momentum);
      when(() => momentum.timestamp).thenReturn(frontierTimestamp);
      when(
        () => htlcApi.create(
          kZnnCoin,
          fromAmount,
          counterpartyAddress,
          frontierTimestamp + expirationDuration.inSeconds,
          htlcHashTypeSha3,
          htlcPreimageMaxLength,
          any(),
        ),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'start swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);
      when(
        () => htlcSwapsService.storeSwap(any()),
      ).thenAnswer((_) async {});
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = StartNativeSwapBloc(
        accountBlockUtils: accountBlockUtils,
        htlcSwapsService: htlcSwapsService,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const StartNativeSwapInitial());
    });

    blocTest<StartNativeSwapBloc, StartNativeSwapState>(
      'creates, stores, and emits the outgoing HTLC swap',
      build: () => bloc,
      act: (StartNativeSwapBloc bloc) => bloc.add(buildEvent()),
      verify: (_) {
        verify(
          () => htlcApi.create(
            kZnnCoin,
            fromAmount,
            counterpartyAddress,
            frontierTimestamp + expirationDuration.inSeconds,
            htlcHashTypeSha3,
            htlcPreimageMaxLength,
            any(),
          ),
        ).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);

        final HtlcSwap swap =
            verify(
                  () => htlcSwapsService.storeSwap(captureAny()),
                ).captured.single
                as HtlcSwap;
        final List<int> preimage = FormatUtils.decodeHexString(swap.preimage!);

        expect(swap.id, response.hash.toString());
        expect(swap.chainId, response.chainIdentifier);
        expect(swap.initialHtlcId, response.hash.toString());
        expect(
          swap.initialHtlcExpirationTime,
          frontierTimestamp + expirationDuration.inSeconds,
        );
        expect(swap.direction, P2pSwapDirection.outgoing);
        expect(swap.state, P2pSwapState.pending);
        expect(swap.fromAmount, fromAmount);
        expect(swap.fromToken, kZnnCoin);
        expect(preimage, hasLength(htlcPreimageDefaultLength));
        expect(swap.hashLock, Hash.digest(preimage).toString());
      },
      expect: () => <Matcher>[
        isA<StartNativeSwapLoading>(),
        isA<StartNativeSwapDone>(),
      ],
    );

    blocTest<StartNativeSwapBloc, StartNativeSwapState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (StartNativeSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<StartNativeSwapLoading>(),
        isA<StartNativeSwapFailure>().having(
          (StartNativeSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<StartNativeSwapBloc, StartNativeSwapState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (StartNativeSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<StartNativeSwapLoading>(),
        isA<StartNativeSwapFailure>().having(
          (StartNativeSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
