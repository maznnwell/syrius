import 'dart:async';

import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swaps_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class P2pSwapTabChild extends StatefulWidget {
  const P2pSwapTabChild({
    required this._onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  State createState() => _P2pSwapTabChildState();
}

class _P2pSwapTabChildState extends State<P2pSwapTabChild> {
  @override
  void initState() {
    super.initState();
    unawaited(NodeUtils.checkForLocalTimeDiscrepancy(
      '''Local time discrepancy detected. Please confirm your operating '''
      '''system's time is correct before conducting P2P swaps.''',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildLayout(context);
  }

  StandardFluidLayout _buildLayout(BuildContext context) {
    return StandardFluidLayout(
      children: <FluidCell>[
        FluidCell(
          height: kStaggeredNumOfColumns / 2,
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const P2pSwapOptionsCard(),
        ),
        FluidCell(
          height: kStaggeredNumOfColumns / 2,
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 1.5,
            lg: kStaggeredNumOfColumns ~/ 1.5,
            md: kStaggeredNumOfColumns ~/ 1.5,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: Consumer<SelectedAddressNotifier>(
            builder: (_, _, _) => P2pSwapsCard(
              onStepperNotificationSeeMorePressed:
                  widget._onStepperNotificationSeeMorePressed,
            ),
          ),
        ),
      ],
    );
  }
}
