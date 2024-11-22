import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/staking/staking.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class MockRewardHistoryList extends Mock implements RewardHistoryList {}

class MockRewardHistoryEntry extends Mock implements RewardHistoryEntry {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockRewardHistoryList());
    registerFallbackValue(MockRewardHistoryEntry());
    registerFallbackValue(FakeAddress());
  });

  group('StakingRewardsHistoryCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late StakingRewardsHistoryCubit cubit;
    late NoRewardsLastWeekException exception;
    late Address testAddress;
    late RewardHistoryList rewardHistoryList;

    setUp(() {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      exception = NoRewardsLastWeekException();
      testAddress = emptyAddress;
      final Map<String, dynamic> rewardHistoryListJson = <String, dynamic>{
        'count': 2,
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
      when(() => mockEmbedded.stake).thenReturn(mockStake);

      cubit = StakingRewardsHistoryCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(IndicatorStatus.initial));
    });

    group('getData', () {
      blocTest<StakingRewardsHistoryCubit, StakingRewardsHistoryState>(
        'emits [loading, success] when getData succeeds with rewards',
        setUp: () {
          when(
            () => mockStake.getFrontierRewardByPage(
              any(),
              pageIndex: any(named: 'pageIndex'),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenAnswer((_) async => rewardHistoryList);
        },
        build: () => cubit,
        act: (StakingRewardsHistoryCubit cubit) => cubit.updateStream(),
        expect: () => <StakingRewardsHistoryState>[
          const StakingRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          StakingRewardsHistoryState(
            status: IndicatorStatus.success,
            data: rewardHistoryList,
          ),
        ],
        verify: (_) {
          verify(
            () => mockStake.getFrontierRewardByPage(
              any(),
              pageIndex: any(named: 'pageIndex'),
              pageSize: any(named: 'pageSize'),
            ),
          ).called(1);
        },
      );

      blocTest<StakingRewardsHistoryCubit, StakingRewardsHistoryState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(
            () => mockStake.getFrontierRewardByPage(
              any(),
              pageIndex: any(named: 'pageIndex'),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenThrow(exception);
        },
        build: () => cubit,
        act: (StakingRewardsHistoryCubit cubit) async {
          await cubit.updateStream();
        },
        expect: () => <StakingRewardsHistoryState>[
          const StakingRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          StakingRewardsHistoryState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );

      group('fromJson/toJson', () {
        test('can (de)serialize initial state', () {
          const StakingRewardsHistoryState state = StakingRewardsHistoryState();

          final Map<String, dynamic> json = state.toJson();
          final StakingRewardsHistoryState deserializedState =
              StakingRewardsHistoryState.fromJson(json);

          expect(deserializedState, equals(state));
        });

        test('can (de)serialize loading state', () {
          const StakingRewardsHistoryState state = StakingRewardsHistoryState(
            status: IndicatorStatus.loading,
          );

          final Map<String, dynamic> json = state.toJson();
          final StakingRewardsHistoryState deserializedState =
              StakingRewardsHistoryState.fromJson(json);

          expect(deserializedState, equals(state));
        });

        test('can (de)serialize success state', () {
          final StakingRewardsHistoryState state = StakingRewardsHistoryState(
            status: IndicatorStatus.success,
            data: rewardHistoryList,
          );

          final Map<String, dynamic> json = state.toJson();
          final StakingRewardsHistoryState deserializedState =
              StakingRewardsHistoryState.fromJson(json);

          expect(deserializedState.status, equals(state.status));
          expect(deserializedState.data, equals(state.data));
        });

        test('can (de)serialize failure state', () {
          final StakingRewardsHistoryState failureState =
              StakingRewardsHistoryState(
            status: IndicatorStatus.failure,
            error: exception,
          );

          final Map<String, dynamic> json = failureState.toJson();
          final StakingRewardsHistoryState deserializedState =
              StakingRewardsHistoryState.fromJson(json);

          expect(deserializedState.status, equals(failureState.status));
          expect(deserializedState.error, equals(failureState.error));
        });
      });
    });
  });
}
