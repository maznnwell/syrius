import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/native_p2p_swap/widgets/htlc_swap_details_widget.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/native_p2p_swap/widgets/swap_amount_info.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_details/p2p_swap_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';

/// Completed native P2P swap content.
class CompletedSwapView extends StatelessWidget {
  /// Creates a [CompletedSwapView].
  const CompletedSwapView({required this._swap, super.key});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_completed_symbol.svg',
          colorFilter: const ColorFilter.mode(
            AppColors.znnColor,
            BlendMode.srcIn,
          ),
          height: 70,
        ),
        Text(
          context.l10n.swapCompleted,
          style: context.textTheme.titleMedium,
        ),
        Card.filled(
          color: AppColors.znnColor.withAlpha((255 * 0.2).round()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              spacing: kVerticalGap16.height!,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(context.l10n.from),
                    SwapAmountInfo(
                      amount: _swap.fromAmount,
                      token: _swap.fromToken,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(context.l10n.to),
                    SwapAmountInfo(
                      amount: _swap.toAmount,
                      token: _swap.toToken,
                    ),
                  ],
                ),
                ExchangeRateWidget(
                  fromAmount: _swap.fromAmount,
                  fromToken: _swap.fromToken,
                  toAmount: _swap.toAmount!,
                  toToken: _swap.toToken!,
                ),
              ],
            ),
          ),
        ),
        HtlcSwapDetailsWidget(swap: _swap),
      ],
    );
  }
}
