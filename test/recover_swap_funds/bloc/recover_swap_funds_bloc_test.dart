import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

void main() {
  group('RecoverSwapFundsBloc', () {
    const int now = 1000;
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final Address selfAddress = emptyAddress;
    final Address otherAddress = htlcAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late HtlcInfo htlc;
    late RecoverSwapFundsBloc bloc;

    HtlcInfo buildHtlc({
      required Address timeLocked,
      required int expirationTime,
    }) => HtlcInfo(
      id: htlcId,
      timeLocked: timeLocked,
      hashLocked: otherAddress,
      tokenStandard: kZnnCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime: expirationTime,
      hashType: htlcHashTypeSha3,
      keyMaxSize: htlcPreimageMaxLength,
      hashLock: <int>[4, 5, 6],
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      htlc = buildHtlc(
        timeLocked: selfAddress,
        expirationTime: now,
      );

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(htlcId)).thenAnswer((_) async => htlc);
      when(() => htlcApi.reclaim(htlcId)).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'reclaim swap funds',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = RecoverSwapFundsBloc(
        accountBlockUtils: accountBlockUtils,
        walletAddresses: <String>{selfAddress.toString()},
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        unixTimeProvider: () => now,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const RecoverSwapFundsInitial());
    });

    blocTest<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      'submits the reclaim transaction and refreshes balances',
      build: () => bloc,
      act: (RecoverSwapFundsBloc bloc) => bloc.add(
        RecoverSwapFundsRequested(htlcId: htlcId),
      ),
      expect: () => <RecoverSwapFundsState>[
        const RecoverSwapFundsLoading(),
        const RecoverSwapFundsDone(),
      ],
      verify: (_) {
        verify(() => htlcApi.getById(htlcId)).called(1);
        verify(() => htlcApi.reclaim(htlcId)).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim swap funds',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      'rejects a deposit that does not belong to the wallet',
      setUp: () {
        htlc = buildHtlc(
          timeLocked: otherAddress,
          expirationTime: now,
        );
      },
      build: () => bloc,
      act: (RecoverSwapFundsBloc bloc) => bloc.add(
        RecoverSwapFundsRequested(htlcId: htlcId),
      ),
      expect: () => <Matcher>[
        isA<RecoverSwapFundsLoading>(),
        isA<RecoverSwapFundsFailure>().having(
          (RecoverSwapFundsFailure state) => state.exception.message,
          'message',
          'The deposit does not belong to you.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      'rejects a deposit that is still locked',
      setUp: () {
        htlc = buildHtlc(
          timeLocked: selfAddress,
          expirationTime: now + 1,
        );
      },
      build: () => bloc,
      act: (RecoverSwapFundsBloc bloc) => bloc.add(
        RecoverSwapFundsRequested(htlcId: htlcId),
      ),
      expect: () => <Matcher>[
        isA<RecoverSwapFundsLoading>(),
        isA<RecoverSwapFundsFailure>().having(
          (RecoverSwapFundsFailure state) => state.exception.message,
          'message',
          'The deposit is locked until '
              '${FormatUtils.formatDate(
                (now + 1) * Duration.millisecondsPerSecond,
                dateFormat: kDefaultDateTimeFormat,
              )}.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      'preserves a SyriusException from transaction submission',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim swap funds',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(SyriusException('Unable to recover funds.'));
      },
      build: () => bloc,
      act: (RecoverSwapFundsBloc bloc) => bloc.add(
        RecoverSwapFundsRequested(htlcId: htlcId),
      ),
      expect: () => <Matcher>[
        isA<RecoverSwapFundsLoading>(),
        isA<RecoverSwapFundsFailure>().having(
          (RecoverSwapFundsFailure state) => state.exception.message,
          'message',
          'Unable to recover funds.',
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(
          () => htlcApi.getById(htlcId),
        ).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (RecoverSwapFundsBloc bloc) => bloc.add(
        RecoverSwapFundsRequested(htlcId: htlcId),
      ),
      expect: () => <Matcher>[
        isA<RecoverSwapFundsLoading>(),
        isA<RecoverSwapFundsFailure>().having(
          (RecoverSwapFundsFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );
  });
}
