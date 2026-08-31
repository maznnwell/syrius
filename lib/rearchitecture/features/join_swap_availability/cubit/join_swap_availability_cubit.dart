import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'join_swap_availability_state.dart';

/// Tracks whether an initial HTLC still has enough time to be joined safely.
class JoinSwapAvailabilityCubit extends Cubit<JoinSwapAvailabilityState> {
  /// Creates a [JoinSwapAvailabilityCubit].
  JoinSwapAvailabilityCubit({
    required HtlcInfo initialHtlc,
    this._refreshInterval = const Duration(seconds: 5),
    int Function()? unixTimeProvider,
  }) : _initialHtlc = initialHtlc,
       _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(
         _stateAt(
           initialHtlc,
           (unixTimeProvider ?? _currentUnixTime)(),
         ),
       ) {
    if (state is JoinSwapAvailable) {
      _startRefreshing();
    }
  }

  final HtlcInfo _initialHtlc;
  final int Function() _unixTimeProvider;
  final Duration _refreshInterval;

  Timer? _autoRefresher;

  static int _currentUnixTime() => DateTimeUtils.unixTimeNow;

  static JoinSwapAvailabilityState _stateAt(
    HtlcInfo initialHtlc,
    int unixTime,
  ) {
    if (!initialHtlc.canBeSafelyJoinedAt(unixTime)) {
      return const JoinSwapUnavailable();
    }

    return JoinSwapAvailable(
      minutesLeftToJoin: initialHtlc.minutesLeftToJoinAt(unixTime),
    );
  }

  /// Recalculates whether the initial HTLC can still be joined safely.
  void checkAvailability() {
    if (isClosed) {
      return;
    }

    final JoinSwapAvailabilityState nextState = _stateAt(
      _initialHtlc,
      _unixTimeProvider(),
    );
    if (nextState is JoinSwapUnavailable) {
      _autoRefresher?.cancel();
    }
    emit(nextState);
  }

  void _startRefreshing() {
    _autoRefresher = Timer.periodic(_refreshInterval, (_) {
      if (!isClosed) {
        checkAvailability();
      }
    });
  }

  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }
}
