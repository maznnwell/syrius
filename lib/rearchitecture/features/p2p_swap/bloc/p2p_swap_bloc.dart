import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';

part 'p2p_swap_event.dart';

part 'p2p_swap_state.dart';

/// A bloc that periodically fetches one persisted HTLC swap by id.
class P2pSwapBloc extends Bloc<P2pSwapEvent, P2pSwapBlocState> {
  /// Creates a [P2pSwapBloc].
  P2pSwapBloc({
    required this._htlcSwapsService,
    required this._swapId,
    this.refreshInterval = const Duration(seconds: 5),
  }) : super(const P2pSwapInitial()) {
    on<P2pSwapRequested>(_onSwapRequested);
    on<_P2pSwapRefreshRequested>(_onSwapRequested);
  }

  final HtlcSwapsService _htlcSwapsService;
  final String _swapId;

  /// The interval at which swap details are refreshed.
  final Duration refreshInterval;

  Timer? _autoRefresher;

  FutureOr<void> _onSwapRequested(
    P2pSwapEvent event,
    Emitter<P2pSwapBlocState> emit,
  ) {
    try {
      if (state is! P2pSwapPopulated) {
        emit(const P2pSwapLoading());
      }

      emit(P2pSwapPopulated(swap: _getSwap()));
    } on SyriusException catch (e, stackTrace) {
      emit(P2pSwapFailure(exception: e));
      addError(e, stackTrace);
    } on Object catch (e, stackTrace) {
      emit(P2pSwapFailure(exception: FailureException()));
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
          add(const _P2pSwapRefreshRequested());
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
