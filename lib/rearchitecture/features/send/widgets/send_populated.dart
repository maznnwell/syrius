import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget with multiple [DropdownMenu] and [TextField] that allow the user
/// to select and input the information needed for sending a transaction
class SendPopulated extends StatefulWidget {
  /// Creates a new instance.
  const SendPopulated({
    required this.balances,
    super.key,
  });

  /// A map with wallet addresses as keys, and account info objects as values
  final Map<String, AccountInfo> balances;

  @override
  State<SendPopulated> createState() => _SendPopulatedState();
}

class _SendPopulatedState extends State<SendPopulated> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final FocusNode _recipientFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  final List<Token> _availableAssets = <Token>[];

  final ValueNotifier<Token> _selectedToken = .new(kDualCoin.first);

  final ValueNotifier<String> _sender = .new(kSelectedAddress!);

  // The amount as inputted by the user
  String get _amount => _amountController.text;

  String get _recipient => _recipientController.text;

  AccountInfo get _accountInfo => widget.balances[_sender.value]!;

  String? get _recipientErrorText =>
      _recipient.isNotEmpty ? InputValidators.checkAddress(_recipient) : null;

  String? get _amountErrorText => _amountController.text.isNotEmpty
      ? InputValidators.correctValue(
          _amountController.text,
          _accountInfo.getBalance(
            _selectedToken.value.tokenStandard,
          ),
          _selectedToken.value.decimals,
          BigInt.zero,
        )
      : null;

  bool get _isInputValid =>
      _recipientErrorText == null &&
      _amountErrorText == null &&
      _amountController.text.isNotEmpty &&
      _recipient.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sender.addListener(() {
      _selectedToken.value = kDualCoin.first;
      _initAvailableAssets();
    });
    _initAvailableAssets();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _selectedToken,
        _sender,
      ]),
      builder: (_, _) {
        final Token selectedToken = _selectedToken.value;

        return BlocListener<SendTransactionBloc, SendTransactionState>(
          listener: (_, SendTransactionState state) {
            if (state.status == SendTransactionStatus.loading) {
              _sendPaymentButtonKey.currentState?.animateForward();
            } else if (state.status == SendTransactionStatus.success) {
              unawaited(_sendConfirmationNotification(block: state.data!));
              _sendPaymentButtonKey.currentState?.animateReverse();
              _amountController.clear();
              _recipientController.clear();
            } else if (state.status == SendTransactionStatus.failure) {
              _sendPaymentButtonKey.currentState?.animateReverse();
              unawaited(_sendErrorNotification(state.error!));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildDefaultAddressDropdown(),
                    ),
                    kHorizontalGap8,
                    Expanded(
                      child: ZtsDropdown(
                        availableTokens: _availableAssets,
                        selectedToken: _selectedToken,
                      ),
                    ),
                  ],
                ),
                kVerticalGap8,
                AvailableBalance(
                  selectedToken,
                  _accountInfo,
                ),
                kVerticalGap8,
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _recipientController,
                  builder: (_, TextEditingValue recipient, _) {
                    return TextField(
                      key: const Key('send_recipient_field'),
                      controller: _recipientController,
                      decoration: InputDecoration(
                        errorText: _recipientErrorText,
                        hintText: context.l10n.recipientAddress,
                        suffixIcon: FieldSuffixButtons(
                          controller: _recipientController,
                        ),
                      ),
                      focusNode: _recipientFocusNode,
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_amountFocusNode);
                      },
                    );
                  },
                ),
                kVerticalGap16,
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountController,
                  builder: (_, TextEditingValue amount, _) {
                    return AmountTextField(
                      accountInfo: _accountInfo,
                      key: const Key('send_amount_field'),
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      errorText: _amountErrorText,
                      onSubmitted: (String value) {
                        if (_isInputValid) {
                          unawaited(_onSendPaymentPressed());
                        }
                      },
                      token: selectedToken,
                    );
                  },
                ),
                kVerticalGap16,
                Center(
                  child: ListenableBuilder(
                    listenable: Listenable.merge(<Listenable>[
                      _amountController,
                      _recipientController,
                    ]),
                    builder: (_, _) {
                      return KeyedSubtree(
                        key: const Key('send_submit_button'),
                        child: SendButton(
                          key: _sendPaymentButtonKey,
                          text: context.l10n.send,
                          onPressed: _isInputValid
                              ? _onSendPaymentPressed
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSendPaymentPressed() async {
    final String title = context.l10n.send;

    final String symbol = _selectedToken.value.symbol;

    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String description = context.l10n.areYouSureTranfer(
      _amount,
      recipient,
      symbol,
    );

    final bool? txConfirmed = await showDialogWithNoAndYesOptions(
      isBarrierDismissible: false,
      context: context,
      title: title,
      description: description,
    );

    if (txConfirmed ?? false) {
      _sendPayment();
    }
  }

  void _sendPayment() {
    context.read<SendTransactionBloc>().add(
      SendTransactionInitiate(
        amount: _amount.extractDecimals(_selectedToken.value.decimals),
        fromAddress: _sender.value,
        toAddress: _recipient,
        token: _selectedToken.value,
      ),
    );
  }

  Widget _buildDefaultAddressDropdown() {
    return Tooltip(
      message: context.l10n.senderAddressDescription,
      child: NewAddressesDropdown(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
        selectedAddress: _sender,
      ),
    );
  }

  Future<void> _sendErrorNotification(SyriusException error) async {
    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String symbol = _selectedToken.value.symbol;

    final String title = context.l10n.couldNotSend(_amount, recipient, symbol);

    await NotificationUtils.sendNotificationError(
      error,
      title,
    );
  }

  Future<void> _sendConfirmationNotification({
    required AccountBlockTemplate block,
  }) async {
    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String senderLabel = ZenonAddressUtils.getLabel(_sender.value);

    final String symbol = _selectedToken.value.symbol;

    final String title = context.l10n.sentDetails(
      _amount,
      recipient,
      senderLabel,
      symbol,
    );

    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: title,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.hashValue(block.hash.toString()),
        type: NotificationType.paymentSent,
      ),
    );
  }

  void _initAvailableAssets() {
    fillAvailableTokens(
      initialTokens: kDualCoin,
      list: _availableAssets,
      tokensWithBalance: getTokensWithBalance(
        accountInfo: widget.balances[_sender.value]!,
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _selectedToken.dispose();
    _sender.dispose();
    super.dispose();
  }
}
