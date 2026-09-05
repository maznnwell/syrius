import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/native_p2p_swap/widgets/htlc_swap_details_widget.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/native_p2p_swap/widgets/swap_amount_info.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_details/p2p_swap_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Reclaimable native P2P swap content.
class ReclaimableSwapView extends StatelessWidget {
  /// Creates a [ReclaimableSwapView].
  const ReclaimableSwapView({required this._swap, super.key});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    final int? expiration = _swap.direction == P2pSwapDirection.outgoing
        ? _swap.initialHtlcExpirationTime
        : _swap.counterHtlcExpirationTime;
    final Duration remainingDuration = Duration(
      seconds: (expiration ?? 0) - DateTime.now().unixTimestamp,
    );
    final bool canReclaim = remainingDuration.inSeconds <= 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        SizedBox.square(
          dimension: 70,
          child: SvgPicture.asset(
            'assets/svg/ic_unsuccessful_symbol.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.errorColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        Text(
          canReclaim
              ? context.l10n.swapUnsuccessful
              : context.l10n.swapUnsuccessfulWaitForExpiration,
          style: context.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        Card.filled(
          color: AppColors.znnColor.withAlpha((255 * 0.2).round()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(context.l10n.depositedAmount),
                SwapAmountInfo(
                  amount: _swap.fromAmount,
                  token: _swap.fromToken,
                ),
              ],
            ),
          ),
        ),
        if (remainingDuration.inSeconds > 0)
          TweenAnimationBuilder<Duration>(
            duration: remainingDuration,
            tween: .new(begin: remainingDuration, end: Duration.zero),
            builder: (_, Duration duration, _) {
              return Visibility(
                visible: duration.inSeconds > 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(context.l10n.depositExpiresIn),
                      Text(duration.toString().split('.').first),
                    ],
                  ),
                ),
              );
            },
          ),
        if (canReclaim) _ReclaimButton(swap: _swap),
        HtlcSwapDetailsWidget(swap: _swap),
      ],
    );
  }
}

class _ReclaimButton extends StatelessWidget {
  const _ReclaimButton({required this._swap});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendTransactionBloc, SendTransactionState>(
      listener: _onTransactionStateChanged,
      builder: (_, SendTransactionState state) => InstructionButton(
        text: context.l10n.reclaimFunds,
        isEnabled: true,
        isLoading: state.status == SendTransactionStatus.loading,
        loadingText: context.l10n.reclaimingFundsPleaseWait,
        onPressed: () => _onReclaimPressed(context),
      ),
    );
  }

  void _onTransactionStateChanged(
    BuildContext context,
    SendTransactionState state,
  ) {
    if (state.status == SendTransactionStatus.success) {
      _sendConfirmationNotification(context, state.data!);
    } else if (state.status == SendTransactionStatus.failure) {
      unawaited(
        NotificationUtils.sendNotificationError(
          state.error!,
          context.l10n.errorReclaimingSwapFunds,
        ),
      );
    }
  }

  void _onReclaimPressed(BuildContext context) {
    final String htlcId = _swap.direction == P2pSwapDirection.outgoing
        ? _swap.initialHtlcId
        : _swap.counterHtlcId!;

    context.read<SendTransactionBloc>().add(
      SendTransactionInitiateFromBlock(
        block: zenon!.embedded.htlc.reclaim(Hash.parse(htlcId)),
        fromAddress: _swap.selfAddress,
        reasonForGeneratingPlasma: context.l10n.reclaimFunds,
      ),
    );
  }

  void _sendConfirmationNotification(
    BuildContext context,
    AccountBlockTemplate block,
  ) {
    unawaited(
      sl.get<NotificationsBloc>().addNotification(
        WalletNotification(
          title: context.l10n.swapReclaimBlockCreated,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: context.l10n.hashValue(block.hash.toString()),
          type: NotificationType.paymentSent,
        ),
      ),
    );
  }
}
