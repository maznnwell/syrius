import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc_for_reloading_indicator.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelUncollectedRewardsBloc
    extends BaseBlocForReloadingIndicator<UncollectedReward> {
  @override
  Future<UncollectedReward> getDataAsync() =>
      zenon!.embedded.sentinel.getUncollectedReward(
        Address.parse(kSelectedAddress!),
      );
}
