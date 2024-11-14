import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_deposit_qsr_cubit.g.dart';

part 'sentinel_deposit_qsr_state.dart';

/// A cubit that handles the depositing of QSR for Sentinel slots.
class SentinelsDepositQsrCubit extends HydratedCubit<SentinelsDepositQsrState> {
  /// Creates a new instance of [SentinelsDepositQsrCubit].
  SentinelsDepositQsrCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  :accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const SentinelsDepositQsrState());


  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to deposit QSR for a Sentinel slot.
  Future<void> depositQsr(
    BigInt amount, {
    bool justMarkStepCompleted = false,
  }) async {
    // Emit loading state
    emit(state.copyWith(status: SentinelsDepositQsrStatus.loading));
    try {
      if (!justMarkStepCompleted) {
        // Create the transaction parameters for depositing QSR
        final AccountBlockTemplate transactionParams =
            zenon.embedded.sentinel.depositQsr(amount);

        // Create the account block and wait for the required plasma, optionally
        final AccountBlockTemplate response =
            await accountBlockUtilsHelper.createAccountBlock(
          transactionParams,
          'deposit ${kQsrCoin.symbol} for Sentinel Slot',
          waitForRequiredPlasma: true,
        );

        // Wait for a delay after account block creation
        await Future.delayed(duration);

        // Refresh the balance after the operation
        await zenonAddressUtilsHelper.refreshBalance();

        // Emit success state with the response data
        emit(
          state.copyWith(
            status: SentinelsDepositQsrStatus.success,
            data: response,
          ),
        );
      } else {
        // If just marking step completed, emit success without action
        emit(state.copyWith(status: SentinelsDepositQsrStatus.success));
      }
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: SentinelsDepositQsrStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [SentinelsDepositQsrState].
  @override
  SentinelsDepositQsrState? fromJson(Map<String, dynamic> json) =>
      SentinelsDepositQsrState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(SentinelsDepositQsrState state) => state.toJson();
}
