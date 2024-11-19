import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'get_sentinel_by_owner_cubit.g.dart';

part 'get_sentinel_by_owner_state.dart';

/// A cubit responsible for fetching and managing the state
/// of sentinels owned by a specific address.
class GetSentinelByOwnerCubit
    extends CubitWithRefreshMixin<SentinelInfo?, GetSentinelByOwnerState> {
  /// Constructs a [GetSentinelByOwnerCubit] with a [zenon] instance and the
  /// [address] for which sentinel data is to be retrieved.
  GetSentinelByOwnerCubit({
    required super.zenon,
    required this.address,
    bool callUpdateStream = true,
  }) : super(
          callUpdateStream: callUpdateStream,
          const GetSentinelByOwnerState(),
        );

  /// The [Address] for which the cubit fetches and manages sentinel data.
  final Address address;

  /// Overrides [getData] method to define how data is fetched for the cubit.
  @override
  Future<SentinelInfo?> getData() async {
    try {
      final SentinelInfo? response = await zenon.embedded.sentinel.getByOwner(
        address,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [GetSentinelByOwnerState].
  @override
  GetSentinelByOwnerState? fromJson(Map<String, dynamic> json) =>
      GetSentinelByOwnerState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(GetSentinelByOwnerState state) => state.toJson();
}
