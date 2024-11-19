import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/sentinels/sentinels.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinel extends Mock implements SentinelApi {}

class MockAccountBlockUtilsHelper extends Mock
    implements AccountBlockUtilsHelper {}

class MockZenonAddressUtilsHelper extends Mock
    implements ZenonAddressUtilsHelper {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockAccountBlockTemplate());
  });

  group('SentinelsDeployCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late SentinelsDeployCubit cubit;
    late CubitFailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockAccountBlockUtilsHelper = MockAccountBlockUtilsHelper();
      mockZenonAddressUtilsHelper = MockZenonAddressUtilsHelper();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = CubitFailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(() => mockSentinel.register()).thenReturn(testAccBlockTemplate);

      when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccBlockTemplate);

      when(() => mockZenonAddressUtilsHelper.refreshBalance())
          .thenAnswer((_) async {});

      cubit = SentinelsDeployCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtilsHelper,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(SentinelsDeployStatus.initial));
    });

    group('deploySentinel', () {
      blocTest<SentinelsDeployCubit, SentinelsDeployState>(
        'emits [loading, success] when deploySentinel succeeds',
        build: () => cubit,
        act: (SentinelsDeployCubit cubit) => cubit.deploySentinel(),
        expect: () => <SentinelsDeployState>[
          const SentinelsDeployState(
            status: SentinelsDeployStatus.loading,
          ),
          SentinelsDeployState(
            status: SentinelsDeployStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.register()).called(1);
          verify(
                () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              'register Sentinel',
              waitForRequiredPlasma: true,
            ),
          ).called(1);
          verify(() => mockZenonAddressUtilsHelper.refreshBalance()).called(1);
        },
      );

      blocTest<SentinelsDeployCubit, SentinelsDeployState>(
        'emits [loading, failure] when deploySentinel fails',
        setUp: () {
          when(() => mockSentinel.register()).thenThrow(exception);
        },
        build: () => cubit,
        act: (SentinelsDeployCubit cubit) => cubit.deploySentinel(),
        expect: () => <SentinelsDeployState>[
          const SentinelsDeployState(
            status: SentinelsDeployStatus.loading,
          ),
          SentinelsDeployState(
            status: SentinelsDeployStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const SentinelsDeployState state = SentinelsDeployState();

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDeployState deserializedState =
        SentinelsDeployState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const SentinelsDeployState state = SentinelsDeployState(
          status: SentinelsDeployStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDeployState deserializedState =
        SentinelsDeployState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final SentinelsDeployState state = SentinelsDeployState(
          status: SentinelsDeployStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDeployState deserializedState =
        SentinelsDeployState.fromJson(json);

        expect(deserializedState, isA<SentinelsDeployState>());
        expect(
          deserializedState.status,
          equals(
            SentinelsDeployStatus.success,
          ),
        );
        expect(
          deserializedState.data,
          equals(testAccBlockTemplate),
        );
      });

      test('can (de)serialize failure state', () {
        final SentinelsDeployState failureState = SentinelsDeployState(
          status: SentinelsDeployStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final SentinelsDeployState deserializedState =
        SentinelsDeployState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
