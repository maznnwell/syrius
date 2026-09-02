import 'package:znn_sdk_dart/znn_sdk_dart.dart';

extension AccountBlocExtension on AccountBlock {
  int get confirmationTimestampMs =>
      (confirmationDetail?.momentumTimestamp ?? 0) * 1000;
}
