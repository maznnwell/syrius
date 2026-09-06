import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/recover_swap_funds/bloc/recover_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Records and displays foreground feedback for swap-fund recovery.
class RecoverSwapFundsListener extends StatelessWidget {
  /// Creates a [RecoverSwapFundsListener].
  const RecoverSwapFundsListener({
    required this._child,
    required this._successMessage,
    super.key,
  });

  final Widget _child;
  final String _successMessage;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      listener: _onStateChanged,
      child: _child,
    );
  }

  void _onStateChanged(BuildContext context, RecoverSwapFundsState state) {
    if (state case RecoverSwapFundsDone(:final block)) {
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
    } else if (state case RecoverSwapFundsFailure(:final exception)) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorReclaimingSwapFunds,
        ),
      );
    }
  }
}
