// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disassemble_sentinel_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisassembleSentinelState _$DisassembleSentinelStateFromJson(
        Map<String, dynamic> json) =>
    DisassembleSentinelState(
      status: $enumDecodeNullable(
              _$DisassembleSentinelStatusEnumMap, json['status']) ??
          DisassembleSentinelStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$DisassembleSentinelStateToJson(
        DisassembleSentinelState instance) =>
    <String, dynamic>{
      'status': _$DisassembleSentinelStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$DisassembleSentinelStatusEnumMap = {
  DisassembleSentinelStatus.initial: 'initial',
  DisassembleSentinelStatus.loading: 'loading',
  DisassembleSentinelStatus.success: 'success',
  DisassembleSentinelStatus.failure: 'failure',
};
