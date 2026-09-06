import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reclaim_deposit/bloc/reclaim_deposit_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays foreground feedback for a deposit reclaim.
class ReclaimDepositListener extends StatelessWidget {
  /// Creates a [ReclaimDepositListener].
  const ReclaimDepositListener({
    required this._child,
    required this._successMessage,
    super.key,
  });

  final Widget _child;
  final String _successMessage;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReclaimDepositBloc, ReclaimDepositState>(
      listener: _onStateChanged,
      child: _child,
    );
  }

  void _onStateChanged(BuildContext context, ReclaimDepositState state) {
    if (state case ReclaimDepositDone(:final AccountBlockTemplate block)) {
      unawaited(
        NotificationUtils.showForegroundNotification(
          context,
          WalletNotification(
            title: _successMessage,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: context.l10n.hashValue(block.hash.toString()),
            type: NotificationType.paymentSent,
          ),
        ),
      );
    } else if (state case ReclaimDepositFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorReclaimingDeposit,
        ),
      );
    }
  }
}
