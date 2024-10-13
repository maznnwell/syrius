import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedger extends Mock implements LedgerApi {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlock extends Mock implements AccountBlock {}

class MockMomentum extends Mock implements Momentum {}

class MockAccountBlockList extends Mock implements AccountBlockList {}


void main() {
  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('RealtimeStatisticsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockLedger mockLedger;
    late RealtimeStatisticsCubit statsCubit;
    late Exception statsException;
    late List<AccountBlock> listAccBlock;
    late MockMomentum mockMomentum;
    late MockAccountBlockList accBlockList;

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      statsCubit = RealtimeStatisticsCubit(mockZenon, RealtimeStatisticsState());
      statsException = Exception();
      listAccBlock = [MockAccountBlock()];
      mockMomentum = MockMomentum();
      accBlockList = MockAccountBlockList();
      kSelectedAddress = 'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f';


      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
    });

    test('initial status is correct', () {
      final cubit = RealtimeStatisticsCubit(mockZenon, RealtimeStatisticsState());
      expect(cubit.state.status, CubitStatus.initial);
    });

    //TODO: test not finished;
    group('fetch', () {
      blocTest<RealtimeStatisticsCubit, DashboardState>(
        'calls getFrontierMomentum and getAccountBlocksByPage once',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum()).thenAnswer((_) async => mockMomentum);
          when(() => mockMomentum.height).thenReturn(100);

          when(() => mockLedger.getAccountBlocksByPage(any())).thenAnswer((_) async => accBlockList);
          when(() => accBlockList.list).thenReturn(listAccBlock);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockLedger.getFrontierMomentum()).called(1);
          verify(() => mockLedger.getAccountBlocksByPage(any())).called(1);
        },
      );

      //TODO: test not finished;
      blocTest<RealtimeStatisticsCubit, DashboardState>(
        'emits [loading, success] when fetch returns',
        setUp: () {
          when(() => statsCubit.fetch()).thenAnswer((_) async => listAccBlock);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          RealtimeStatisticsState(status: CubitStatus.loading),
          RealtimeStatisticsState(
            status: CubitStatus.success,
            data: listAccBlock,
          ),
        ],
      );

      blocTest<RealtimeStatisticsCubit, DashboardState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum()).thenThrow(statsException);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          RealtimeStatisticsState(status: CubitStatus.loading),
          RealtimeStatisticsState(
            status: CubitStatus.failure,
            error: statsException,
          ),
        ],
      );
    });
  });
}
