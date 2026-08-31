import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  const int latestSafeJoinTime = 100000;
  final HtlcInfo initialHtlc = HtlcInfo(
    id: Hash.digest(<int>[1, 2, 3]),
    timeLocked: htlcAddress,
    hashLocked: emptyAddress,
    tokenStandard: znnZts,
    amount: BigInt.one,
    expirationTime:
        latestSafeJoinTime +
        kMinSafeTimeToFindPreimage.inSeconds +
        kCounterHtlcDuration.inSeconds,
    hashType: htlcHashTypeSha3,
    keyMaxSize: htlcPreimageMaxLength,
    hashLock: <int>[4, 5, 6],
  );
  late int unixTime;

  setUp(() {
    unixTime = latestSafeJoinTime;
  });

  test('initial state is available before the cutoff', () async {
    unixTime = latestSafeJoinTime - 1;
    final JoinSwapAvailabilityCubit cubit = JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      unixTimeProvider: () => unixTime,
    );

    expect(
      cubit.state,
      const JoinSwapAvailable(minutesLeftToJoin: 1),
    );
    await cubit.close();
  });

  test('initial state is available exactly at the cutoff', () async {
    final JoinSwapAvailabilityCubit cubit = JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      unixTimeProvider: () => unixTime,
    );

    expect(
      cubit.state,
      const JoinSwapAvailable(minutesLeftToJoin: 0),
    );
    await cubit.close();
  });

  blocTest<JoinSwapAvailabilityCubit, JoinSwapAvailabilityState>(
    'emits unavailable after the cutoff',
    build: () => JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      unixTimeProvider: () => unixTime,
    ),
    act: (JoinSwapAvailabilityCubit cubit) {
      unixTime = latestSafeJoinTime + 1;
      cubit.checkAvailability();
    },
    expect: () => <JoinSwapAvailabilityState>[
      const JoinSwapUnavailable(),
    ],
  );
}
