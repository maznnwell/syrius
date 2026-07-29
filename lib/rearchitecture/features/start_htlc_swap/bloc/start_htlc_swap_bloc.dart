import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'start_htlc_swap_event.dart';

part 'start_htlc_swap_state.dart';

/// A bloc that creates and stores an outgoing HTLC swap.
class StartHtlcSwapBloc extends Bloc<StartHtlcSwapEvent, StartHtlcSwapState> {
  /// Creates a [StartHtlcSwapBloc].
  StartHtlcSwapBloc({
    required this._accountBlockUtils,
    required this._htlcSwapsService,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const StartHtlcSwapInitial()) {
    on<StartHtlcSwapRequested>(_onStartHtlcSwapRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final HtlcSwapsService _htlcSwapsService;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onStartHtlcSwapRequested(
    StartHtlcSwapRequested event,
    Emitter<StartHtlcSwapState> emit,
  ) async {
    try {
      emit(const StartHtlcSwapLoading());

      final List<int> preimage = _generatePreimage();
      final Hash hashLock = await _getHashLock(event.hashType, preimage);
      final int expirationTime = await _getExpirationTime(
        event.initialHtlcDuration,
      );
      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .create(
            event.fromToken,
            event.fromAmount,
            event.counterpartyAddress,
            expirationTime,
            event.hashType,
            htlcPreimageMaxLength,
            hashLock.getBytes(),
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'start swap',
            address: event.selfAddress,
            waitForRequiredPlasma: true,
          );

      final HtlcSwap swap = HtlcSwap(
        id: response.hash.toString(),
        chainId: response.chainIdentifier,
        type: event.swapType,
        direction: P2pSwapDirection.outgoing,
        selfAddress: event.selfAddress.toString(),
        counterpartyAddress: event.counterpartyAddress.toString(),
        state: P2pSwapState.pending,
        startTime: DateTimeUtils.unixTimeNow,
        initialHtlcId: response.hash.toString(),
        initialHtlcExpirationTime: expirationTime,
        fromAmount: event.fromAmount,
        fromTokenStandard: event.fromToken.tokenStandard.toString(),
        fromDecimals: event.fromToken.decimals,
        fromSymbol: event.fromToken.symbol,
        fromChain: event.fromChain,
        toChain: event.toChain,
        hashLock: hashLock.toString(),
        preimage: FormatUtils.encodeHexString(preimage),
        hashType: event.hashType,
      );

      await _htlcSwapsService.storeSwap(swap);
      _zenonAddressUtils.refreshBalance();
      emit(StartHtlcSwapDone(swap: swap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(StartHtlcSwapFailure(exception: error));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(StartHtlcSwapFailure(exception: FailureException()));
    }
  }

  List<int> _generatePreimage() {
    const int maxInt = 256;
    final Random random = Random.secure();

    return List<int>.generate(
      htlcPreimageDefaultLength,
      (_) => random.nextInt(maxInt),
    );
  }

  Future<Hash> _getHashLock(int hashType, List<int> preimage) async {
    if (hashType == htlcHashTypeSha3) {
      return Hash.digest(preimage);
    } else if (hashType == htlcHashTypeSha256) {
      return Hash.fromBytes(await Crypto.sha256Bytes(preimage));
    }
    throw UnimplementedError('Hash type not implemented');
  }

  Future<int> _getExpirationTime(int duration) async {
    return (await _zenon.ledger.getFrontierMomentum()).timestamp + duration;
  }
}
