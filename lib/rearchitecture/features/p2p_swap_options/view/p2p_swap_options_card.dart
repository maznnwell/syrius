import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
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
    return BlocProvider<StartNativeSwapBloc>(
      create: (_) => StartNativeSwapBloc(
        accountBlockUtils: AccountBlockUtils(),
        htlcSwapsService: htlcSwapsService!,
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: const _View(),
      ),
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
    return BlocListener<StartNativeSwapBloc, StartNativeSwapState>(
      listener: _onStartNativeSwapStateChanged,
      child: StreamBuilder<PowStatus>(
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
      ),
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
          title: context.l10n.joinSwap,
          subtitle: context.l10n.p2pSwapJoinDescription,
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast(context)
              : unawaited(_onJoinSwapPressed(context)),
        ),
        kVerticalGap25,
        const Center(
          child: ViewSwapTutorialButton(),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => showCustomDialog(
              context: context,
              content: const RecoverDepositModal(),
            ),
            label: Text(context.l10n.recoverDeposit),
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

    unawaited(
      showCustomDialog(
        context: context,
        content: BlocProvider<StartNativeSwapBloc>.value(
          value: context.read<StartNativeSwapBloc>(),
          child: const StartNativeSwapModal(),
        ),
      ),
    );
  }

  Future<void> _onJoinSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);

    if (!canContinue || !context.mounted) {
      return;
    }

    final String? swapId = await showCustomDialog<String>(
      context: context,
      content: const JoinNativeSwapModal(),
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

  void _onStartNativeSwapStateChanged(
    BuildContext context,
    StartNativeSwapState state,
  ) {
    if (state is StartNativeSwapDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showNativeSwapDetailsModal(context, state.swap.id);
        }
      });
    } else if (state is StartNativeSwapFailure) {
      ToastUtils.showToast(context, state.exception.toString());
    }
  }

  void _showGeneratingPlasmaToast(BuildContext context) {
    ToastUtils.showToast(context, context.l10n.p2pSwapGeneratingPlasma);
  }
}
