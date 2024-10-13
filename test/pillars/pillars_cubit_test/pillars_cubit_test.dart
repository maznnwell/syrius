import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class MockPillarInfoList extends Mock implements PillarInfoList {}

class MockPillarInfo extends Mock implements PillarInfo {}

void main() {

  group('PillarsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late PillarsCubit pillarsCubit;
    late Exception pillarsException;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      pillarsCubit = PillarsCubit(mockZenon, PillarsState());
      pillarsException = Exception();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(
              () => mockZenon.embedded
      ).thenReturn(mockEmbedded);
      when(
          () => mockEmbedded.pillar
      ).thenReturn(mockPillar);
    });

    test('initial status is correct', () {
      final PillarsCubit pillarsCubit = PillarsCubit(
        mockZenon,
        PillarsState(),
      );
      expect(pillarsCubit.state.status, CubitStatus.initial);
    });

    group('fetch', () {
      blocTest<PillarsCubit, DashboardState<int>>(
        'emits [loading, success] when fetch is successful with 100 pillars',
        build: () => pillarsCubit,
        setUp: () {
          final mockPillarInfoList = MockPillarInfoList();
          final mockPillarInfo = MockPillarInfo();
          when(() => mockPillar.getAll()).thenAnswer((_) async => mockPillarInfoList);
          when(() => mockPillarInfoList.list).thenReturn(List.filled(100, mockPillarInfo));
        },
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DashboardState<int>>[
          PillarsState(status: CubitStatus.loading),  // Loading state
          PillarsState(status: CubitStatus.success, data: 100), // Success with 100 pillars
        ],
        verify: (_) {
          verify(() => mockPillar.getAll()).called(1); // Ensure getAll was called once
        },
      );

      blocTest<PillarsCubit, DashboardState>(
        'emits [loading, failure] when getAll() throws',
        setUp: () {
          when(() => mockZenon.embedded).thenReturn(mockEmbedded);
          when(() => mockEmbedded.pillar).thenReturn(mockPillar);
          when(() => mockPillar.getAll()).thenThrow(pillarsException);  // Simulate failure
        },
        build: () => pillarsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <PillarsState>[
          PillarsState(status: CubitStatus.loading),
          PillarsState(status: CubitStatus.failure, error: pillarsException),
        ],
      );
    });
  });
}
