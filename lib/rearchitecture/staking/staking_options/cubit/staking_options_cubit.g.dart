// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staking_options_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingOptionsState _$StakingOptionsStateFromJson(Map<String, dynamic> json) =>
    StakingOptionsState(
      status:
          $enumDecodeNullable(_$StakingOptionsStatusEnumMap, json['status']) ??
              StakingOptionsStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$StakingOptionsStateToJson(
        StakingOptionsState instance) =>
    <String, dynamic>{
      'status': _$StakingOptionsStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$StakingOptionsStatusEnumMap = {
  StakingOptionsStatus.initial: 'initial',
  StakingOptionsStatus.loading: 'loading',
  StakingOptionsStatus.success: 'success',
  StakingOptionsStatus.failure: 'failure',
};
