part of 'get_sentinel_by_owner_cubit.dart';

/// The state representation of [GetSentinelByOwnerCubit].
@JsonSerializable(explicitToJson: true)
class GetSentinelByOwnerState extends IndicatorState<SentinelInfo?> {
  /// Creates a new instance of [GetSentinelByOwnerState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const GetSentinelByOwnerState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory GetSentinelByOwnerState.fromJson(Map<String, dynamic> json) =>
      _$GetSentinelByOwnerStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<SentinelInfo?> copyWith({
    IndicatorStatus? status,
    SentinelInfo? data,
    SyriusException? error,
  }) {
    return GetSentinelByOwnerState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$GetSentinelByOwnerStateToJson(this);

}
