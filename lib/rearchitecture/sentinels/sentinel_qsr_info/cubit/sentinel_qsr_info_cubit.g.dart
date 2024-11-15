// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinel_qsr_info_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelsQsrInfoState _$SentinelsQsrInfoStateFromJson(
        Map<String, dynamic> json) =>
    SentinelsQsrInfoState(
      status: $enumDecodeNullable(
              _$SentinelsQsrInfoStatusEnumMap, json['status']) ??
          SentinelsQsrInfoStatus.initial,
      data: json['data'] == null
          ? null
          : SentinelsQsrInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentinelsQsrInfoStateToJson(
        SentinelsQsrInfoState instance) =>
    <String, dynamic>{
      'status': _$SentinelsQsrInfoStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$SentinelsQsrInfoStatusEnumMap = {
  SentinelsQsrInfoStatus.initial: 'initial',
  SentinelsQsrInfoStatus.loading: 'loading',
  SentinelsQsrInfoStatus.success: 'success',
  SentinelsQsrInfoStatus.failure: 'failure',
};
