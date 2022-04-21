import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/staking/staking_rewards_history_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/charts/staking_rewards_chart.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingRewards extends StatefulWidget {
  final StakingRewardsHistoryBloc stakingRewardsHistoryBloc;

  const StakingRewards({
    required this.stakingRewardsHistoryBloc,
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _StakingRewardsState();
  }
}

class _StakingRewardsState extends State<StakingRewards> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Staking Rewards',
      description: 'This card displays a chart with your staking rewards from '
          'your staking entries',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: _getStreamBody(),
      ),
    );
  }

  Widget _getStreamBody() {
    return StreamBuilder<RewardHistoryList?>(
      stream: widget.stakingRewardsHistoryBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return StakingRewardsChart(snapshot.data);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }
}
