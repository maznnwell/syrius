import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/sentinels/sentinels.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinel extends Mock implements SentinelApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('SentinelRewardsHistoryCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelRewardsHistoryCubit sentinelRewardsHistoryCubit;
    late RewardHistoryList rewardHistoryList;
    late NoRewardsLastWeekException exception;
    late Address testAddress;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress;
      exception = NoRewardsLastWeekException();

      final Map<String, dynamic> rewardHistoryListJson = <String, dynamic>{
        'count' : 2,
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '100',
            'qsrAmount': '50',
          },
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '0',
            'qsrAmount': '0',
          },
        ],
      };
      rewardHistoryList = RewardHistoryList.fromJson(rewardHistoryListJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);

      sentinelRewardsHistoryCubit = SentinelRewardsHistoryCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      sentinelRewardsHistoryCubit.close();
    });

    test('initial state is correct', () {
      expect(
        sentinelRewardsHistoryCubit.state.status,
        IndicatorStatus.initial,
      );
    });

    group('SentinelRewardsHistory toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const SentinelRewardsHistoryState initialState =
        SentinelRewardsHistoryState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final SentinelRewardsHistoryState deserialized =
        SentinelRewardsHistoryState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const SentinelRewardsHistoryState loadingState =
        SentinelRewardsHistoryState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final SentinelRewardsHistoryState deserialized =
        SentinelRewardsHistoryState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final SentinelRewardsHistoryState successState =
        SentinelRewardsHistoryState(
          status: IndicatorStatus.success,
          data: rewardHistoryList,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final SentinelRewardsHistoryState deserialized =
        SentinelRewardsHistoryState.fromJson(serialized);

        expect(deserialized, isA<SentinelRewardsHistoryState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.success),
        );
        expect(deserialized.data, equals(rewardHistoryList));
      });

      test('can (de)serialize failure state', () {
        final SentinelRewardsHistoryState failureState =
        SentinelRewardsHistoryState(
          status: IndicatorStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final SentinelRewardsHistoryState deserialized =
        SentinelRewardsHistoryState.fromJson(serialized);

        expect(deserialized, isA<SentinelRewardsHistoryState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.failure),
        );
      });
    });

    group('updateStream', () {
      blocTest<SentinelRewardsHistoryCubit, SentinelRewardsHistoryState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(
                () => mockSentinel.getFrontierRewardByPage(
              any(),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenAnswer((_) async => rewardHistoryList);
        },
        build: () => sentinelRewardsHistoryCubit,
        act: (SentinelRewardsHistoryCubit cubit) => cubit.updateStream(),
        expect: () => <SentinelRewardsHistoryState>[
          const SentinelRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          SentinelRewardsHistoryState(
            status: IndicatorStatus.success,
            data: rewardHistoryList,
          ),
        ],
      );

      blocTest<SentinelRewardsHistoryCubit, SentinelRewardsHistoryState>(
        'emits [loading, failure] when getData throws exception',
        setUp: () {
          when(
                () => mockSentinel.getFrontierRewardByPage(
              any(),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenThrow(exception);
        },
        build: () => sentinelRewardsHistoryCubit,
        act: (SentinelRewardsHistoryCubit cubit) => cubit.updateStream(),
        expect: () => <SentinelRewardsHistoryState>[
          const SentinelRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          SentinelRewardsHistoryState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
