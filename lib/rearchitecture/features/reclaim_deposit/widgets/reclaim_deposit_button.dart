import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/recover_swap_funds/bloc/recover_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that recovers funds from an expired HTLC.
class RecoverSwapFundsButton extends StatelessWidget {
  /// Creates a [RecoverSwapFundsButton].
  const RecoverSwapFundsButton({
    required this._htlcId,
    required this._isEnabled,
    required this._loadingText,
    required this._text,
    this._instructionText,
    super.key,
  });

  final String _htlcId;
  final bool _isEnabled;
  final String _loadingText;
  final String _text;
  final String? _instructionText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      builder: (_, RecoverSwapFundsState state) => InstructionButton(
        text: _text,
        isEnabled: _isEnabled,
        isLoading: state is RecoverSwapFundsLoading,
        loadingText: _loadingText,
        instructionText: _instructionText,
        onPressed: () => context.read<RecoverSwapFundsBloc>().add(
          RecoverSwapFundsRequested(htlcId: Hash.parse(_htlcId)),
        ),
      ),
    );
  }
}
