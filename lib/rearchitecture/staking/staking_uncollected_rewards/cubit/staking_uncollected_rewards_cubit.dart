import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_uncollected_rewards_cubit.g.dart';
part 'staking_uncollected_rewards_state.dart';

/// A cubit responsible for fetching and managing the state of
/// uncollected rewards for a specific staking address.
class StakingUncollectedRewardsCubit extends CubitForReloadingIndicator<
    UncollectedReward, StakingUncollectedRewardsState> {
  /// Constructs a [StakingUncollectedRewardsCubit].
  ///
  /// The parameters are a [Zenon] instance,
  /// the target [address] to retrieve uncollected rewards,
  /// and an optional flag [callUpdateStream] to control
  /// whether data is fetched on initialization.
  StakingUncollectedRewardsCubit({
    required super.zenon,
    required this.address,
    bool callUpdateStream = true,
  }) : super(
    callUpdateStream: callUpdateStream,
    const StakingUncollectedRewardsState(),
  );

  /// The [address] for which the cubit fetches and manages uncollected rewards.
  final Address address;

  /// Fetches the uncollected rewards for the specified [address].
  @override
  Future<UncollectedReward> getData() async {
    try {
      final UncollectedReward response =
      await zenon.embedded.stake.getUncollectedReward(address);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [StakingUncollectedRewardsState] instance.
  @override
  StakingUncollectedRewardsState? fromJson(Map<String, dynamic> json) =>
      StakingUncollectedRewardsState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(StakingUncollectedRewardsState state) =>
      state.toJson();
}
