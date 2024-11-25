import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/sentinels_qsr_info.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/sentinels/sentinels.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinel extends Mock implements SentinelApi {}

class MockSentinelsQsrInfo extends Mock implements SentinelsQsrInfo {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(MockSentinelsQsrInfo());
    registerFallbackValue(FakeAddress());
  });

  group('SentinelsQsrInfoCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelsQsrInfoCubit cubit;
    late FailureException exception;
    late String testAddress;
    late SentinelsQsrInfo testQsrInfo;
    late BigInt deposit;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      exception = FailureException();
      testAddress = emptyAddress.toString();
      deposit = BigInt.from(1000);

      testQsrInfo = SentinelsQsrInfo(
        cost: sentinelRegisterQsrAmount,
        deposit: deposit,
      );

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(() => mockSentinel.getDepositedQsr(any()))
          .thenAnswer((_) async => deposit);

      cubit = SentinelsQsrInfoCubit(
        zenon: mockZenon,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, equals(SentinelsQsrInfoStatus.initial));
    });

    group('getQsrManagementInfo', () {
      blocTest<SentinelsQsrInfoCubit, SentinelsQsrInfoState>(
        'emits [loading, success] when getQsrManagementInfo succeeds',
        setUp: () {

        },
        build: () => cubit,
        act: (SentinelsQsrInfoCubit cubit) =>
            cubit.getQsrManagementInfo(testAddress),
        expect: () => <SentinelsQsrInfoState>[
          const SentinelsQsrInfoState(
            status: SentinelsQsrInfoStatus.loading,
          ),
          SentinelsQsrInfoState(
            status: SentinelsQsrInfoStatus.success,
            data: testQsrInfo,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.getDepositedQsr(any())).called(1);
        },
      );

      blocTest<SentinelsQsrInfoCubit, SentinelsQsrInfoState>(
        'emits [loading, failure] when getQsrManagementInfo fails',
        setUp: () {
          when(() => mockSentinel.getDepositedQsr(any())).thenThrow(exception);
        },
        build: () => cubit,
        act: (SentinelsQsrInfoCubit cubit) =>
            cubit.getQsrManagementInfo(testAddress),
        expect: () => <SentinelsQsrInfoState>[
          const SentinelsQsrInfoState(
            status: SentinelsQsrInfoStatus.loading,
          ),
          SentinelsQsrInfoState(
            status: SentinelsQsrInfoStatus.failure,
            error: exception,
          ),
        ],
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const SentinelsQsrInfoState state = SentinelsQsrInfoState();

        final Map<String, dynamic> json = state.toJson();
        final SentinelsQsrInfoState deserializedState =
            SentinelsQsrInfoState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize loading state', () {
        const SentinelsQsrInfoState state = SentinelsQsrInfoState(
          status: SentinelsQsrInfoStatus.loading,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsQsrInfoState deserializedState =
            SentinelsQsrInfoState.fromJson(json);

        expect(deserializedState, equals(state));
      });

      test('can (de)serialize success state', () {
        final SentinelsQsrInfo data = SentinelsQsrInfo(
          deposit: BigInt.from(1000),
          cost: sentinelRegisterQsrAmount,
        );

        final SentinelsQsrInfoState state = SentinelsQsrInfoState(
          status: SentinelsQsrInfoStatus.success,
          data: data,
        );

        final Map<String, dynamic> json = state.toJson();
        final SentinelsQsrInfoState deserializedState =
            SentinelsQsrInfoState.fromJson(json);

        expect(deserializedState.status, equals(state.status));
        expect(deserializedState.data, equals(state.data));
      });

      test('can (de)serialize failure state', () {
        final SentinelsQsrInfoState failureState = SentinelsQsrInfoState(
          status: SentinelsQsrInfoStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> json = failureState.toJson();
        final SentinelsQsrInfoState deserializedState =
            SentinelsQsrInfoState.fromJson(json);

        expect(deserializedState, equals(failureState));
      });
    });
  });
}
