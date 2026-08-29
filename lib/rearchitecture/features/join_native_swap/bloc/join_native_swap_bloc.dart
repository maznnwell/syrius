import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'join_native_swap_event.dart';

part 'join_native_swap_state.dart';

/// A bloc that creates and stores an incoming HTLC swap.
class JoinNativeSwapBloc
    extends Bloc<JoinNativeSwapEvent, JoinNativeSwapState> {
  /// Creates a [JoinNativeSwapBloc].
  JoinNativeSwapBloc({
    required this._accountBlockUtils,
    required this._htlcSwapsService,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const JoinNativeSwapInitial()) {
    on<JoinNativeSwapRequested>(_onJoinNativeSwapRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final HtlcSwapsService _htlcSwapsService;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onJoinNativeSwapRequested(
    JoinNativeSwapRequested event,
    Emitter<JoinNativeSwapState> emit,
  ) async {
    try {
      emit(const JoinNativeSwapLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .create(
            event.fromToken,
            event.fromAmount,
            event.initialHtlc.timeLocked,
            event.counterHtlcExpirationTime,
            event.initialHtlc.hashType,
            event.initialHtlc.keyMaxSize,
            event.initialHtlc.hashLock,
          );
      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'join swap',
            address: event.initialHtlc.hashLocked,
            waitForRequiredPlasma: true,
          );
      final HtlcSwap swap = HtlcSwap(
        id: event.initialHtlc.id.toString(),
        chainId: response.chainIdentifier,
        type: event.swapType,
        direction: P2pSwapDirection.incoming,
        selfAddress: event.initialHtlc.hashLocked.toString(),
        counterHtlcId: response.hash.toString(),
        counterHtlcExpirationTime: event.counterHtlcExpirationTime,
        counterpartyAddress: event.initialHtlc.timeLocked.toString(),
        state: P2pSwapState.active,
        startTime: DateTimeUtils.unixTimeNow,
        initialHtlcId: event.initialHtlc.id.toString(),
        initialHtlcExpirationTime: event.initialHtlc.expirationTime,
        fromAmount: event.fromAmount,
        fromTokenStandard: event.fromToken.tokenStandard.toString(),
        fromDecimals: event.fromToken.decimals,
        fromSymbol: event.fromToken.symbol,
        fromChain: event.fromChain,
        toAmount: event.initialHtlc.amount,
        toTokenStandard: event.toToken.tokenStandard.toString(),
        toDecimals: event.toToken.decimals,
        toSymbol: event.toToken.symbol,
        toChain: event.toChain,
        hashLock: FormatUtils.encodeHexString(event.initialHtlc.hashLock),
        hashType: event.initialHtlc.hashType,
      );

      await _htlcSwapsService.storeSwap(swap);
      _zenonAddressUtils.refreshBalance();
      emit(JoinNativeSwapDone(swap: swap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(JoinNativeSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(JoinNativeSwapFailure(exception: FailureException()));
    }
  }
}
