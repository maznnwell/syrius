import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'disassemble_sentinel_cubit.g.dart';

part 'disassemble_sentinel_state.dart';

/// A cubit that handles the disassembling of a Sentinel.
class DisassembleSentinelCubit extends HydratedCubit<DisassembleSentinelState> {
  /// Creates a new instance of [DisassembleSentinelCubit].
  DisassembleSentinelCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const DisassembleSentinelState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to disassemble a Sentinel.
  Future<void> disassembleSentinel(BuildContext context) async {
    // Emit loading state
    emit(state.copyWith(status: DisassembleSentinelStatus.loading));
    try {
      // Create the transaction parameters for revoking the Sentinel
      final AccountBlockTemplate transactionParams =
          zenon.embedded.sentinel.revoke();

      // Create the account block and wait for the required plasma if necessary
      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'disassemble Sentinel',
        waitForRequiredPlasma: true,
      );

      // Refresh the balance after the operation
      await zenonAddressUtilsHelper.refreshBalance();

      // Emit success state with the response data
      emit(state.copyWith(
        status: DisassembleSentinelStatus.success,
        data: response,
      ),);
    } catch (e) {
      // Emit failure state with the error information
      emit(state.copyWith(
        status: DisassembleSentinelStatus.failure,
        error: e,
      ),);
    }
  }

  /// Deserializes the JSON map into a [DisassembleSentinelState].
  @override
  DisassembleSentinelState? fromJson(Map<String, dynamic> json) =>
      DisassembleSentinelState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(DisassembleSentinelState state) =>
      state.toJson();
}
