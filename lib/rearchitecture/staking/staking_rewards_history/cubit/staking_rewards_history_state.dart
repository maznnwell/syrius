part of 'staking_rewards_history_cubit.dart';

/// The state representation of [StakingRewardsHistoryCubit].
@JsonSerializable(explicitToJson: true)
class StakingRewardsHistoryState extends IndicatorState<RewardHistoryList> {
  /// Creates a new instance of [StakingRewardsHistoryState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const StakingRewardsHistoryState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory StakingRewardsHistoryState.fromJson(Map<String, dynamic> json) =>
      _$StakingRewardsHistoryStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<RewardHistoryList> copyWith({
    IndicatorStatus? status,
    RewardHistoryList? data,
    SyriusException? error,
  }) {
    return StakingRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$StakingRewardsHistoryStateToJson(this);

}
