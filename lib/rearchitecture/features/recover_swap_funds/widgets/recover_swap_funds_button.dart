import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/recover_swap_funds/bloc/recover_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that recovers funds from an expired HTLC.
class RecoverSwapFundsButton extends StatelessWidget {
  /// Creates a [RecoverSwapFundsButton].
  const RecoverSwapFundsButton({
    required this._depositId,
    required this._isEnabled,
    required this._isLoading,
    super.key,
  });

  final String _depositId;
  final bool _isEnabled;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    return InstructionButton(
      text: context.l10n.recoverDeposit,
      isEnabled: _isEnabled,
      isLoading: _isLoading,
      loadingText: context.l10n.sendingTransaction,
      instructionText: context.l10n.inputDepositId,
      onPressed: () => context.read<RecoverSwapFundsBloc>().add(
        RecoverSwapFundsRequested(htlcId: Hash.parse(_depositId)),
      ),
    );
  }
}
