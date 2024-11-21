// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staking_rewards_history_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingRewardsHistoryState _$StakingRewardsHistoryStateFromJson(
        Map<String, dynamic> json) =>
    StakingRewardsHistoryState(
      status: $enumDecodeNullable(_$IndicatorStatusEnumMap, json['status']) ??
          IndicatorStatus.initial,
      data: json['data'] == null
          ? null
          : RewardHistoryList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StakingRewardsHistoryStateToJson(
        StakingRewardsHistoryState instance) =>
    <String, dynamic>{
      'status': _$IndicatorStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$IndicatorStatusEnumMap = {
  IndicatorStatus.failure: 'failure',
  IndicatorStatus.initial: 'initial',
  IndicatorStatus.loading: 'loading',
  IndicatorStatus.success: 'success',
};
