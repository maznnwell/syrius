import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide InfiniteScrollTable, InfiniteScrollTableCell;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the P2P swaps conducted with this wallet.
class P2pSwapsCard extends StatelessWidget {
  /// Creates a [P2pSwapsCard].
  const P2pSwapsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final HtlcSwapsService swapsService = htlcSwapsService!;

    return BlocProvider<P2pSwapsBloc>(
      create: (_) => P2pSwapsBloc(
        htlcSwapsService: swapsService,
      )..add(const P2pSwapsRequested()),
      child: _View(swapsService: swapsService),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this._swapsService});

  final HtlcSwapsService _swapsService;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.p2pSwaps,
        description: context.l10n.p2pSwapsConductedWithWallet,
      ),
      onRefreshPressed: () {
        context.read<P2pSwapsBloc>().add(const P2pSwapsRequested());
      },
      body: BlocBuilder<P2pSwapsBloc, P2pSwapsState>(
        builder: (BuildContext context, P2pSwapsState state) {
          return switch (state) {
            P2pSwapsInitial() => const SyriusLoadingWidget(),
            P2pSwapsLoading() => const SyriusLoadingWidget(),
            P2pSwapsFailure(:final SyriusException exception) =>
              SyriusErrorWidget(exception),
            P2pSwapsPopulated(:final List<P2pSwap> swaps) => _Populated(
              onDeleteHistory: () => _onDeleteSwapHistoryTapped(context),
              onDeleteSwap: (P2pSwap swap) =>
                  _onDeleteSwapTapped(context, swap),
              swaps: swaps,
            ),
          };
        },
      ),
    );
  }

  Future<void> _onDeleteSwapTapped(
    BuildContext context,
    P2pSwap swap,
  ) async {
    final bool? deleteConfirmed = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: true,
      title: context.l10n.deleteSwap,
      description: context.l10n.deleteSwapCannotBeUndone,
    );

    if (deleteConfirmed ?? false) {
      if (swap.mode == P2pSwapMode.htlc) {
        await _swapsService.deleteSwap(swap.id);
      }
      if (context.mounted) {
        context.read<P2pSwapsBloc>().add(const P2pSwapsRequested());
      }
    }
  }

  Future<void> _onDeleteSwapHistoryTapped(BuildContext context) async {
    final bool? deleteHistoryConfirmed = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: true,
      title: context.l10n.deleteSwapHistory,
      description: context.l10n.deleteHistoryKeepsActiveSwaps,
    );

    if (deleteHistoryConfirmed ?? false) {
      await _swapsService.deleteInactiveSwaps();
      if (context.mounted) {
        context.read<P2pSwapsBloc>().add(const P2pSwapsRequested());
      }
    }
  }
}

class _Populated extends StatefulWidget {
  const _Populated({
    required this._onDeleteHistory,
    required this._onDeleteSwap,
    required this._swaps,
  });

  final VoidCallback _onDeleteHistory;
  final ValueChanged<P2pSwap> _onDeleteSwap;
  final List<P2pSwap> _swaps;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget._onDeleteHistory,
            icon: const Icon(Icons.delete),
            label: Text(context.l10n.deleteSwapHistory),
          ),
        ),
        Expanded(
          child: InfiniteScrollTable<P2pSwap>(
            onItemTap: (int index) {
              unawaited(
                showCustomDialog(
                  context: context,
                  content: NativeP2pSwapModal(swapId: widget._swaps[index].id),
                ),
              );
            },
            items: widget._swaps,
            hasReachedMax: true,
            generateRowCells: _buildRowCells,
            onScrollReachedBottom: () {},
            columns: const <InfiniteScrollTableColumnType>[
              .status,
              .from,
              .to,
              .started,
              .blank,
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRowCells(P2pSwap swap) {
    final BigInt? toAmount = swap.toAmount;
    final Token? toToken = swap.toToken;

    return <Widget>[
      InfiniteScrollTableCell(child: _Status(swap: swap)),
      InfiniteScrollTableCell(
        child: _Amount(
          amount: swap.fromAmount,
          token: swap.fromToken,
        ),
      ),
      if (swap.state == P2pSwapState.completed &&
          toAmount != null &&
          toToken != null)
        InfiniteScrollTableCell(
          child: _Amount(
            amount: toAmount,
            token: toToken,
          ),
        )
      else
        InfiniteScrollTableCell.withText(content: '-'),
      DateCell(timestampMs: swap.startTime * 1000),
      InfiniteScrollTableCell(
        child: _ActionButton(
          swap: swap,
          onDelete: widget._onDeleteSwap,
        ),
      ),
    ];
  }
}

class _Status extends StatelessWidget {
  const _Status({required this._swap});

  final P2pSwap _swap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildStatusIcon(),
        kHorizontalGap8,
        Text(_statusText(context)),
      ],
    );
  }

  Widget _buildStatusIcon() {
    return switch (_swap.state) {
      P2pSwapState.pending || P2pSwapState.active => const SyriusLoadingWidget(
        size: 18,
        strokeWidth: 2,
        padding: 2,
      ),
      P2pSwapState.completed => const Icon(
        Icons.check_circle_outline,
        color: AppColors.znnColor,
      ),
      P2pSwapState.reclaimable => Icon(
        Icons.call_received_rounded,
        color: ColorUtils.getTokenColor(_swap.fromToken.tokenStandard),
      ),
      _ => const Icon(
        Icons.cancel_outlined,
        color: AppColors.errorColor,
      ),
    };
  }

  String _statusText(BuildContext context) {
    return switch (_swap.state) {
      P2pSwapState.pending => context.l10n.starting,
      P2pSwapState.active => context.l10n.active,
      P2pSwapState.completed => context.l10n.completed,
      P2pSwapState.reclaimable => context.l10n.reclaimFunds,
      _ => context.l10n.unsuccessful,
    };
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this._amount, required this._token});

  final BigInt _amount;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _amount.addDecimals(_token.decimals),
        children: <InlineSpan>[
          const TextSpan(text: ' '),
          TextSpan(
            text: _token.symbol,
            style: TextStyle(
              color: ColorUtils.getTokenColor(_token.tokenStandard),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this._onDelete,
    required this._swap,
  });

  final ValueChanged<P2pSwap> _onDelete;
  final P2pSwap _swap;

  @override
  Widget build(BuildContext context) {
    final Widget deleteButton = OutlinedButton.icon(
      onPressed: () => _onDelete(_swap),
      icon: const Icon(Icons.delete),
      label: Text(context.l10n.deleteSwap),
    );

    return SizedBox(
      height: 36,
      child: switch (_swap.state) {
        P2pSwapState.completed => deleteButton,
        P2pSwapState.unsuccessful => deleteButton,
        _ => const SizedBox.shrink(),
      },
    );
  }
}
