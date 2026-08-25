import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';

part 'p2p_swap_details_event.dart';

part 'p2p_swap_details_state.dart';

/// A bloc that periodically fetches one persisted HTLC swap by id.
class P2pSwapDetailsBloc
    extends Bloc<P2pSwapDetailsEvent, P2pSwapDetailsState> {
  /// Creates a [P2pSwapDetailsBloc].
  P2pSwapDetailsBloc({
    required this._htlcSwapsService,
    required this._swapId,
    this.refreshInterval = const Duration(seconds: 5),
  }) : super(const P2pSwapDetailsInitial()) {
    on<P2pSwapDetailsRequested>(_onSwapDetailsRequested);
    on<_P2pSwapDetailsRefreshRequested>(_onSwapDetailsRequested);
  }

  final HtlcSwapsService _htlcSwapsService;
  final String _swapId;

  /// The interval at which swap details are refreshed.
  final Duration refreshInterval;

  Timer? _autoRefresher;

  FutureOr<void> _onSwapDetailsRequested(
    P2pSwapDetailsEvent event,
    Emitter<P2pSwapDetailsState> emit,
  ) {
    try {
      if (state is! P2pSwapDetailsPopulated) {
        emit(const P2pSwapDetailsLoading());
      }

      emit(P2pSwapDetailsPopulated(swap: _getSwap()));
    } on SyriusException catch (e, stackTrace) {
      emit(P2pSwapDetailsFailure(exception: e));
      addError(e, stackTrace);
    } on Object catch (e, stackTrace) {
      emit(P2pSwapDetailsFailure(exception: FailureException()));
      addError(e, stackTrace);
    } finally {
      _scheduleRefresh();
    }
  }

  HtlcSwap _getSwap() {
    final HtlcSwap? swap = _htlcSwapsService.getSwapById(_swapId);
    if (swap == null) {
      throw SyriusException('Swap does not exist');
    }

    return swap;
  }

  void _scheduleRefresh() {
    if (isClosed || (_autoRefresher?.isActive ?? false)) {
      return;
    }

    _autoRefresher = Timer(
      refreshInterval,
      () {
        if (!isClosed) {
          add(const _P2pSwapDetailsRefreshRequested());
        }
      },
    );
  }

  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }
}
