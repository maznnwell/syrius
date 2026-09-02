import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_details/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SwapStatus extends StatelessWidget {
  const SwapStatus({required this._swap, super.key});

  final P2pSwap _swap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatusIcon(),
        kHorizontalGap8,
        _buildStatusText(context),
      ],
    );
  }

  Widget _buildStatusIcon() {
    const double size = 16;
    switch (_swap.state) {
      case P2pSwapState.pending:
      case P2pSwapState.active:
        return const SyriusLoadingWidget(
          size: 12,
          strokeWidth: 2,
          padding: 2,
        );
      case P2pSwapState.completed:
        return const Icon(
          Icons.check_circle_outline,
          color: AppColors.znnColor,
          size: size,
        );
      default:
        return const Icon(
          Icons.cancel_outlined,
          color: AppColors.errorColor,
          size: size,
        );
    }
  }

  Widget _buildStatusText(BuildContext context) {
    final String text = switch (_swap.state) {
      P2pSwapState.pending => context.l10n.starting,
      P2pSwapState.active => context.l10n.active,
      P2pSwapState.completed => context.l10n.completed,
      _ => context.l10n.unsuccessful,
    };
    return Text(text);
  }
}
