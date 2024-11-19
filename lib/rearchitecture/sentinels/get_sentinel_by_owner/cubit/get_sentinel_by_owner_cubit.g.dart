// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_sentinel_by_owner_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSentinelByOwnerState _$GetSentinelByOwnerStateFromJson(
        Map<String, dynamic> json) =>
    GetSentinelByOwnerState(
      status: $enumDecodeNullable(_$IndicatorStatusEnumMap, json['status']) ??
          IndicatorStatus.initial,
      data: json['data'] == null
          ? null
          : SentinelInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetSentinelByOwnerStateToJson(
        GetSentinelByOwnerState instance) =>
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
