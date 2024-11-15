// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinel_deposit_qsr_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelsDepositQsrState _$SentinelsDepositQsrStateFromJson(
        Map<String, dynamic> json) =>
    SentinelsDepositQsrState(
      status: $enumDecodeNullable(
              _$SentinelsDepositQsrStatusEnumMap, json['status']) ??
          SentinelsDepositQsrStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentinelsDepositQsrStateToJson(
        SentinelsDepositQsrState instance) =>
    <String, dynamic>{
      'status': _$SentinelsDepositQsrStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$SentinelsDepositQsrStatusEnumMap = {
  SentinelsDepositQsrStatus.initial: 'initial',
  SentinelsDepositQsrStatus.loading: 'loading',
  SentinelsDepositQsrStatus.success: 'success',
  SentinelsDepositQsrStatus.failure: 'failure',
};
