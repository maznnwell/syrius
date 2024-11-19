import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
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

class MockBuildContext extends Mock implements BuildContext {}

class MockDuration extends Mock implements Duration {}


void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockAccountBlockTemplate());
    registerFallbackValue(BigInt.from(1000));
  });

  group('SentinelsDepositQsrCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late SentinelsDepositQsrCubit cubit;
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

      cubit = SentinelsDepositQsrCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtilsHelper,
        duration: Duration.zero,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(SentinelsDepositQsrStatus.initial));
    });

    group('depositQsr', () {
      blocTest<SentinelsDepositQsrCubit, SentinelsDepositQsrState>(
        'emits [loading, success] when depositQsr succeeds',
        setUp: () {
          when(() => mockSentinel.depositQsr(any()))
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
        act: (SentinelsDepositQsrCubit cubit) =>
            cubit.depositQsr(BigInt.from(1000)),
        expect: () => <SentinelsDepositQsrState>[
          const SentinelsDepositQsrState(
            status: SentinelsDepositQsrStatus.loading,
          ),
          SentinelsDepositQsrState(
            status: SentinelsDepositQsrStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.depositQsr(BigInt.from(1000))).called(1);
          verify(
                () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(that: equals(testAccBlockTemplate)),
              'deposit QSR for Sentinel Slot',
              waitForRequiredPlasma: true,
            ),
          ).called(1);
          verify(() => mockZenonAddressUtilsHelper.refreshBalance()).called(1);
        },
      );

      blocTest<SentinelsDepositQsrCubit, SentinelsDepositQsrState>(
        'emits [loading, failure] when depositQsr fails',
        setUp: () {
          when(() => mockSentinel.depositQsr(any())).thenThrow(exception);
        },
        build: () => cubit,
        act: (SentinelsDepositQsrCubit cubit) =>
            cubit.depositQsr(BigInt.from(1000)),
        expect: () => <SentinelsDepositQsrState>[
          const SentinelsDepositQsrState(
            status: SentinelsDepositQsrStatus.loading,
          ),
          SentinelsDepositQsrState(
            status: SentinelsDepositQsrStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const SentinelsDepositQsrState state = SentinelsDepositQsrState();

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDepositQsrState deserializedState =
        SentinelsDepositQsrState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const SentinelsDepositQsrState state = SentinelsDepositQsrState(
          status: SentinelsDepositQsrStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDepositQsrState deserializedState =
        SentinelsDepositQsrState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final SentinelsDepositQsrState state = SentinelsDepositQsrState(
          status: SentinelsDepositQsrStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsDepositQsrState deserializedState =
        SentinelsDepositQsrState.fromJson(json);

        expect(deserializedState, isA<SentinelsDepositQsrState>());
        expect(
          deserializedState.status,
          equals(
            SentinelsDepositQsrStatus.success,
          ),
        );
        expect(
          deserializedState.data,
          equals(testAccBlockTemplate),
        );
      });

      test('can (de)serialize failure state', () {
        final SentinelsDepositQsrState failureState = SentinelsDepositQsrState(
          status: SentinelsDepositQsrStatus.failure,
          error: exception,
          // Note: error is ignored during serialization
        );

        final Map<String, dynamic> json = failureState.toJson();
        final SentinelsDepositQsrState deserializedState =
        SentinelsDepositQsrState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
