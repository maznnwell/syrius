import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A `BalanceCard` widget that displays balance information for a user.
///
/// The widget uses a `BalanceCubit` to fetch and manage account balance data
/// and presents the state in different views based on the current status
/// (e.g., loading, success, failure).
class BalanceCard extends StatelessWidget {
  /// Constructs a `BalanceCard` widget.
  ///
  /// The widget is a stateless widget and expects a `BalanceCubit` to be
  /// provided via a `BlocProvider`.
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = BalanceCubit(
          Address.parse(kSelectedAddress!),
          zenon!,
          const BalanceState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.balance.getData(context: context),
        body: BlocBuilder<BalanceCubit, BalanceState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const BalanceEmpty(),
              CubitStatus.loading => const BalanceLoading(),
              CubitStatus.failure => BalanceError(
                  error: state.error!,
                ),
              CubitStatus.success => BalancePopulated(
                  address: kSelectedAddress!,
                  accountInfo: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
