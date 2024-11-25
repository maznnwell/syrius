import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/staking/staking.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class MockAccountBlockUtilsHelper extends Mock
    implements AccountBlockUtilsHelper {}

class MockZenonAddressUtilsHelper extends Mock
    implements ZenonAddressUtilsHelper {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

class FakeDuration extends Fake implements Duration {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockAccountBlockTemplate());
    registerFallbackValue(FakeDuration());
    registerFallbackValue(BigInt.from(1000));
  });

  group('StakingOptionsCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late StakingOptionsCubit cubit;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      mockAccountBlockUtilsHelper = MockAccountBlockUtilsHelper();
      mockZenonAddressUtilsHelper = MockZenonAddressUtilsHelper();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);

      cubit = StakingOptionsCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtilsHelper,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(StakingOptionsStatus.initial));
    });

    group('stakeForQsr', () {
      blocTest<StakingOptionsCubit, StakingOptionsState>(
        'emits [loading, success] when stakeForQsr succeeds',
        setUp: () {
          when(() => mockStake.stake(any(), any()))
              .thenReturn(testAccBlockTemplate);

          when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).thenAnswer((_) async => testAccBlockTemplate);

          when(() => mockZenonAddressUtilsHelper.refreshBalance())
              .thenAnswer((_) async {});
        },
        build: () => cubit,
        act: (StakingOptionsCubit cubit) => cubit.stakeForQsr(
          Duration.zero,
          BigInt.from(1000),
        ),
        expect: () => <StakingOptionsState>[
          const StakingOptionsState(
            status: StakingOptionsStatus.loading,
          ),
          StakingOptionsState(
            status: StakingOptionsStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockStake.stake(any(), any())).called(1);
          verify(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).called(1);
          verify(() => mockZenonAddressUtilsHelper.refreshBalance()).called(1);
        },
      );

      blocTest<StakingOptionsCubit, StakingOptionsState>(
        'emits [loading, failure] when stakeForQsr fails',
        setUp: () {
          when(() => mockStake.stake(any(), any()))
              .thenThrow(exception);
        },
        build: () => cubit,
        act: (StakingOptionsCubit cubit) => cubit.stakeForQsr(
          Duration.zero,
          BigInt.from(1000),
        ),
        expect: () => <StakingOptionsState>[
          const StakingOptionsState(
            status: StakingOptionsStatus.loading,
          ),
          StakingOptionsState(
            status: StakingOptionsStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const StakingOptionsState state = StakingOptionsState();

        final Map<String, dynamic> json = state.toJson();
        final StakingOptionsState deserializedState =
            StakingOptionsState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const StakingOptionsState state = StakingOptionsState(
          status: StakingOptionsStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final StakingOptionsState deserializedState =
            StakingOptionsState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final StakingOptionsState state = StakingOptionsState(
          status: StakingOptionsStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final StakingOptionsState deserializedState =
            StakingOptionsState.fromJson(json);

        expect(deserializedState, isA<StakingOptionsState>());
        expect(deserializedState.status, equals(StakingOptionsStatus.success));
        expect(deserializedState.data, equals(testAccBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final StakingOptionsState failureState = StakingOptionsState(
          status: StakingOptionsStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final StakingOptionsState deserializedState =
            StakingOptionsState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
