part of 'staking_uncollected_rewards_cubit.dart';

/// The state representation of [StakingUncollectedRewardsCubit].
@JsonSerializable(explicitToJson: true)
class StakingUncollectedRewardsState
    extends IndicatorState<UncollectedReward> {
  /// Creates a new instance of [StakingUncollectedRewardsState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const StakingUncollectedRewardsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory StakingUncollectedRewardsState.fromJson(Map<String, dynamic> json) =>
      _$StakingUncollectedRewardsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<UncollectedReward> copyWith({
    IndicatorStatus? status,
    UncollectedReward? data,
    SyriusException? error,
  }) {
    return StakingUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() =>
      _$StakingUncollectedRewardsStateToJson(this);
}
