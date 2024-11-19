// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinel_uncollected_rewards_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelUncollectedRewardsState _$SentinelUncollectedRewardsStateFromJson(
        Map<String, dynamic> json) =>
    SentinelUncollectedRewardsState(
      status: $enumDecodeNullable(_$IndicatorStatusEnumMap, json['status']) ??
          IndicatorStatus.initial,
      data: json['data'] == null
          ? null
          : UncollectedReward.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SentinelUncollectedRewardsStateToJson(
        SentinelUncollectedRewardsState instance) =>
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
