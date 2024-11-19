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

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockAccountBlockTemplate());
  });

  group('DisassembleSentinelCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late MockZenonAddressUtilsHelper mockZenonAddressUtilsHelper;
    late AccountBlockTemplate testAccBlockTemplate;
    late DisassembleSentinelCubit cubit;
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
      when(() => mockSentinel.revoke()).thenReturn(testAccBlockTemplate);

      when(
        () => mockAccountBlockUtilsHelper.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccBlockTemplate);

      when(() => mockZenonAddressUtilsHelper.refreshBalance())
          .thenAnswer((_) async {});

      cubit = DisassembleSentinelCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtilsHelper,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(DisassembleSentinelStatus.initial));
    });

    group('disassembleSentinel', () {
      blocTest<DisassembleSentinelCubit, DisassembleSentinelState>(
        'emits [loading, success] when disassembleSentinel succeeds',
        build: () => cubit,
        act: (DisassembleSentinelCubit cubit) =>
            cubit.disassembleSentinel(MockBuildContext()),
        expect: () => <DisassembleSentinelState>[
          const DisassembleSentinelState(
            status: DisassembleSentinelStatus.loading,
          ),
          DisassembleSentinelState(
            status: DisassembleSentinelStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.revoke()).called(1);
          verify(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              'disassemble Sentinel',
              waitForRequiredPlasma: true,
            ),
          ).called(1);
          verify(() => mockZenonAddressUtilsHelper.refreshBalance()).called(1);
        },
      );

      blocTest<DisassembleSentinelCubit, DisassembleSentinelState>(
        'emits [loading, failure] when disassembleSentinel fails',
        setUp: () {
          // Mock the revoke method to throw an exception
          when(() => mockSentinel.revoke()).thenThrow(exception);
        },
        build: () => cubit,
        act: (DisassembleSentinelCubit cubit) =>
            cubit.disassembleSentinel(MockBuildContext()),
        expect: () => <DisassembleSentinelState>[
          const DisassembleSentinelState(
            status: DisassembleSentinelStatus.loading,
          ),
          DisassembleSentinelState(
            status: DisassembleSentinelStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DisassembleSentinelState state = DisassembleSentinelState();

        final Map<String, dynamic> json = state.toJson();
        final DisassembleSentinelState deserializedState =
            DisassembleSentinelState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const DisassembleSentinelState state = DisassembleSentinelState(
          status: DisassembleSentinelStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final DisassembleSentinelState deserializedState =
            DisassembleSentinelState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final DisassembleSentinelState state = DisassembleSentinelState(
          status: DisassembleSentinelStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> json = state.toJson();
        final DisassembleSentinelState deserializedState =
            DisassembleSentinelState.fromJson(json);

        expect(deserializedState, isA<DisassembleSentinelState>());
        expect(
          deserializedState.status,
          equals(
            DisassembleSentinelStatus.success,
          ),
        );
        expect(
          deserializedState.data,
          equals(testAccBlockTemplate),
        );
      });

      test('can (de)serialize failure state', () {
        final DisassembleSentinelState failureState = DisassembleSentinelState(
          status: DisassembleSentinelStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final DisassembleSentinelState deserializedState =
            DisassembleSentinelState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
