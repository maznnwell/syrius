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

class SentinelCollect extends StatefulWidget {

  const SentinelCollect({
    required this.sentinelRewardsHistoryBloc,
    super.key,
  });
  final SentinelRewardsHistoryBloc sentinelRewardsHistoryBloc;

  @override
  State<SentinelCollect> createState() => _SentinelCollectState();
}

class _SentinelCollectState extends State<SentinelCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final SentinelUncollectedRewardsBloc _sentinelCollectRewardsBloc =
      SentinelUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.sentinelCollectTitle,
      description: context.l10n.sentinelCollectDescription,
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _sentinelCollectRewardsBloc.stream,
      builder: (_, AsyncSnapshot<UncollectedReward?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.znnAmount > BigInt.zero ||
              snapshot.data!.qsrAmount > BigInt.zero) {
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
          end: uncollectedReward.znnAmount.addDecimals(coinDecimals).toNum(),
          after: ' ${kZnnCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.znnColor,
                fontSize: 30,
              ),
        ),
        kVerticalSpacing,
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
          visible: uncollectedReward.qsrAmount > BigInt.zero ||
              uncollectedReward.znnAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: context.l10n.collect,
            onPressed: uncollectedReward.qsrAmount > BigInt.zero ||
                    uncollectedReward.znnAmount > BigInt.zero
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
        zenon!.embedded.sentinel.collectReward(),
        'collect Sentinel rewards',
        waitForRequiredPlasma: true,
      ).then(
        (AccountBlockTemplate response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _sentinelCollectRewardsBloc.updateStream();
          }
          widget.sentinelRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        context.l10n.errorCollectingSentinelRewards,
      );
    } finally {
      _collectButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _sentinelCollectRewardsBloc.dispose();
    super.dispose();
  }
}
