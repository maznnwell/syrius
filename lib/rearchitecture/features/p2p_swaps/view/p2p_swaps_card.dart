import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swaps_list_item.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

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
            P2pSwapsFailure(:final exception) => SyriusErrorWidget(exception),
            P2pSwapsPopulated(:final List<P2pSwap> swaps) => _Populated(
              isMaxSwapsReached: _swapsService.isMaxSwapsReached,
              onDeleteHistory: () => _onDeleteSwapHistoryTapped(context),
              onDeleteSwap: (P2pSwap swap) =>
                  _onDeleteSwapTapped(context, swap),
              onSwapTapped: (String swapId) => _onSwapTapped(context, swapId),
              swaps: swaps,
            ),
          };
        },
      ),
    );
  }

  void _onSwapTapped(BuildContext context, String swapId) {
    unawaited(showCustomDialog(
      context: context,
      content: NativeP2pSwapModal(swapId: swapId),
    ));
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
    required this._isMaxSwapsReached,
    required this._onDeleteHistory,
    required this._onDeleteSwap,
    required this._onSwapTapped,
    required this._swaps,
  });

  final bool _isMaxSwapsReached;
  final VoidCallback _onDeleteHistory;
  final ValueChanged<P2pSwap> _onDeleteSwap;
  final ValueChanged<String> _onSwapTapped;
  final List<P2pSwap> _swaps;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        spacing: kVerticalGap16.height!,
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget._onDeleteHistory,
              icon: const Icon(Icons.delete),
              label: Text(context.l10n.deleteSwapHistory),
            ),
          ),
          if (widget._swaps.isEmpty)
            Expanded(
              child: SyriusErrorWidget(context.l10n.noP2pSwaps),
            )
          else ...<Widget>[
            _buildHeader(),
            Expanded(child: _buildList()),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      cacheExtent: 1000,
      itemCount: widget._swaps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 15),
      itemBuilder: (_, int index) {
        final P2pSwap swap = widget._swaps[index];
        // TODO(maznnwell): each item should have a delete button
        return P2pSwapsListItem(
          key: ValueKey<String>(swap.id),
          swap: swap,
          onTap: widget._onSwapTapped,
          onDelete: widget._onDeleteSwap,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 20,
            child: _buildHeaderItem(context.l10n.status),
          ),
          Expanded(
            flex: 20,
            child: _buildHeaderItem(context.l10n.from),
          ),
          Expanded(
            flex: 20,
            child: _buildHeaderItem(context.l10n.to),
          ),
          Expanded(
            flex: 20,
            child: _buildHeaderItem(context.l10n.started),
          ),
          Expanded(
            flex: 20,
            child: Visibility(
              visible: widget._isMaxSwapsReached,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  _buildHeaderItem(
                    context.l10n.swapHistoryFull,
                    textColor: AppColors.errorColor,
                    textHeight: 1,
                  ),
                  const SizedBox(width: 5),
                  Tooltip(
                    message: context.l10n.oldestSwapDeletedWhenFull,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.info,
                        color: AppColors.errorColor,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(
    String text, {
    Color? textColor,
    double? textHeight,
  }) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, height: textHeight, color: textColor),
    );
  }
}
