import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'complete_swap_event.dart';

part 'complete_swap_state.dart';

/// Completes an HTLC swap by unlocking the counterparty deposit.
class CompleteSwapBloc extends Bloc<CompleteSwapEvent, CompleteSwapState> {
  /// Creates a [CompleteSwapBloc].
  CompleteSwapBloc({
    required this._accountBlockUtils,
    required this._htlcSwapsService,
    required this._zenon,
    required this._zenonAddressUtils,
    int Function()? unixTimeProvider,
  }) : _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(const CompleteSwapInitial()) {
    on<CompleteSwapRequested>(_onCompleteSwapRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final HtlcSwapsService _htlcSwapsService;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;
  final int Function() _unixTimeProvider;

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  FutureOr<void> _onCompleteSwapRequested(
    CompleteSwapRequested event,
    Emitter<CompleteSwapState> emit,
  ) async {
    try {
      emit(const CompleteSwapLoading());

      final HtlcSwap swap = event.swap;
      final Hash htlcId = Hash.parse(
        swap.direction == P2pSwapDirection.outgoing
            ? swap.counterHtlcId!
            : swap.initialHtlcId,
      );
      final HtlcInfo htlc = await _zenon.embedded.htlc.getById(htlcId);

      if (htlc.expirationTime <=
          _unixTimeProvider() + kMinSafeTimeToCompleteSwap.inSeconds) {
        throw SyriusException(
          'The swap will expire too soon for a safe swap.',
        );
      }

      final List<int> preimage = FormatUtils.decodeHexString(swap.preimage!);
      if (htlc.keyMaxSize < preimage.length) {
        throw SyriusException(
          'The swap secret size exceeds the maximum allowed size.',
        );
      }

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .unlock(htlcId, preimage);
      final AccountBlockTemplate block = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'complete swap',
            address: Address.parse(swap.selfAddress),
            waitForRequiredPlasma: true,
          );

      final HtlcSwap completedSwap = swap.copyWith(
        state: P2pSwapState.completed,
      );
      await _htlcSwapsService.storeSwap(completedSwap);
      _zenonAddressUtils.refreshBalance();
      emit(CompleteSwapDone(block: block, swap: completedSwap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(CompleteSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(CompleteSwapFailure(exception: FailureException()));
    }
  }
}
