import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedger extends Mock implements LedgerApi {}

class MockAccountInfo extends Mock implements AccountInfo {}

class FakeAddress extends Fake implements Address {}

void main() {

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('BalanceCubit', () {
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late MockWsClient mockWsClient;
    late BalanceCubit balanceCubit;
    late MockAccountInfo mockAccountInfo;
    late Exception balanceException;

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      mockAccountInfo = MockAccountInfo();
      balanceCubit = BalanceCubit(emptyAddress, mockZenon, BalanceState());
      balanceException = Exception('Empty balance on the selected address - test');

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);

      when(() => mockLedger.getAccountInfoByAddress(any())
      ).thenAnswer((_) async => mockAccountInfo);

      when(() => mockAccountInfo.znn()
      ).thenReturn(BigInt.from(1));
      when(() => mockAccountInfo.qsr()
      ).thenReturn(BigInt.from(1));
      when(() => mockAccountInfo.blockCount
      ).thenReturn(1);
    });

    test('initial status is correct', () {
      final BalanceCubit balanceCubit = BalanceCubit(
        emptyAddress,
        mockZenon,
        BalanceState(),
      );
      expect(balanceCubit.state.status, CubitStatus.initial);
    });

    group('fetch', () {
      blocTest<BalanceCubit, DashboardState>(
        'calls getAccountInfoByAddress once',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any())
          ).thenAnswer((_) async => mockAccountInfo);
        },
        act: (cubit) => cubit.fetch(),
        verify: (_) {
            verify(() =>
                mockZenon.ledger.getAccountInfoByAddress(any()
                )).called(1);
        },
      );

      blocTest<BalanceCubit, DashboardState>(
        'emits [loading, failure] when fetch throws',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any())
          ).thenThrow(balanceException);
        },
        act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <BalanceState>[
            BalanceState(status: CubitStatus.loading),
            BalanceState(
              status: CubitStatus.failure,
              error: balanceException,
            ),
        ],
      );

      blocTest<BalanceCubit, DashboardState>(
        'emits [loading, success] when fetch returns',
        build: () => balanceCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <BalanceState>[
            BalanceState(status: CubitStatus.loading),
            BalanceState(status: CubitStatus.success,
            data: mockAccountInfo),
          ],
      );
    });
  });
}
