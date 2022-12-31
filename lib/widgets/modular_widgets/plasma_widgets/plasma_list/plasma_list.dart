import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaList extends StatefulWidget {
  final String? errorText;
  final PlasmaListBloc bloc;

  const PlasmaList({required this.bloc, this.errorText, Key? key})
      : super(key: key);

  @override
  State createState() {
    return _PlasmaListState();
  }
}

class _PlasmaListState extends State<PlasmaList> {
  final List<FusionEntry>? _stakingList = [];

  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Plasma List',
      description: 'This card displays all your addresses that have Plasma '
          'generated by fusing ${kQsrCoin.symbol}',
      childBuilder: () => widget.errorText != null
          ? SyriusErrorWidget(widget.errorText!)
          : _getTable(widget.bloc),
      onRefreshPressed: widget.bloc.refreshResults,
    );
  }

  Widget _getTable(PlasmaListBloc bloc) {
    return InfiniteScrollTable<FusionEntry>(
      disposeBloc: false,
      bloc: bloc,
      headerColumns: [
        InfiniteScrollTableHeaderColumn(
          columnName: 'Amount',
          onSortArrowsPressed: _onSortArrowsPressed,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Beneficiary',
          onSortArrowsPressed: _onSortArrowsPressed,
          flex: 3,
        ),
        const InfiniteScrollTableHeaderColumn(
          columnName: 'Expiration',
        ),
      ],
      generateRowCells: (plasmaItem, bool isSelected) {
        return [
          InfiniteScrollTableCell(
            FormattedAmountWithTooltip(
              amount: plasmaItem.qsrAmount.addDecimals(
                kQsrCoin.decimals,
              ),
              tokenSymbol: kQsrCoin.symbol,
              builder: (formattedAmount, tokenSymbol) => Text(
                '$formattedAmount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: AppColors.subtitleColor,
                    ),
              ),
            ),
          ),
          InfiniteScrollTableCell.tooltipWithText(
            context,
            plasmaItem.beneficiary,
            flex: 3,
            showCopyToClipboardIcon: isSelected ? true : false,
          ),
          InfiniteScrollTableCell(
            _getCancelContainer(isSelected, plasmaItem, bloc),
          ),
        ];
      },
    );
  }

  Widget _getCancelContainer(
    bool isSelected,
    FusionEntry plasmaItem,
    PlasmaListBloc plasmaModel,
  ) {
    return Stack(
      alignment: Alignment.centerLeft,
      fit: StackFit.loose,
      children: [
        plasmaItem.isRevocable!
            ? _getCancelButtonViewModel(plasmaModel, isSelected, plasmaItem)
            : _getCancelCountdownTimer(plasmaItem, plasmaModel)
      ],
    );
  }

  Widget _getCancelButtonViewModel(
    PlasmaListBloc plasmaModel,
    bool isSelected,
    FusionEntry plasmaItem,
  ) {
    final GlobalKey<LoadingButtonState> cancelButtonKey = GlobalKey();

    return ViewModelBuilder<CancelPlasmaBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              cancelButtonKey.currentState?.animateReverse();
              plasmaModel.refreshResults();
            }
          },
          onError: (error) {
            cancelButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
                error, 'Error while cancelling plasma');
          },
        );
      },
      builder: (_, model, __) => _getCancelButton(
        model,
        plasmaItem.id.toString(),
        cancelButtonKey,
      ),
      viewModelBuilder: () => CancelPlasmaBloc(),
    );
  }

  Widget _getCancelButton(
    CancelPlasmaBloc model,
    String plasmaItemId,
    GlobalKey<LoadingButtonState> key,
  ) {
    return LoadingButton.infiniteScrollTableWithIcon(
      onPressed: () {
        key.currentState?.animateForward();
        _onCancelPressed(model, plasmaItemId);
      },
      text: 'CANCEL',
      key: key,
      icon: const Icon(
        SimpleLineIcons.close,
        size: 11.0,
        color: AppColors.errorColor,
      ),
      outlineColor: AppColors.errorColor,
      textStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
            color: Theme.of(context).textTheme.bodyText1!.color,
          ),
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Amount':
        _sortAscending
            ? _stakingList!.sort((a, b) => a.qsrAmount.compareTo(b.qsrAmount))
            : _stakingList!.sort((a, b) => b.qsrAmount.compareTo(a.qsrAmount));
        break;
      case 'Beneficiary':
        _sortAscending
            ? _stakingList!
                .sort((a, b) => a.beneficiary.compareTo(b.beneficiary))
            : _stakingList!
                .sort((a, b) => b.beneficiary.compareTo(a.beneficiary));
        break;
      default:
        _sortAscending
            ? _stakingList!
                .sort((a, b) => a.beneficiary.compareTo(b.beneficiary))
            : _stakingList!
                .sort((a, b) => b.beneficiary.compareTo(a.beneficiary));
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  void _onCancelPressed(CancelPlasmaBloc model, String id) {
    model.cancelPlasmaStaking(id, context);
  }

  Widget _getCancelCountdownTimer(
    FusionEntry plasmaItem,
    PlasmaListBloc model,
  ) {
    int heightUntilCancellation =
        plasmaItem.expirationHeight - model.lastMomentumHeight!;

    Duration durationUntilCancellation =
        kIntervalBetweenMomentums * heightUntilCancellation;

    if (plasmaItem.isRevocable!) {
      return Tooltip(
        message: 'Revocation window is open',
        child: CancelTimer(
          durationUntilCancellation,
          AppColors.znnColor,
          onTimeFinishedCallback: () {
            model.refreshResults();
          },
        ),
      );
    }
    return Tooltip(
      message: 'Until revocation window opens',
      child: CancelTimer(
        durationUntilCancellation,
        AppColors.errorColor,
        onTimeFinishedCallback: () {
          model.refreshResults();
        },
      ),
    );
  }
}
