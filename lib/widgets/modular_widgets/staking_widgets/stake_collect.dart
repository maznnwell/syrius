import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakeCollect extends StatefulWidget {

  const StakeCollect({
    required this.stakingRewardsHistoryBloc,
    super.key,
  });
  final StakingRewardsHistoryBloc stakingRewardsHistoryBloc;

  @override
  State<StakeCollect> createState() => _StakeCollectState();
}

class _StakeCollectState extends State<StakeCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final StakingUncollectedRewardsBloc _stakingUncollectedRewardsBloc =
      StakingUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.stakeCollectTitle,
      description: context.l10n.stakeCollectDescription,
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _stakingUncollectedRewardsBloc.stream,
      builder: (_, AsyncSnapshot<UncollectedReward?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.qsrAmount > BigInt.zero) {
            return _getWidgetBody(snapshot.data!);
          }
          return SyriusErrorWidget(context.l10n.noRewardsCollect);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(UncollectedReward uncollectedReward) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NumberAnimation(
          end: uncollectedReward.qsrAmount.addDecimals(coinDecimals).toNum(),
          after: ' ${kQsrCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.qsrColor,
                fontSize: 30,
              ),
        ),
        kVerticalSpacing,
        Visibility(
          visible: uncollectedReward.qsrAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: context.l10n.collect,
            outlineColor: AppColors.qsrColor,
            onPressed: uncollectedReward.qsrAmount > BigInt.zero
                ? _onCollectPressed
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _onCollectPressed() async {
    try {
      _collectButtonKey.currentState?.animateForward();
      await AccountBlockUtils.createAccountBlock(
        zenon!.embedded.stake.collectReward(),
        'collect staking rewards',
        waitForRequiredPlasma: true,
      ).then(
        (AccountBlockTemplate response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _stakingUncollectedRewardsBloc.updateStream();
          }
          widget.stakingRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        context.l10n.errorCollectingStakingRewards,
      );
    } finally {
      _collectButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _stakingUncollectedRewardsBloc.dispose();
    super.dispose();
  }
}
