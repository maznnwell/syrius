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
  registerFallbackValue(FakeAddress());

  group('GetSentinelByOwner', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late GetSentinelByOwnerCubit cubit;
    late Address testAddress;
    late FailureException exception;
    late SentinelInfo sentinelInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress;
      exception = FailureException();
      
      final Map<String, dynamic> sentinelInfoJson = <String, dynamic> {
        'owner': emptyAddress.toString(),
        'registrationTimestamp': 1,
        'isRevocable': true,
        'revokeCooldown': 1,
        'active': true,
      };

      sentinelInfo = SentinelInfo.fromJson(sentinelInfoJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);

      cubit = GetSentinelByOwnerCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, IndicatorStatus.initial);
    });

    group('GetSentinelByOwner toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const GetSentinelByOwnerState initialState = GetSentinelByOwnerState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final GetSentinelByOwnerState deserialized =
        GetSentinelByOwnerState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const GetSentinelByOwnerState loadingState = GetSentinelByOwnerState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final GetSentinelByOwnerState deserialized =
        GetSentinelByOwnerState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final GetSentinelByOwnerState successState = GetSentinelByOwnerState(
          status: IndicatorStatus.success,
          data: sentinelInfo,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final GetSentinelByOwnerState deserialized =
        GetSentinelByOwnerState.fromJson(serialized);


        expect(deserialized, isA<GetSentinelByOwnerState>());
        expect(deserialized.status,
          equals(IndicatorStatus.success),);
        expect(deserialized.data, equals(sentinelInfo));
      });

      test('can (de)serialize failure state', () {
        final GetSentinelByOwnerState failureState = GetSentinelByOwnerState(
          status: IndicatorStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final GetSentinelByOwnerState deserialized =
        GetSentinelByOwnerState.fromJson(serialized);

        expect(deserialized.status, equals(IndicatorStatus.failure));
      });
    });

    group('updateStream', () {
      blocTest<GetSentinelByOwnerCubit, GetSentinelByOwnerState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockSentinel.getByOwner(any()))
              .thenAnswer((_) async => sentinelInfo);
        },
        build: () => cubit,
        act: (GetSentinelByOwnerCubit cubit) => cubit.updateStream(),
        expect: () => <GetSentinelByOwnerState>[
          const GetSentinelByOwnerState(status: IndicatorStatus.loading),
          GetSentinelByOwnerState(
            status: IndicatorStatus.success,
            data: sentinelInfo,
          ),
        ],
        verify: (_) {
          verify(() => mockSentinel.getByOwner(any())).called(1);
        },
      );

      blocTest<GetSentinelByOwnerCubit, GetSentinelByOwnerState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockSentinel.getByOwner(any())).thenThrow(exception);
        },
        build: () => cubit,
        act: (GetSentinelByOwnerCubit cubit) => cubit.updateStream(),
        expect: () => <GetSentinelByOwnerState>[
          const GetSentinelByOwnerState(status: IndicatorStatus.loading),
          GetSentinelByOwnerState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
