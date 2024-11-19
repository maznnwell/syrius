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

  group('SentinelsWithdrawQsrCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late SentinelsWithdrawQsrCubit cubit;
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

      cubit = SentinelsWithdrawQsrCubit(
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
      expect(cubit.state.status, equals(SentinelsWithdrawQsrStatus.initial));
    });

    group('withdrawQsr', () {
      blocTest<SentinelsWithdrawQsrCubit, SentinelsWithdrawQsrState>(
        'emits [loading, success] when withdrawQsr succeeds',
        setUp: () {
          when(() => mockSentinel.withdrawQsr())
              .thenReturn(testAccBlockTemplate);

          when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).thenAnswer((_) async => testAccBlockTemplate);

          // Mock the refresh balance
          when(() => mockZenonAddressUtilsHelper.refreshBalance())
              .thenAnswer((_) async {});
        },
        build: () => cubit,
        act: (SentinelsWithdrawQsrCubit cubit) => cubit.withdrawQsr(),
        expect: () => <SentinelsWithdrawQsrState>[
          const SentinelsWithdrawQsrState(
            status: SentinelsWithdrawQsrStatus.loading,
          ),
          SentinelsWithdrawQsrState(
            status: SentinelsWithdrawQsrStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.withdrawQsr()).called(1);
          verify(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(that: equals(testAccBlockTemplate)),
              'withdraw QSR from Sentinel Slot',
              waitForRequiredPlasma: true,
            ),
          ).called(1);
          verify(() => mockZenonAddressUtilsHelper.refreshBalance()).called(1);
        },
      );

      blocTest<SentinelsWithdrawQsrCubit, SentinelsWithdrawQsrState>(
        'emits [loading, failure] when withdrawQsr fails',
        setUp: () {
          when(() => mockSentinel.withdrawQsr()).thenThrow(exception);
        },
        build: () => cubit,
        act: (SentinelsWithdrawQsrCubit cubit) => cubit.withdrawQsr(),
        expect: () => <SentinelsWithdrawQsrState>[
          const SentinelsWithdrawQsrState(
            status: SentinelsWithdrawQsrStatus.loading,
          ),
          SentinelsWithdrawQsrState(
            status: SentinelsWithdrawQsrStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const SentinelsWithdrawQsrState state = SentinelsWithdrawQsrState();

        final Map<String, dynamic> json = state.toJson();
        final SentinelsWithdrawQsrState deserializedState =
            SentinelsWithdrawQsrState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const SentinelsWithdrawQsrState state = SentinelsWithdrawQsrState(
          status: SentinelsWithdrawQsrStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsWithdrawQsrState deserializedState =
            SentinelsWithdrawQsrState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final SentinelsWithdrawQsrState state = SentinelsWithdrawQsrState(
          status: SentinelsWithdrawQsrStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsWithdrawQsrState deserializedState =
            SentinelsWithdrawQsrState.fromJson(json);

        expect(deserializedState, isA<SentinelsWithdrawQsrState>());
        expect(
          deserializedState.status,
          equals(
            SentinelsWithdrawQsrStatus.success,
          ),
        );
        expect(
          deserializedState.data,
          equals(testAccBlockTemplate),
        );
      });

      test('can (de)serialize failure state', () {
        final SentinelsWithdrawQsrState failureState =
            SentinelsWithdrawQsrState(
          status: SentinelsWithdrawQsrStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final SentinelsWithdrawQsrState deserializedState =
            SentinelsWithdrawQsrState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
