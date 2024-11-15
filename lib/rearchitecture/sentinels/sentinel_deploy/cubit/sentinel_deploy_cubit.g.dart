// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinel_deploy_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelsDeployState _$SentinelsDeployStateFromJson(
        Map<String, dynamic> json) =>
    SentinelsDeployState(
      status:
          $enumDecodeNullable(_$SentinelsDeployStatusEnumMap, json['status']) ??
              SentinelsDeployStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentinelsDeployStateToJson(
        SentinelsDeployState instance) =>
    <String, dynamic>{
      'status': _$SentinelsDeployStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$SentinelsDeployStatusEnumMap = {
  SentinelsDeployStatus.initial: 'initial',
  SentinelsDeployStatus.loading: 'loading',
  SentinelsDeployStatus.success: 'success',
  SentinelsDeployStatus.failure: 'failure',
};
