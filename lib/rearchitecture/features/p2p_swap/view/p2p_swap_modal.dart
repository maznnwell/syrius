import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class P2pSwapModal extends StatelessWidget {
  const P2pSwapModal({
    required this.swapId,
    super.key,
  });

  final String swapId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<P2pSwapDetailsBloc>(
          create: (_) => P2pSwapDetailsBloc(
            htlcSwapsService: htlcSwapsService!,
            swapId: swapId,
          )..add(const P2pSwapDetailsRequested()),
        ),
        BlocProvider<CompleteSwapBloc>(
          create: (_) => CompleteSwapBloc(
            accountBlockUtils: AccountBlockUtils(
              publishSuccessNotification: false,
            ),
            htlcSwapsService: htlcSwapsService!,
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
      ],
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompleteSwapBloc, CompleteSwapState>(
      listener: _onCompleteSwapStateChanged,
      child: BlocBuilder<P2pSwapDetailsBloc, P2pSwapDetailsState>(
        builder: (BuildContext context, P2pSwapDetailsState state) {
          return switch (state) {
            P2pSwapDetailsPopulated(:final HtlcSwap swap) => BaseModal(
              title: swap.state.statusText(context),
              child: _buildContent(swap),
            ),
            P2pSwapDetailsFailure(:final SyriusException exception) =>
              BaseModal(
                title: context.l10n.error,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SyriusErrorWidget(exception),
                ),
              ),
            P2pSwapDetailsInitial() => const SyriusLoadingWidget(),
            P2pSwapDetailsLoading() => const SyriusLoadingWidget(),
          };
        },
      ),
    );
  }

  Widget _buildContent(HtlcSwap swap) {
    return switch (swap.state) {
      P2pSwapState.pending => const _Pending(),
      P2pSwapState.active => ActiveSwapView(swap: swap),
      P2pSwapState.completed => CompletedSwapView(swap: swap),
      P2pSwapState.reclaimable => ReclaimableSwapView(swap: swap),
      P2pSwapState.unsuccessful => UnsuccessfulSwapView(swap: swap),
      P2pSwapState.error => SyriusErrorWidget(FailureException()),
    };
  }

  void _onCompleteSwapStateChanged(
    BuildContext context,
    CompleteSwapState state,
  ) {
    if (state case CompleteSwapDone(:final AccountBlockTemplate block)) {
      context.read<P2pSwapDetailsBloc>().add(
        const P2pSwapDetailsRequested(),
      );
      unawaited(
        NotificationUtils.showForegroundNotification(
          context,
          WalletNotification(
            title: context.l10n.swapCompleted,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: context.l10n.hashValue(block.hash.toString()),
            type: NotificationType.paymentSent,
          ),
          toastMessage: context.l10n.swapCompletedFundsSoon,
        ),
      );
    } else if (state case CompleteSwapFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorCompletingSwap,
        ),
      );
    }
  }
}

class _Pending extends StatelessWidget {
  const _Pending();

  @override
  Widget build(BuildContext context) {
    final double height = context.customDialogMaxHeight / 4;

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            context.l10n.startingSwapPleaseWait,
            style: context.textTheme.titleMedium,
          ),
          const SyriusLoadingWidget(),
        ],
      ),
    );
  }
}
