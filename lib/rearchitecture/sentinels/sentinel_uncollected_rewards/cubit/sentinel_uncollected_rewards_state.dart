part of 'sentinel_uncollected_rewards_cubit.dart';

/// The state representation of [SentinelUncollectedRewardsCubit].
@JsonSerializable(explicitToJson: true)
class SentinelUncollectedRewardsState
    extends IndicatorState<UncollectedReward> {
  /// Creates a new instance of [SentinelUncollectedRewardsState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const SentinelUncollectedRewardsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a new instance from a JSON object.
  factory SentinelUncollectedRewardsState.fromJson(Map<String, dynamic> json) =>
      _$SentinelUncollectedRewardsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<UncollectedReward> copyWith({
    IndicatorStatus? status,
    UncollectedReward? data,
    SyriusException? error,
  }) {
    return SentinelUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() =>
      _$SentinelUncollectedRewardsStateToJson(this);
}
