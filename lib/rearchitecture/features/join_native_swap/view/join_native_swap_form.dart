import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/bloc/join_native_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_details/p2p_swap_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/swap_warning.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Form for reviewing and joining a validated native P2P swap.
class JoinNativeSwapForm extends StatefulWidget {
  /// Creates a [JoinNativeSwapForm].
  const JoinNativeSwapForm({
    required this.accountInfo,
    required this.initialHtlc,
    required this.token,
    super.key,
  });

  /// Current account information for the address joining the swap.
  final AccountInfo accountInfo;

  /// The fetched and validated initial HTLC.
  final HtlcInfo initialHtlc;

  /// Token locked in the initial HTLC.
  final Token token;

  @override
  State<JoinNativeSwapForm> createState() => _JoinNativeSwapFormState();
}

class _JoinNativeSwapFormState extends State<JoinNativeSwapForm> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ValueNotifier<Token> _tokenNotifier = .new(kZnnCoin);

  int? _safeExpirationTime;
  StreamSubscription<int>? _safeExpirationSubscription;

  Token get _token => _tokenNotifier.value;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialHtlc.hashLocked.toString();
    _safeExpirationTime = _calculateSafeExpirationTime(
      widget.initialHtlc.expirationTime,
    );
    _safeExpirationSubscription =
        Stream<int>.periodic(
          const Duration(seconds: 5),
          (int count) => count,
        ).listen((int _) {
          _safeExpirationTime = _calculateSafeExpirationTime(
            widget.initialHtlc.expirationTime,
          );
          setState(() {});
        });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _tokenNotifier.dispose();
    unawaited(_safeExpirationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildContent();

  Widget _buildContent() {
    final int minutesLeftToJoin =
        (((widget.initialHtlc.expirationTime -
                        kMinSafeTimeToFindPreimage.inSeconds -
                        kCounterHtlcDuration.inSeconds) -
                    DateTimeUtils.unixTimeNow) /
                60)
            .ceil();
    final String joinDeadlineBullet = context.l10n.minutesLeftToJoinSwap(
      minutesLeftToJoin,
    );
    final String counterpartyDeadlineBullet = context.l10n
        .counterpartyTimeToCompleteSwap(
          kCounterHtlcDuration.inHours,
        );
    final String reclaimBullet = context.l10n.reclaimFundsIfCounterpartyFails;

    return BlocConsumer<JoinNativeSwapBloc, JoinNativeSwapState>(
      listener: _onJoinNativeSwapStateChanged,
      builder: (_, JoinNativeSwapState state) {
        final bool isSwapLoading = state is JoinNativeSwapLoading;

        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _amountController,
            _tokenNotifier,
          ]),
          builder: (_, _) {
            final String amount = _amountController.text;
            final String? amountError = InputValidators.correctValue(
              amount,
              widget.accountInfo.getBalance(_token.tokenStandard),
              _token.decimals,
              BigInt.zero,
            );
            final bool isAmountValid = amount.isNotEmpty && amountError == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: kVerticalGap16.height!,
              children: <Widget>[
                DisabledAddressField(
                  _addressController,
                  labelText: context.l10n.receiveSwappedFundsToAddress,
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AmountTextField(
                        accountInfo: widget.accountInfo,
                        controller: _amountController,
                        enabled: !isSwapLoading,
                        errorText: amount.isNotEmpty ? amountError : null,
                        labelText: context.l10n.youAreSending,
                        token: _token,
                        onSubmitted: (_) {},
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: ZtsDropdown(
                        availableTokens: getTokensWithBalance(
                          accountInfo: widget.accountInfo,
                        ),
                        enabled: !isSwapLoading,
                        label: Text(context.l10n.asset),
                        selectedToken: _tokenNotifier,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  AntDesign.arrowdown,
                  color: Colors.white,
                ),
                HtlcCard.fromHtlcInfo(
                  title: context.l10n.youAreReceiving,
                  htlc: widget.initialHtlc,
                  token: widget.token,
                ),
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
                      _buildExchangeRateWidget(),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                if (_safeExpirationTime != null) const SizedBox(height: 20),
                if (_safeExpirationTime != null)
                  BulletPointCard(
                    bulletPoints: <String>[
                      joinDeadlineBullet,
                      counterpartyDeadlineBullet,
                      reclaimBullet,
                    ],
                  ),
                const SizedBox(height: 20),
                if (_safeExpirationTime != null)
                  Column(
                    children: <Widget>[
                      Visibility(
                        visible: !isTrustedToken(
                          widget.token.tokenStandard.toString(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SwapWarning(
                            text: context.l10n.verifyNonFavoriteToken(
                              widget.token.tokenStandard.toString(),
                            ),
                          ),
                        ),
                      ),
                      _buildJoinSwapButton(
                        isEnabled: isAmountValid,
                        isLoading: isSwapLoading,
                      ),
                    ],
                  )
                else
                  SwapWarning(
                    text: context.l10n.cannotJoinSwapExpiresTooSoon,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildJoinSwapButton({
    required bool isEnabled,
    required bool isLoading,
  }) {
    return InstructionButton(
      text: context.l10n.joinSwap,
      instructionText: context.l10n.inputAmountToSend,
      loadingText: context.l10n.sendingTransaction,
      isEnabled: isEnabled,
      isLoading: isLoading,
      onPressed: _onJoinButtonPressed,
    );
  }

  void _onJoinButtonPressed() {
    context.read<JoinNativeSwapBloc>().add(
      JoinNativeSwapRequested(
        initialHtlc: widget.initialHtlc,
        fromToken: _token,
        toToken: widget.token,
        fromAmount: _amountController.text.extractDecimals(
          _token.decimals,
        ),
        swapType: P2pSwapType.native,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        counterHtlcExpirationTime: _safeExpirationTime!,
      ),
    );
  }

  void _onJoinNativeSwapStateChanged(
    BuildContext context,
    JoinNativeSwapState state,
  ) {
    if (state is JoinNativeSwapDone) {
      Navigator.pop(context);
    } else if (state is JoinNativeSwapFailure) {
      ToastUtils.showToast(context, state.exception.toString());
    }
  }

  int? _calculateSafeExpirationTime(int initialHtlcExpiration) {
    final Duration minNeededRemainingTime =
        kMinSafeTimeToFindPreimage + kCounterHtlcDuration;
    final int now = DateTimeUtils.unixTimeNow;
    final Duration remaining = Duration(seconds: initialHtlcExpiration - now);
    return remaining >= minNeededRemainingTime
        ? now + kCounterHtlcDuration.inSeconds
        : null;
  }

  Widget _buildExchangeRateWidget() {
    return ExchangeRateWidget(
      fromAmount: _amountController.text.extractDecimals(
        _token.decimals,
      ),
      fromDecimals: _token.decimals,
      fromSymbol: _token.symbol,
      toAmount: widget.initialHtlc.amount,
      toDecimals: widget.token.decimals,
      toSymbol: widget.token.symbol,
    );
  }
}
