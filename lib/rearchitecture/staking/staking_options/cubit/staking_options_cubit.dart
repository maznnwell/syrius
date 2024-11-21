import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_options_cubit.g.dart';
part 'staking_options_state.dart';

/// A cubit that handles staking ZNN for QSR rewards.
class StakingOptionsCubit extends HydratedCubit<StakingOptionsState> {
  /// Creates a new instance of [StakingOptionsCubit].
  StakingOptionsCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : accountBlockUtilsHelper =
      accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const StakingOptionsState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class for account block utils, facilitates dependency injection.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class for address utilities, facilitates dependency injection.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the process to stake ZNN for QSR rewards.
  Future<void> stakeForQsr(
      Duration stakeDuration,
      BigInt amount,
      ) async {

    // Emit loading state before any data fetching
    emit(state.copyWith(status: StakingOptionsStatus.loading));
    try {
      // Create the transaction parameters for staking
      final AccountBlockTemplate transactionParams = zenon.embedded.stake.stake(
        stakeDuration.inSeconds,
        amount,
      );

      // Create the account block and wait for the required plasma if necessary
      final AccountBlockTemplate response =
      await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'create stake',
        waitForRequiredPlasma: true,
      );

      // Refresh the balance after the operation
      await zenonAddressUtilsHelper.refreshBalance();

      // Emit success state with the response data
      emit(
        state.copyWith(
          status: StakingOptionsStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: StakingOptionsStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [StakingOptionsState].
  @override
  StakingOptionsState? fromJson(Map<String, dynamic> json) =>
      StakingOptionsState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(StakingOptionsState state) => state.toJson();
}
