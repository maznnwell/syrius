import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AmountTextField extends StatelessWidget {
  const AmountTextField({
    required this._accountInfo,
    required this._token,
    required this._controller,
    required this._errorText,
    required this._focusNode,
    required this._onSubmitted,
    super.key,
  });

  final AccountInfo _accountInfo;
  final TextEditingController _controller;
  final String? _errorText;
  final FocusNode _focusNode;
  final void Function(String) _onSubmitted;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('send_amount_field'),
      controller: _controller,
      decoration: InputDecoration(
        errorText: _errorText,
        hintText: context.l10n.amount,
        suffixIcon: TextButton(
          onPressed: () => _onMaxPressed(
            accountInfo: _accountInfo,
            selectedToken: _token,
            controller: _controller,
          ),
          child: Text(context.l10n.max.toUpperCase()),
        ),
      ),
      focusNode: _focusNode,
      inputFormatters: FormatUtils.getAmountTextInputFormatters(
        _controller.text,
      ),
      onSubmitted: _onSubmitted,
    );
  }

  void _onMaxPressed({
    required AccountInfo accountInfo,
    required Token selectedToken,
    required TextEditingController controller,
  }) {
    final String amount = controller.text;

    final BigInt maxBalance = accountInfo.getBalance(
      selectedToken.tokenStandard,
    );

    final BigInt currentBalance = amount.isEmpty
        ? BigInt.zero
        : amount.extractDecimals(selectedToken.decimals);

    if (currentBalance < maxBalance) {
      controller.text = maxBalance.addDecimals(selectedToken.decimals);
    }
  }
}
