import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class TestState extends DashboardState<bool> {
  const TestState({
    super.status,
    super.data,
    super.error,
  });

  @override
  DashboardState<bool> copyWith({CubitStatus? status, bool? data, Object? error}) {
    return TestState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

class TestCubit extends DashboardCubit<bool> {
  TestCubit(super.zenon, super.initialState);

  @override
  Future<bool> fetch() async {
   return Future.delayed(
      const Duration(milliseconds: 300),
          () => Random().nextBool(),
    );
  }
}

//TODO: WORK IN PROGRESS;

void main() {

  group('DashboardCubit', () {
    late MockZenon mockZenon;
    late TestCubit testCubit;
    late Exception testException;

    setUp(() async {
      mockZenon = MockZenon();
      testCubit = TestCubit(
        mockZenon,
        TestState(),
      );
      testException = Exception('Test exception');
      when(
            () => testCubit.fetch(),
      ).thenAnswer((_) async => true);
    });

    test('initial status is correct', () {
      expect(testCubit.state.status, CubitStatus.initial);
    });

    blocTest<TestCubit, DashboardState>(
      'emits [loading, failure] when fetch() throws',
      setUp: () {
        when(
              () => testCubit.fetch(),
        ).thenThrow(testException);
      },

      build: () => testCubit,
      act: (cubit) => cubit.fetchDataPeriodically(),
      expect: () => <TestState>[
        TestState(status: CubitStatus.loading),
        TestState(
          status: CubitStatus.failure,
          error: testException,
        ),
      ],
    );

    blocTest<TestCubit, DashboardState>(
        'emits [loading, success] when fetch() returns (bool)',
        // setUp: () {
        //   when(
        //         () => testCubit.fetch(),
        //   ).thenReturn(true as Future<bool>);
        // },
        build: () => testCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <TestState>[
          TestState(status: CubitStatus.loading),
          TestState(status: CubitStatus.success),
        ]
    );
  });

}