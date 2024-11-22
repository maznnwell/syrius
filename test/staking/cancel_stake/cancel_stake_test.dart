import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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

class MockBuildContext extends Mock implements BuildContext {}

class FakeHash extends Fake implements Hash {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockAccountBlockTemplate());
    registerFallbackValue(MockBuildContext());
    registerFallbackValue(FakeHash());
  });

  group('CancelStakeCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late CancelStakeCubit cubit;
    late CubitFailureException exception;
    late String testHash;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      mockAccountBlockUtilsHelper = MockAccountBlockUtilsHelper();
      mockZenonAddressUtilsHelper = MockZenonAddressUtilsHelper();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = CubitFailureException();
      testHash = emptyHash.toString();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);

      cubit = CancelStakeCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtilsHelper,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(CancelStakeStatus.initial));
    });

    group('cancelStake', () {
      blocTest<CancelStakeCubit, CancelStakeState>(
        'emits [loading, success] when cancelStake succeeds',
        setUp: () {
          when(() => mockStake.cancel(any()))
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
        act: (CancelStakeCubit cubit) => cubit.cancelStake(
          testHash,
          MockBuildContext(),
        ),
        expect: () => <CancelStakeState>[
          const CancelStakeState(
            status: CancelStakeStatus.loading,
          ),
          CancelStakeState(
            status: CancelStakeStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockStake.cancel(any())).called(1);
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

      blocTest<CancelStakeCubit, CancelStakeState>(
        'emits [loading, failure] when cancelStake fails',
        setUp: () {
          when(() => mockStake.cancel(any())).thenThrow(exception);
        },
        build: () => cubit,
        act: (CancelStakeCubit cubit) => cubit.cancelStake(
          testHash,
          MockBuildContext(),
        ),
        expect: () => <CancelStakeState>[
          const CancelStakeState(
            status: CancelStakeStatus.loading,
          ),
          CancelStakeState(
            status: CancelStakeStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const CancelStakeState state = CancelStakeState();

        final Map<String, dynamic> json = state.toJson();
        final CancelStakeState deserializedState =
        CancelStakeState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const CancelStakeState state = CancelStakeState(
          status: CancelStakeStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final CancelStakeState deserializedState =
        CancelStakeState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final CancelStakeState state = CancelStakeState(
          status: CancelStakeStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final CancelStakeState deserializedState =
        CancelStakeState.fromJson(json);

        expect(deserializedState, isA<CancelStakeState>());
        expect(deserializedState.status, equals(CancelStakeStatus.success));
        expect(deserializedState.data, equals(testAccBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final CancelStakeState failureState = CancelStakeState(
          status: CancelStakeStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final CancelStakeState deserializedState =
        CancelStakeState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
