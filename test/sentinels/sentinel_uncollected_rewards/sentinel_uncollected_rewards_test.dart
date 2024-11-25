import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  group('SentinelUncollectedRewardsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelUncollectedRewardsCubit sentinelUncollectedRewardsCubit;
    late UncollectedReward uncollectedReward;
    late FailureException exception;
    late Address testAddress;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockWsClient = MockWsClient();
      testAddress = FakeAddress();
      exception = FailureException();

      final Map<String, dynamic> uncollectedRewardJson = <String, dynamic>{
        'address': emptyAddress.toString(),
        'znnAmount': '1',
        'qsrAmount': '1',
      };
      uncollectedReward = UncollectedReward.fromJson(uncollectedRewardJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);

      sentinelUncollectedRewardsCubit = SentinelUncollectedRewardsCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      sentinelUncollectedRewardsCubit.close();
    });

    test('initial state is correct', () {
      expect(
        sentinelUncollectedRewardsCubit.state.status,
        IndicatorStatus.initial,
      );
    });

    group('SentinelUncollectedRewards toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const SentinelUncollectedRewardsState initialState =
            SentinelUncollectedRewardsState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final SentinelUncollectedRewardsState deserialized =
            SentinelUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const SentinelUncollectedRewardsState loadingState =
            SentinelUncollectedRewardsState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final SentinelUncollectedRewardsState deserialized =
            SentinelUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final SentinelUncollectedRewardsState successState =
            SentinelUncollectedRewardsState(
          status: IndicatorStatus.success,
          data: uncollectedReward,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final SentinelUncollectedRewardsState deserialized =
            SentinelUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, isA<SentinelUncollectedRewardsState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.success),
        );
        expect(deserialized.data, equals(uncollectedReward));
      });

      test('can (de)serialize failure state', () {
        final SentinelUncollectedRewardsState failureState =
            SentinelUncollectedRewardsState(
          status: IndicatorStatus.failure,
          error: exception,
        );
        final Map<String, dynamic> serialized = failureState.toJson();
        final SentinelUncollectedRewardsState deserialized =
            SentinelUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('updateStream', () {
      blocTest<SentinelUncollectedRewardsCubit,
          SentinelUncollectedRewardsState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockSentinel.getUncollectedReward(any()))
              .thenAnswer((_) async => uncollectedReward);
        },
        build: () => sentinelUncollectedRewardsCubit,
        act: (SentinelUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <SentinelUncollectedRewardsState>[
          const SentinelUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          SentinelUncollectedRewardsState(
            status: IndicatorStatus.success,
            data: uncollectedReward,
          ),
        ],
      );

      blocTest<SentinelUncollectedRewardsCubit,
          SentinelUncollectedRewardsState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockSentinel.getUncollectedReward(any()))
              .thenThrow(exception);
        },
        build: () => sentinelUncollectedRewardsCubit,
        act: (SentinelUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <SentinelUncollectedRewardsState>[
          const SentinelUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          SentinelUncollectedRewardsState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
