import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_rewards_history_cubit.g.dart';

part 'sentinel_rewards_history_state.dart';

/// A cubit that manages the state of reward history for a specific sentinel
/// address.
class SentinelRewardsHistoryCubit extends CubitForReloadingIndicator<
    RewardHistoryList, SentinelRewardsHistoryState> {
  /// Constructs a [SentinelRewardsHistoryCubit].
  ///
  /// The parameters are a [Zenon] instance,
  /// the target [address] for which reward history data is fetched,
  /// an optional [pageSize] to control the number of entries retrieved,
  /// and an optional flag [callUpdateStream] to control
  /// whether data is fetched on initialization.
  SentinelRewardsHistoryCubit({
    required super.zenon,
    required this.address,
    this.pageSize = kStandardChartNumDays,
    bool callUpdateStream = true,
  }) : super(
          callUpdateStream: callUpdateStream,
          const SentinelRewardsHistoryState(),
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
          await zenon.embedded.sentinel.getFrontierRewardByPage(
        address,
        pageSize: pageSize.toInt(),
      );
      if (response.list.any(
        (RewardHistoryEntry element) =>
            element.qsrAmount > BigInt.zero || element.znnAmount > BigInt.zero,
      )) {
        return response;
      } else {
        throw NoRewardsLastWeekException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [SentinelRewardsHistoryState].
  @override
  SentinelRewardsHistoryState? fromJson(Map<String, dynamic> json) =>
      SentinelRewardsHistoryState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(SentinelRewardsHistoryState state) =>
      state.toJson();
}
