import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_rewards_history_cubit.g.dart';
part 'staking_rewards_history_state.dart';

/// A cubit that manages the state of reward history for a specific staking
/// address.
class StakingRewardsHistoryCubit extends CubitForReloadingIndicator<
    RewardHistoryList, StakingRewardsHistoryState> {

  /// Constructs a [StakingRewardsHistoryCubit].
  ///
  /// The parameters are a [Zenon] instance,
  /// the target [address] for which reward history data is fetched,
  /// an optional [pageSize] to control the number of entries retrieved,
  /// and an optional flag [callUpdateStream] to control
  /// whether data is fetched on initialization.
  StakingRewardsHistoryCubit({
    required super.zenon,
    required this.address,
    this.pageSize = kStandardChartNumDays,
    bool callUpdateStream = true,
  }) : super(
    callUpdateStream: callUpdateStream,
    const StakingRewardsHistoryState(),
  );

  /// The [address] for which the cubit fetches and manages reward history data.
  final Address address;

  /// The number of reward history entries to request per page.
  final double pageSize;

  /// Fetches the reward history data for the specified [address]
  /// with the defined [pageSize].
  @override
  Future<RewardHistoryList> getData() async {
    try {
      final RewardHistoryList response =
      await zenon.embedded.stake.getFrontierRewardByPage(
        address,
        pageSize: pageSize.toInt(),
      );
      if (response.list.any(
            (RewardHistoryEntry element) => element.qsrAmount > BigInt.zero,
      )) {
        return response;
      } else {
        throw NoRewardsLastWeekException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [StakingRewardsHistoryState].
  @override
  StakingRewardsHistoryState? fromJson(Map<String, dynamic> json) =>
      StakingRewardsHistoryState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(StakingRewardsHistoryState state) =>
      state.toJson();
}
