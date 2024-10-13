import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockSentinel extends Mock implements SentinelApi {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinelInfoList extends Mock implements SentinelInfoList {}


void main() {

  group('SentinelsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelsCubit sentinelsCubit;
    late Exception sentinelsException;
    late MockSentinelInfoList mockSentinelInfoList;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockSentinelInfoList = MockSentinelInfoList();
      sentinelsCubit = SentinelsCubit(mockZenon, SentinelsState());
      sentinelsException = Exception();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(
              () => mockZenon.embedded
      ).thenReturn(mockEmbedded);
      when(
              () => mockEmbedded.sentinel
      ).thenReturn(mockSentinel);
    });

    test('initial status is correct', () {
      final SentinelsCubit sentinelsCubit = SentinelsCubit(
        mockZenon,
        SentinelsState(),
      );
      expect(sentinelsCubit.state.status, CubitStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<SentinelsCubit, DashboardState>(
        'calls getAllActive() once',
        build: () => sentinelsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.sentinel.getAllActive()
          ).called(1);
        },
      );

      blocTest<SentinelsCubit, DashboardState>(
        'emits [loading, failure] when getAllActive() throws',
        setUp: () {
          when(
                () => mockSentinel.getAllActive(),
          ).thenThrow(sentinelsException);
        },
        build: () => sentinelsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <SentinelsState>[
          SentinelsState(status: CubitStatus.loading),
          SentinelsState(
            status: CubitStatus.failure,
            error: sentinelsException,
          ),
        ],
      );

      blocTest<SentinelsCubit, DashboardState>(
          'emits [loading, success] when getAllActive() returns (sentinelInfoList)',
          setUp: () {
            when(
                  () => mockSentinel.getAllActive(),
            ).thenAnswer((_) async => mockSentinelInfoList);
          },
          build: () => sentinelsCubit,
          act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <SentinelsState>[
            SentinelsState(status: CubitStatus.loading),
            SentinelsState(status: CubitStatus.success,
            data: mockSentinelInfoList),
          ]
      );
    });
  });
}
