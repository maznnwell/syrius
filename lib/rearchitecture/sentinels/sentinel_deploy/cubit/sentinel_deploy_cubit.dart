import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_deploy_cubit.g.dart';

part 'sentinel_deploy_state.dart';

/// A cubit that handles the deployment (registration) of a Sentinel.
class SentinelsDeployCubit extends HydratedCubit<SentinelsDeployState> {
  /// Creates a new instance of [SentinelsDeployCubit].
  SentinelsDeployCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const SentinelsDeployState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class for account block utils, facilitates dependency injection.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class for address utilities, facilitates dependency injection.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to deploy (register) a Sentinel.
  Future<void> deploySentinel() async {
    // Emit loading state
    emit(state.copyWith(status: SentinelsDeployStatus.loading));
    try {
      // Create the transaction parameters for registering the Sentinel
      final AccountBlockTemplate transactionParams =
          zenon.embedded.sentinel.register();

      // Create the account block and wait for the required plasma if necessary
      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'register Sentinel',
        waitForRequiredPlasma: true,
      );

      // Refresh the balance after the operation
      await zenonAddressUtilsHelper.refreshBalance();

      // Emit success state with the response data
      emit(
        state.copyWith(
          status: SentinelsDeployStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: SentinelsDeployStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [SentinelsDeployState].
  @override
  SentinelsDeployState? fromJson(Map<String, dynamic> json) =>
      SentinelsDeployState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(SentinelsDeployState state) => state.toJson();
}
