import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_options/widgets/p2p_swap_options_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_options/widgets/p2p_swap_warning_modal.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/start_native_swap/start_native_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/join_native_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/native_p2p_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/recover_deposit_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card with the actions available for native P2P swaps.
class P2pSwapOptionsCard extends StatelessWidget {
  /// Creates a P2P swap options card.
  const P2pSwapOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: const _View(),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.p2pSwapOptionsTitle,
    description: context.l10n.p2pSwapOptionsDescription,
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PowStatus>(
      stream: sl.get<PowGeneratingStatusBloc>().stream,
      builder: (_, AsyncSnapshot<PowStatus> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }

        return _buildNativeOptions(
          context: context,
          isGeneratingPlasma: snapshot.data == PowStatus.generating,
        );
      },
    );
  }

  Widget _buildNativeOptions({
    required BuildContext context,
    required bool isGeneratingPlasma,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        P2pSwapOptionsButton(
          title: context.l10n.p2pSwapStart,
          subtitle: context.l10n.p2pSwapStartDescription,
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast(context)
              : unawaited(_onStartSwapPressed(context)),
        ),
        kVerticalGap25,
        P2pSwapOptionsButton(
          title: context.l10n.p2pSwapJoin,
          subtitle: context.l10n.p2pSwapJoinDescription,
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast(context)
              : unawaited(_onJoinSwapPressed(context)),
        ),
        kVerticalGap25,
        Center(
          child: TextButton.icon(
            onPressed: () => unawaited(
              NavigationUtils.openUrl(kP2pSwapTutorialLink),
            ),
            label: Text(context.l10n.p2pSwapTutorial),
            icon: const Icon(Icons.open_in_new),
            iconAlignment: IconAlignment.end,
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => showCustomDialog(
              context: context,
              content: const RecoverDepositModal(),
            ),
            label: Text(context.l10n.p2pSwapRecoverDeposit),
            icon: const Icon(Icons.refresh),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ],
    );
  }

  Future<void> _onStartSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);

    if (!canContinue || !context.mounted) {
      return;
    }

    final String? swapId = await showCustomDialog<String>(
      context: context,
      content: const StartNativeSwapModal(),
    );

    if (swapId == null || !context.mounted) {
      return;
    }

    _showNativeSwapDetailsModal(context, swapId);
  }

  Future<void> _onJoinSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);

    if (!canContinue || !context.mounted) {
      return;
    }

    final String? swapId = await showCustomDialog<String>(
      context: context,
      content: JoinNativeSwapModal(
        onJoinedSwap: (String swapId) => Navigator.pop(context, swapId),
      ),
    );

    if (swapId == null || !context.mounted) {
      return;
    }

    _showNativeSwapDetailsModal(context, swapId);
  }

  Future<bool> _confirmUserWarningIfNeeded(BuildContext context) async {
    final bool hasReadWarning = sharedPrefsService!.get(
      kHasReadP2pSwapWarningKey,
      defaultValue: kHasReadP2pSwapWarningDefaultValue,
    );

    if (hasReadWarning) {
      return true;
    }

    final bool? result = await showCustomDialog<bool>(
      context: context,
      content: const P2pSwapWarningModal(),
    );

    if (result == true) {
      await sharedPrefsService!.put(kHasReadP2pSwapWarningKey, true);
      return true;
    }

    return false;
  }

  void _showNativeSwapDetailsModal(BuildContext context, String swapId) {
    unawaited(
      showCustomDialog(
        context: context,
        content: NativeP2pSwapModal(
          swapId: swapId,
        ),
      ),
    );
  }

  void _showGeneratingPlasmaToast(BuildContext context) {
    ToastUtils.showToast(context, context.l10n.p2pSwapGeneratingPlasma);
  }
}
