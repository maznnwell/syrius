// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinel_withdraw_qsr_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelsWithdrawQsrState _$SentinelsWithdrawQsrStateFromJson(
        Map<String, dynamic> json) =>
    SentinelsWithdrawQsrState(
      status: $enumDecodeNullable(
              _$SentinelsWithdrawQsrStatusEnumMap, json['status']) ??
          SentinelsWithdrawQsrStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentinelsWithdrawQsrStateToJson(
        SentinelsWithdrawQsrState instance) =>
    <String, dynamic>{
      'status': _$SentinelsWithdrawQsrStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$SentinelsWithdrawQsrStatusEnumMap = {
  SentinelsWithdrawQsrStatus.initial: 'initial',
  SentinelsWithdrawQsrStatus.loading: 'loading',
  SentinelsWithdrawQsrStatus.success: 'success',
  SentinelsWithdrawQsrStatus.failure: 'failure',
};
