// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_stake_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancelStakeState _$CancelStakeStateFromJson(Map<String, dynamic> json) =>
    CancelStakeState(
      status: $enumDecodeNullable(_$CancelStakeStatusEnumMap, json['status']) ??
          CancelStakeStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$CancelStakeStateToJson(CancelStakeState instance) =>
    <String, dynamic>{
      'status': _$CancelStakeStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$CancelStakeStatusEnumMap = {
  CancelStakeStatus.initial: 'initial',
  CancelStakeStatus.loading: 'loading',
  CancelStakeStatus.success: 'success',
  CancelStakeStatus.failure: 'failure',
};
