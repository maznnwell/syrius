part of 'sentinel_rewards_history_cubit.dart';

/// The state representation of [SentinelRewardsHistoryCubit].
@JsonSerializable(explicitToJson: true)
class SentinelRewardsHistoryState extends IndicatorState<RewardHistoryList> {
  /// Creates a new instance of [SentinelRewardsHistoryState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const SentinelRewardsHistoryState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a new instance from a JSON object.
  factory SentinelRewardsHistoryState.fromJson(Map<String, dynamic> json) =>
      _$SentinelRewardsHistoryStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<RewardHistoryList> copyWith({
    IndicatorStatus? status,
    RewardHistoryList? data,
    SyriusException? error,
  }) {
    return SentinelRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SentinelRewardsHistoryStateToJson(this);

}
