import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_withdraw_qsr_cubit.g.dart';

part 'sentinel_withdraw_qsr_state.dart';

/// A cubit that handles the withdrawal of QSR from a Sentinel slot.
class SentinelsWithdrawQsrCubit
    extends HydratedCubit<SentinelsWithdrawQsrState> {
  /// Creates a new instance of [SentinelsWithdrawQsrCubit].
  SentinelsWithdrawQsrCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const SentinelsWithdrawQsrState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class for account block utils, facilitates dependency injection.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class for address utilities, facilitates dependency injection.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to withdraw QSR from a Sentinel slot.
  Future<void> withdrawQsr() async {
    // Emit loading state
    emit(state.copyWith(status: SentinelsWithdrawQsrStatus.loading));
    try {
      // Create the transaction parameters for withdrawing QSR
      final AccountBlockTemplate transactionParams =
          zenon.embedded.sentinel.withdrawQsr();

      // Create the account block and wait for the required plasma if necessary
      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Sentinel Slot',
        waitForRequiredPlasma: true,
      );

      // Wait for a delay after account block creation
      await Future.delayed(duration);

      // Refresh the balance after the operation
      await zenonAddressUtilsHelper.refreshBalance();

      // Emit success state with the response data
      emit(
        state.copyWith(
          status: SentinelsWithdrawQsrStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: SentinelsWithdrawQsrStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [SentinelsWithdrawQsrState].
  @override
  SentinelsWithdrawQsrState? fromJson(Map<String, dynamic> json) =>
      SentinelsWithdrawQsrState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(SentinelsWithdrawQsrState state) =>
      state.toJson();
}
