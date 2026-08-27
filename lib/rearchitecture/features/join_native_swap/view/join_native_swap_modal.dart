import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/join_htlc_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/important_text_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Modal containing the form used to join a native P2P swap.
class JoinNativeSwapModal extends StatelessWidget {
  /// Creates a [JoinNativeSwapModal].
  const JoinNativeSwapModal({
    required this.onJoinedSwap,
    super.key,
  });

  /// Called with the identifier of the successfully joined swap.
  final ValueChanged<String> onJoinedSwap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InitialHtlcValidationBloc>(
      create: (_) => InitialHtlcValidationBloc(
        accountBlocksAfterTimeFetcher:
            AccountBlockUtils.getAccountBlocksAfterTime,
        htlcSwapsService: htlcSwapsService!,
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
      ),
      child: _View(onJoinedSwap: onJoinedSwap),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.onJoinedSwap});

  final ValueChanged<String> onJoinedSwap;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _depositIdController = TextEditingController();

  HtlcInfo? _initialHltc;
  int? _safeExpirationTime;
  StreamSubscription<int>? _safeExpirationSubscription;

  Token _selectedToken = kZnnCoin;
  bool _isAmountValid = false;
  bool _isLoading = false;

  String get _selfAddress => _initialHltc!.hashLocked.toString();

  @override
  void initState() {
    super.initState();
    unawaited(sl.get<BalanceBloc>().getBalanceForAllAddresses());
    _safeExpirationSubscription =
        Stream<int>.periodic(
          const Duration(seconds: 5),
          (int count) => count,
        ).listen((int _) {
          if (_initialHltc != null) {
            _safeExpirationTime = _calculateSafeExpirationTime(
              _initialHltc!.expirationTime,
            );
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _depositIdController.dispose();
    unawaited(_safeExpirationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      listenWhen: (_, InitialHtlcValidationState state) =>
          state is InitialHtlcValidationDone,
      listener: _onInitialHtlcValidationStateChanged,
      child: BaseModal(
        title: context.l10n.joinSwap,
        child: _initialHltc == null
            ? _buildSearchView()
            : FutureBuilder<Token?>(
                future: zenon!.embedded.token.getByZts(
                  _initialHltc!.tokenStandard,
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
              ),
      ),
    );
  }

  Widget _buildSearchView() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _depositIdController,
      builder: (_, TextEditingValue value, _) {
        final String? depositIdError = InputValidators.checkHash(value.text);
        final bool isDepositIdValid =
            value.text.isNotEmpty && depositIdError == null;

        return Column(
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                errorText: value.text.isNotEmpty ? depositIdError : null,
                hintText: context.l10n.depositIdProvidedByCounterparty,
                suffixIcon: FieldSuffixButtons(
                  controller: _depositIdController,
                ),
              ),
              controller: _depositIdController,
            ),
            _buildInitialHtlcValidationError(),
            InitialHtlcValidationButton(
              depositId: value.text,
              isEnabled: isDepositIdValid,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitialHtlcValidationError() {
    return BlocSelector<
      InitialHtlcValidationBloc,
      InitialHtlcValidationState,
      SyriusException?
    >(
      selector: (InitialHtlcValidationState state) => switch (state) {
        InitialHtlcValidationFailure(:final SyriusException exception) =>
          exception,
        _ => null,
      },
      builder: (_, SyriusException? exception) {
        if (exception == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: <Widget>[
            ImportantTextContainer(
              text: exception.toString(),
              showBorder: true,
            ),
            kVerticalGap16,
          ],
        );
      },
    );
  }

  void _onInitialHtlcValidationStateChanged(
    BuildContext context,
    InitialHtlcValidationState state,
  ) {
    if (state case InitialHtlcValidationDone(:final HtlcInfo htlc)) {
      setState(() {
        _initialHltc = htlc;
        _addressController.text = htlc.hashLocked.toString();
        _safeExpirationTime = _calculateSafeExpirationTime(
          htlc.expirationTime,
        );
      });
    }
  }

  Widget _buildContent(Token tokenToReceive) {
    final int minutesLeftToJoin =
        (((_initialHltc!.expirationTime -
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
          htlc: _initialHltc!,
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
                  child: ImportantTextContainer(
                    text: context.l10n.verifyNonFavoriteToken(
                      tokenToReceive.tokenStandard.toString(),
                    ),
                    isSelectable: true,
                  ),
                ),
              ),
              _buildJoinSwapViewModel(tokenToReceive),
            ],
          )
        else
          ImportantTextContainer(
            text: context.l10n.cannotJoinSwapExpiresTooSoon,
            showBorder: true,
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
        initialHtlc: _initialHltc!,
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
      toAmount: _initialHltc!.amount,
      toDecimals: tokenToReceive.decimals,
      toSymbol: tokenToReceive.symbol,
    );
  }

  bool _isInputValid() => _isAmountValid;
}
