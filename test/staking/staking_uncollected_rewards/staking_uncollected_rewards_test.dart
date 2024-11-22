import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/staking/staking.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('StakingUncollectedRewardsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late StakingUncollectedRewardsCubit stakingUncollectedRewardsCubit;
    late UncollectedReward uncollectedReward;
    late CubitFailureException exception;
    late Address testAddress;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      mockWsClient = MockWsClient();
      testAddress = FakeAddress();
      exception = CubitFailureException();

      final Map<String, dynamic> uncollectedRewardJson = <String, dynamic>{
        'address': emptyAddress.toString(),
        'znnAmount': '1',
        'qsrAmount': '1',
      };
      uncollectedReward = UncollectedReward.fromJson(uncollectedRewardJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);

      stakingUncollectedRewardsCubit = StakingUncollectedRewardsCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      stakingUncollectedRewardsCubit.close();
    });

    test('initial state is correct', () {
      expect(
        stakingUncollectedRewardsCubit.state.status,
        IndicatorStatus.initial,
      );
    });

    group('StakingUncollectedRewards toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const StakingUncollectedRewardsState initialState =
        StakingUncollectedRewardsState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final StakingUncollectedRewardsState deserialized =
        StakingUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const StakingUncollectedRewardsState loadingState =
        StakingUncollectedRewardsState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final StakingUncollectedRewardsState deserialized =
        StakingUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final StakingUncollectedRewardsState successState =
        StakingUncollectedRewardsState(
          status: IndicatorStatus.success,
          data: uncollectedReward,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final StakingUncollectedRewardsState deserialized =
        StakingUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, isA<StakingUncollectedRewardsState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.success),
        );
        expect(deserialized.data, equals(uncollectedReward));
      });

      test('can (de)serialize failure state', () {
        final StakingUncollectedRewardsState failureState =
        StakingUncollectedRewardsState(
          status: IndicatorStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final StakingUncollectedRewardsState deserialized =
        StakingUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('updateStream', () {
      blocTest<StakingUncollectedRewardsCubit,
          StakingUncollectedRewardsState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockStake.getUncollectedReward(any()))
              .thenAnswer((_) async => uncollectedReward);
        },
        build: () => stakingUncollectedRewardsCubit,
        act: (StakingUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <StakingUncollectedRewardsState>[
          const StakingUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          StakingUncollectedRewardsState(
            status: IndicatorStatus.success,
            data: uncollectedReward,
          ),
        ],
      );

      blocTest<StakingUncollectedRewardsCubit,
          StakingUncollectedRewardsState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockStake.getUncollectedReward(any()))
              .thenThrow(exception);
        },
        build: () => stakingUncollectedRewardsCubit,
        act: (StakingUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <StakingUncollectedRewardsState>[
          const StakingUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          StakingUncollectedRewardsState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
