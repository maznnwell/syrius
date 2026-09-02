import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SwapAmount extends StatelessWidget {
  const SwapAmount({required this._amount, required this._token, super.key});
  
  final BigInt _amount;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _amount.addDecimals(_token.decimals),
        children: <InlineSpan>[
          const TextSpan(
            text: ' ',
          ),
          TextSpan(
            text: _token.symbol,
            style: TextStyle(
              color: ColorUtils.getTokenColor(
                _token.tokenStandard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
