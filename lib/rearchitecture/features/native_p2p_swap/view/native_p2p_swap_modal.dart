import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/single_child_widget.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/complete_htlc_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/elevated_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/important_text_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_info_text.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class NativeP2pSwapModal extends StatefulWidget {
  const NativeP2pSwapModal({
    required this.swapId,
    super.key,
  });

  final String swapId;

  @override
  State<NativeP2pSwapModal> createState() => _NativeP2pSwapModalState();
}

class _NativeP2pSwapModalState extends State<NativeP2pSwapModal> {
  bool _isSendingTransaction = false;
  bool _shouldShowIncorrectAmountInstructions = false;
  bool _shouldShowFundsReceivedMessage = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<P2pSwapDetailsBloc>(
          create: (_) => P2pSwapDetailsBloc(
            htlcSwapsService: htlcSwapsService!,
            swapId: widget.swapId,
          )..add(const P2pSwapDetailsRequested()),
        ),
        BlocProvider<SendTransactionBloc>(
          create: (_) => SendTransactionBloc(),
        ),
      ],
      child: BlocBuilder<P2pSwapDetailsBloc, P2pSwapDetailsState>(
        builder: (_, P2pSwapDetailsState state) {
          return switch (state) {
            P2pSwapDetailsPopulated(:final HtlcSwap swap) => BaseModal(
              title: _getTitle(swap),
              child: _getContent(swap),
            ),
            P2pSwapDetailsFailure(:final SyriusException exception) =>
              BaseModal(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SyriusErrorWidget(exception),
                ),
              ),
            P2pSwapDetailsInitial() => const SyriusLoadingWidget(),
            P2pSwapDetailsLoading() => const SyriusLoadingWidget(),
          };
        },
      ),
    );
  }

  String? _getTitle(HtlcSwap swap) {
    return swap.state == P2pSwapState.active ? context.l10n.activeSwap : null;
  }

  Widget _getContent(HtlcSwap swap) {
    switch (swap.state) {
      case P2pSwapState.pending:
        return _getPendingView();
      case P2pSwapState.active:
        return _getActiveView(swap);
      case P2pSwapState.completed:
        return _getCompletedView(swap);
      case P2pSwapState.reclaimable:
      case P2pSwapState.unsuccessful:
        return _Unsuccessful(swap: swap);
      default:
        return Container();
    }
  }

  Widget _getPendingView() {
    return SizedBox(
      height: 215,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.l10n.startingSwapPleaseWait,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 25),
          const SyriusLoadingWidget(),
        ],
      ),
    );
  }

  Widget _getActiveView(HtlcSwap swap) {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 20,
        ),
        HtlcCard.sending(swap: swap),
        const SizedBox(
          height: 15,
        ),
        const Icon(
          AntDesign.arrowdown,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(
          height: 15,
        ),
        HtlcCard.receiving(swap: swap),
        const SizedBox(
          height: 25,
        ),
        _getBottomSection(swap),
      ],
    );
  }

  Widget _getCompletedView(HtlcSwap swap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          height: 10,
        ),
        Container(
          width: 72,
          height: 72,
          color: Colors.transparent,
          child: SvgPicture.asset(
            'assets/svg/ic_completed_symbol.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.znnColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Text(
          _shouldShowFundsReceivedMessage
              ? context.l10n.swapCompletedFundsSoon
              : context.l10n.swapCompleted,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 25),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xff282828),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      context.l10n.from,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitleColor,
                      ),
                    ),
                    _AmountInfo(
                      swap: swap,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      context.l10n.to,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitleColor,
                      ),
                    ),
                    _AmountInfo(
                      swap: swap,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      context.l10n.exchangeRate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitleColor,
                      ),
                    ),
                    _getExchangeRateWidget(swap),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        HtlcSwapDetailsWidget(swap: swap),
      ],
    );
  }

  Widget _getBottomSection(HtlcSwap swap) {
    if (swap.counterHtlcId == null) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              context.l10n.shareDepositIdWithCounterparty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          SyriusElevatedButton(
            text: context.l10n.copyDepositId,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
            ),
            onPressed: () =>
                ClipboardUtils.copyToClipboard(swap.initialHtlcId, context),
            icon: const Icon(
              Icons.copy,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  context.l10n.exchangeRate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitleColor,
                  ),
                ),
                _getExchangeRateWidget(swap),
              ],
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Visibility(
            visible: swap.direction == P2pSwapDirection.outgoing,
            child: Column(
              children: <Widget>[
                Visibility(
                  visible: !isTrustedToken(swap.toTokenStandard ?? ''),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: ImportantTextContainer(
                      text: context.l10n.verifyNonFavoriteToken(
                        swap.toTokenStandard ?? '',
                      ),
                      isSelectable: true,
                    ),
                  ),
                ),
                _getExpirationWarningForOutgoingSwap(swap),
                _getSwapButtonViewModel(swap),
                const SizedBox(
                  height: 25,
                ),
                _getIncorrectAmountButton(swap),
              ],
            ),
          ),
          Visibility(
            visible: swap.direction == P2pSwapDirection.incoming,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: LoadingInfoText(
                text: context.l10n.waitingForCounterpartyKeepRunning,
                tooltipText: context.l10n.walletNotAutoLocked,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _getExpirationWarningForOutgoingSwap(HtlcSwap swap) {
    const Duration warningThreshold = Duration(minutes: 10);
    final Duration timeToCompleteSwap =
        Duration(
          seconds: swap.counterHtlcExpirationTime! - DateTimeUtils.unixTimeNow,
        ) -
        kMinSafeTimeToCompleteSwap;
    return TweenAnimationBuilder<Duration>(
      duration: timeToCompleteSwap,
      tween: .new(begin: timeToCompleteSwap, end: Duration.zero),
      onEnd: () => setState(() {}),
      builder: (_, Duration d, _) {
        return Visibility(
          visible: timeToCompleteSwap <= warningThreshold,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: ImportantTextContainer(
              text: context.l10n.swapExpiresIn(
                d.toString().split('.').first,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getSwapButtonViewModel(HtlcSwap swap) {
    return ViewModelBuilder<CompleteHtlcSwapBloc>.reactive(
      onViewModelReady: (CompleteHtlcSwapBloc model) {
        model.stream.listen(
          (HtlcSwap? event) async {
            if (event is HtlcSwap) {
              setState(() {
                _shouldShowFundsReceivedMessage = true;
              });
            }
          },
          onError: (error) {
            setState(() {
              _isSendingTransaction = false;
            });
            ToastUtils.showToast(context, error.toString());
          },
        );
      },
      builder: (_, CompleteHtlcSwapBloc model, _) => InstructionButton(
        text: context.l10n.swap,
        isEnabled: true,
        isLoading: _isSendingTransaction,
        loadingText: context.l10n.swapping,
        onPressed: () {
          setState(() {
            _isSendingTransaction = true;
          });
          unawaited(model.completeHtlcSwap(swap: swap));
        },
      ),
      viewModelBuilder: CompleteHtlcSwapBloc.new,
    );
  }

  Widget _getIncorrectAmountButton(HtlcSwap swap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 50),
          firstCurve: Curves.easeInOut,
          firstChild: InkWell(
            onTap: () => setState(() {
              _shouldShowIncorrectAmountInstructions = true;
            }),
            child: Center(
              child: Text(
                context.l10n.receivingWrongTokenOrAmount,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitleColor,
                ),
              ),
            ),
          ),
          secondChild: _getIncorrectAmountInstructions(
            swap.initialHtlcExpirationTime,
          ),
          crossFadeState: _shouldShowIncorrectAmountInstructions
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ),
    );
  }

  Widget _getIncorrectAmountInstructions(int expirationTime) {
    return Text(
      context.l10n.waitToReclaimIncorrectDeposit(
        FormatUtils.formatDate(
          expirationTime * 1000,
          dateFormat: kDefaultDateTimeFormat,
        ),
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
      ),
    );
  }

  Widget _getExchangeRateWidget(HtlcSwap swap) {
    return ExchangeRateWidget(
      fromAmount: swap.fromAmount,
      fromDecimals: swap.fromDecimals,
      fromSymbol: swap.fromSymbol,
      toAmount: swap.toAmount!,
      toDecimals: swap.toDecimals!,
      toSymbol: swap.toSymbol!,
    );
  }
}

class _Unsuccessful extends StatelessWidget {
  const _Unsuccessful({required this._swap});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    final int? expiration = _swap.direction == P2pSwapDirection.outgoing
        ? _swap.initialHtlcExpirationTime
        : _swap.counterHtlcExpirationTime;
    final Duration remainingDuration = Duration(
      seconds: (expiration ?? 0) - DateTimeUtils.unixTimeNow,
    );

    final bool isReclaimable =
        remainingDuration.inSeconds <= 0 &&
        _swap.state == P2pSwapState.reclaimable;

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
          isReclaimable || _swap.state == P2pSwapState.unsuccessful
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
                Text(
                  _swap.state == P2pSwapState.reclaimable
                      ? context.l10n.depositedAmount
                      : context.l10n.depositedAmountReclaimed,
                ),
                _AmountInfo(swap: _swap),
              ],
            ),
          ),
        ),
        if (remainingDuration.inSeconds > 0)
          TweenAnimationBuilder<Duration>(
            duration: remainingDuration,
            tween: .new(begin: remainingDuration, end: Duration.zero),
            builder: (_, Duration d, _) {
              return Visibility(
                visible: d.inSeconds > 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        context.l10n.depositExpiresIn,
                      ),
                      Text(
                        d.toString().split('.').first,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (isReclaimable) _ReclaimButton(swap: _swap),
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

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({required this._swap});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    final String amount = _swap.fromAmount.addDecimals(_swap.fromDecimals);
    final String symbol = _swap.fromSymbol;

    return Text('$amount $symbol');
  }
}
