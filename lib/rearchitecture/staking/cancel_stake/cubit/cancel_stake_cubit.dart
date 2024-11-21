import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'cancel_stake_cubit.g.dart';
part 'cancel_stake_state.dart';

/// A cubit that handles the cancellation of a stake.
class CancelStakeCubit extends HydratedCubit<CancelStakeState> {
  /// Creates a new instance of [CancelStakeCubit].
  CancelStakeCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : accountBlockUtilsHelper =
      accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const CancelStakeState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class for account block utils, facilitates dependency injection.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class for address utilities, facilitates dependency injection.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to cancel a stake.
  Future<void> cancelStake(String hash, BuildContext context) async {

    // Emit loading state before any data fetching
    emit(state.copyWith(status: CancelStakeStatus.loading));
    try {
      // Create the transaction parameters for cancelling the stake
      final AccountBlockTemplate transactionParams =
      zenon.embedded.stake.cancel(Hash.parse(hash));

      // Create the account block and wait for the required plasma if necessary
      final AccountBlockTemplate response =
      await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'cancel stake',
        waitForRequiredPlasma: true,
      );

      // Refresh the balance after the operation
      await zenonAddressUtilsHelper.refreshBalance();

      // Emit success state with the response data
      emit(
        state.copyWith(
          status: CancelStakeStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: CancelStakeStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [CancelStakeState].
  @override
  CancelStakeState? fromJson(Map<String, dynamic> json) =>
      CancelStakeState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(CancelStakeState state) => state.toJson();
}
