import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'p2p_swaps_event.dart';

part 'p2p_swaps_state.dart';

/// A bloc that periodically fetches persisted P2P swaps.
class P2pSwapsBloc extends Bloc<P2pSwapsEvent, P2pSwapsState> {
  /// Creates a [P2pSwapsBloc].
  P2pSwapsBloc({
    required this._swapRepository,
    this._refreshInterval = const Duration(seconds: 5),
  }) : super(const P2pSwapsInitial()) {
    on<P2pSwapsRequested>(_onP2pSwapsRequested);
    on<_P2pSwapsRefreshRequested>(_onP2pSwapsRequested);
  }

  final P2pSwapRepository<HtlcSwap> _swapRepository;
  final Duration _refreshInterval;

  Timer? _autoRefresher;

  Future<void> _onP2pSwapsRequested(
    P2pSwapsEvent event,
    Emitter<P2pSwapsState> emit,
  ) async {
    try {
      if (state is! P2pSwapsPopulated) {
        emit(const P2pSwapsLoading());
      }

      emit(P2pSwapsPopulated(swaps: await _getSwaps()));
    } on SyriusException catch (error, stackTrace) {
      emit(P2pSwapsFailure(exception: error));
      addError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      emit(P2pSwapsFailure(exception: FailureException()));
      addError(error, stackTrace);
    } finally {
      _scheduleRefresh();
    }
  }

  Future<List<P2pSwap>> _getSwaps() async {
    final List<HtlcSwap> swaps = await _swapRepository.getAllSwaps()
      ..sort((HtlcSwap a, HtlcSwap b) => b.startTime.compareTo(a.startTime));
    return swaps;
  }

  void _scheduleRefresh() {
    if (isClosed || (_autoRefresher?.isActive ?? false)) {
      return;
    }

    _autoRefresher = Timer(_refreshInterval, () {
      if (!isClosed) {
        add(const _P2pSwapsRefreshRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }
}
