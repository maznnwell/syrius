import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'recover_swap_funds_event.dart';

part 'recover_swap_funds_state.dart';

/// Recovers the funds from an expired HTLC owned by the wallet.
class RecoverSwapFundsBloc
    extends Bloc<RecoverSwapFundsEvent, RecoverSwapFundsState> {
  /// Creates a [RecoverSwapFundsBloc].
  RecoverSwapFundsBloc({
    required this._accountBlockUtils,
    required this._walletAddresses,
    required this._zenon,
    required this._zenonAddressUtils,
    int Function()? unixTimeProvider,
  }) : _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(const RecoverSwapFundsInitial()) {
    on<RecoverSwapFundsRequested>(_onRecoverSwapFundsRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Set<String> _walletAddresses;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;
  final int Function() _unixTimeProvider;

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  FutureOr<void> _onRecoverSwapFundsRequested(
    RecoverSwapFundsRequested event,
    Emitter<RecoverSwapFundsState> emit,
  ) async {
    try {
      emit(const RecoverSwapFundsLoading());

      final HtlcInfo htlc = await _zenon.embedded.htlc.getById(event.htlcId);

      // TODO(maznnwell): this can trigger bugs: user has 10 addresses,
      // initiates swap from the 10th one, resets his wallet, has generated
      // only 3 addresses, so this check fails
      if (!_walletAddresses.contains(htlc.timeLocked.toString())) {
        throw SyriusException('The deposit does not belong to you.');
      }

      if (htlc.expirationTime - _unixTimeProvider() > 0) {
        final String expirationDate = FormatUtils.formatDate(
          htlc.expirationTime * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        );
        throw SyriusException(
          'The deposit is locked until $expirationDate.',
        );
      }

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .reclaim(event.htlcId);
      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'reclaim swap funds',
        address: htlc.timeLocked,
        waitForRequiredPlasma: true,
      );

      _zenonAddressUtils.refreshBalance();
      emit(const RecoverSwapFundsDone());
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(RecoverSwapFundsFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(RecoverSwapFundsFailure(exception: FailureException()));
    }
  }
}
