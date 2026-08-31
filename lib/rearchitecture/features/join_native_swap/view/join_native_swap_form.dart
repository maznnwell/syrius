import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/bloc/join_native_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/widgets/join_swap_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_swap_availability/join_swap_availability.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
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

  Token get _token => _tokenNotifier.value;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialHtlc.hashLocked.toString();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _tokenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JoinSwapAvailabilityCubit>(
      create: (_) => JoinSwapAvailabilityCubit(
        initialHtlc: widget.initialHtlc,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
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
                _buildAvailabilitySection(
                  amount: amount,
                  counterpartyDeadlineBullet: counterpartyDeadlineBullet,
                  isAmountValid: isAmountValid,
                  reclaimBullet: reclaimBullet,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAvailabilitySection({
    required String amount,
    required String counterpartyDeadlineBullet,
    required bool isAmountValid,
    required String reclaimBullet,
  }) {
    return BlocBuilder<JoinSwapAvailabilityCubit, JoinSwapAvailabilityState>(
      builder: (_, JoinSwapAvailabilityState state) => switch (state) {
        JoinSwapAvailable(:final int minutesLeftToJoin) => Column(
          children: <Widget>[
            const SizedBox(height: 20),
            BulletPointCard(
              bulletPoints: <String>[
                context.l10n.minutesLeftToJoinSwap(minutesLeftToJoin),
                counterpartyDeadlineBullet,
                reclaimBullet,
              ],
            ),
            const SizedBox(height: 20),
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
            JoinSwapButton(
              fromAmount: amount,
              fromToken: _token,
              initialHtlc: widget.initialHtlc,
              isEnabled: isAmountValid,
              toToken: widget.token,
            ),
          ],
        ),
        JoinSwapUnavailable() => Column(
          children: <Widget>[
            const SizedBox(height: 20),
            SwapWarning(
              text: context.l10n.cannotJoinSwapExpiresTooSoon,
            ),
          ],
        ),
      },
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
