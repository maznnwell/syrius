import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/model/sentinels_qsr_info.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_qsr_info_cubit.g.dart';

part 'sentinel_qsr_info_state.dart';

/// A cubit that handles fetching QSR management information for Sentinels.
class SentinelsQsrInfoCubit extends HydratedCubit<SentinelsQsrInfoState> {
  /// Creates a new instance of [SentinelsQsrInfoCubit].
  SentinelsQsrInfoCubit({
    required this.zenon,
  }) : super(const SentinelsQsrInfoState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Fetches the QSR management information for the given [address].
  Future<void> getQsrManagementInfo(String address) async {
    // Emit loading state
    emit(state.copyWith(status: SentinelsQsrInfoStatus.loading));
    try {
      // Fetch the deposited QSR for the Sentinel
      final BigInt deposit = await zenon.embedded.sentinel.getDepositedQsr(
        Address.parse(address),
      );

      // Get the required QSR amount for registering a Sentinel
      final BigInt cost = sentinelRegisterQsrAmount;

      // Create the SentinelsQsrInfo data
      final SentinelsQsrInfo qsrInfo = SentinelsQsrInfo(
        deposit: deposit,
        cost: cost,
      );

      // Emit success state with the data
      emit(
        state.copyWith(
          status: SentinelsQsrInfoStatus.success,
          data: qsrInfo,
        ),
      );
    } catch (e) {
      // Emit failure state with the error information
      emit(
        state.copyWith(
          status: SentinelsQsrInfoStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [SentinelsQsrInfoState].
  @override
  SentinelsQsrInfoState? fromJson(Map<String, dynamic> json) =>
      SentinelsQsrInfoState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(SentinelsQsrInfoState state) => state.toJson();
}
