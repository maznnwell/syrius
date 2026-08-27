import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Adds swap-specific formatting to [HtlcInfo].
extension HtlcInfoExtension on HtlcInfo {
  /// The hash lock encoded as a hexadecimal string.
  String get hashLockHex => FormatUtils.encodeHexString(hashLock);
}
