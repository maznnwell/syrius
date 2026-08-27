import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/join_htlc_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_details/p2p_swap_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/swap_warning.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Form for reviewing and joining a validated native P2P swap.
class JoinNativeSwapForm extends StatefulWidget {
  /// Creates a [JoinNativeSwapForm].
  const JoinNativeSwapForm({
    required this.initialHtlc,
    required this.onJoinedSwap,
    super.key,
  });

  /// The fetched and validated initial HTLC.
  final HtlcInfo initialHtlc;

  /// Called with the identifier of the successfully joined swap.
  final ValueChanged<String> onJoinedSwap;

  @override
  State<JoinNativeSwapForm> createState() => _JoinNativeSwapFormState();
}

class _JoinNativeSwapFormState extends State<JoinNativeSwapForm> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  int? _safeExpirationTime;
  StreamSubscription<int>? _safeExpirationSubscription;

  Token _selectedToken = kZnnCoin;
  bool _isAmountValid = false;
  bool _isLoading = false;

  String get _selfAddress => widget.initialHtlc.hashLocked.toString();

  @override
  void initState() {
    super.initState();
    _addressController.text = _selfAddress;
    _safeExpirationTime = _calculateSafeExpirationTime(
      widget.initialHtlc.expirationTime,
    );
    unawaited(sl.get<BalanceBloc>().getBalanceForAllAddresses());
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
    unawaited(_safeExpirationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Token?>(
      future: zenon!.embedded.token.getByZts(
        widget.initialHtlc.tokenStandard,
      ),
      builder: (_, AsyncSnapshot<Token?> snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SyriusErrorWidget(snapshot.error!),
          );
        } else if (snapshot.hasData) {
          return _buildContent(snapshot.data!);
        }
        return const Padding(
          padding: EdgeInsets.all(50),
          child: SyriusLoadingWidget(),
        );
      },
    );
  }

  Widget _buildContent(Token tokenToReceive) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: LabeledInputContainer(
                labelText: context.l10n.yourAddress,
                helpText: context.l10n.receiveSwappedFundsToAddress,
                inputWidget: DisabledAddressField(
                  _addressController,
                  contentLeftPadding: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 20),
        LabeledInputContainer(
          labelText: context.l10n.youAreSending,
          inputWidget: Flexible(
            child: StreamBuilder<Map<String, AccountInfo>?>(
              stream: sl.get<BalanceBloc>().stream,
              builder: (_, AsyncSnapshot<Map<String, AccountInfo>?> snapshot) {
                if (snapshot.hasError) {
                  return SyriusErrorWidget(snapshot.error!);
                }
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return AmountInputField(
                      controller: _amountController,
                      accountInfo: snapshot.data![_selfAddress]!,
                      valuePadding: 10,
                      textColor: Theme.of(context).colorScheme.inverseSurface,
                      initialToken: _selectedToken,
                      hintText: '0.0',
                      onChanged: (Token token, bool isValid) {
                        setState(() {
                          _selectedToken = token;
                          _isAmountValid = isValid;
                        });
                      },
                    );
                  } else {
                    return const SyriusLoadingWidget();
                  }
                } else {
                  return const SyriusLoadingWidget();
                }
              },
            ),
          ),
        ),
        kVerticalSpacing,
        const Icon(
          AntDesign.arrowdown,
          color: Colors.white,
          size: 20,
        ),
        kVerticalSpacing,
        HtlcCard.fromHtlcInfo(
          title: context.l10n.youAreReceiving,
          htlc: widget.initialHtlc,
          token: tokenToReceive,
        ),
        const SizedBox(height: 20),
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
              _buildExchangeRateWidget(tokenToReceive),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
                  tokenToReceive.tokenStandard.toString(),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SwapWarning(
                    text: context.l10n.verifyNonFavoriteToken(
                      tokenToReceive.tokenStandard.toString(),
                    ),
                  ),
                ),
              ),
              _buildJoinSwapViewModel(tokenToReceive),
            ],
          )
        else
          SwapWarning(
            text: context.l10n.cannotJoinSwapExpiresTooSoon,
          ),
      ],
    );
  }

  ViewModelBuilder<JoinHtlcSwapBloc> _buildJoinSwapViewModel(
    Token tokenToReceive,
  ) {
    return ViewModelBuilder<JoinHtlcSwapBloc>.reactive(
      onViewModelReady: (JoinHtlcSwapBloc model) {
        model.stream.listen(
          (HtlcSwap? event) {
            if (mounted && event is HtlcSwap) {
              widget.onJoinedSwap.call(event.id);
            }
          },
          onError: (Object error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = false;
            });
            ToastUtils.showToast(context, error.toString());
          },
        );
      },
      builder: (_, JoinHtlcSwapBloc model, _) =>
          _buildJoinSwapButton(model, tokenToReceive),
      viewModelBuilder: JoinHtlcSwapBloc.new,
    );
  }

  Widget _buildJoinSwapButton(JoinHtlcSwapBloc model, Token tokenToReceive) {
    return InstructionButton(
      text: context.l10n.joinSwap,
      instructionText: context.l10n.inputAmountToSend,
      loadingText: context.l10n.sendingTransaction,
      isEnabled: _isInputValid(),
      isLoading: _isLoading,
      onPressed: () => _onJoinButtonPressed(model, tokenToReceive),
    );
  }

  Future<void> _onJoinButtonPressed(
    JoinHtlcSwapBloc model,
    Token tokenToReceive,
  ) async {
    setState(() {
      _isLoading = true;
    });
    unawaited(
      model.joinHtlcSwap(
        initialHtlc: widget.initialHtlc,
        fromToken: _selectedToken,
        toToken: tokenToReceive,
        fromAmount: _amountController.text.extractDecimals(
          _selectedToken.decimals,
        ),
        swapType: P2pSwapType.native,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        counterHtlcExpirationTime: _safeExpirationTime!,
      ),
    );
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

  Widget _buildExchangeRateWidget(Token tokenToReceive) {
    return ExchangeRateWidget(
      fromAmount: _amountController.text.extractDecimals(
        _selectedToken.decimals,
      ),
      fromDecimals: _selectedToken.decimals,
      fromSymbol: _selectedToken.symbol,
      toAmount: widget.initialHtlc.amount,
      toDecimals: tokenToReceive.decimals,
      toSymbol: tokenToReceive.symbol,
    );
  }

  bool _isInputValid() => _isAmountValid;
}
