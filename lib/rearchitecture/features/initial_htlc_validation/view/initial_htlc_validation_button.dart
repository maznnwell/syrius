import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/bloc/initial_htlc_validation_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that fetches and validates an initial HTLC.
class InitialHtlcValidationButton extends StatelessWidget {
  /// Creates an [InitialHtlcValidationButton].
  const InitialHtlcValidationButton({
    required this._depositId,
    required this._isEnabled,
    required this._onValidationFailed,
    required this._onValidationStarted,
    required this._onValidated,
    super.key,
  });

  final String _depositId;
  final bool _isEnabled;
  final ValueChanged<SyriusException> _onValidationFailed;
  final VoidCallback _onValidationStarted;
  final ValueChanged<HtlcInfo> _onValidated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InitialHtlcValidationBloc>(
      create: (_) => InitialHtlcValidationBloc(
        accountBlocksAfterTimeFetcher:
            AccountBlockUtils.getAccountBlocksAfterTime,
        htlcSwapsService: htlcSwapsService!,
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
      ),
      child: _View(
        depositId: _depositId,
        isEnabled: _isEnabled,
        onValidationFailed: _onValidationFailed,
        onValidationStarted: _onValidationStarted,
        onValidated: _onValidated,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.depositId,
    required this.isEnabled,
    required this.onValidationFailed,
    required this.onValidationStarted,
    required this.onValidated,
  });

  final String depositId;
  final bool isEnabled;
  final ValueChanged<SyriusException> onValidationFailed;
  final VoidCallback onValidationStarted;
  final ValueChanged<HtlcInfo> onValidated;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      listener: (_, InitialHtlcValidationState state) {
        switch (state) {
          case InitialHtlcValidationLoading():
            onValidationStarted();
          case InitialHtlcValidationDone(:final HtlcInfo htlc):
            onValidated(htlc);
          case InitialHtlcValidationFailure(
            :final SyriusException exception,
          ):
            onValidationFailed(exception);
          case InitialHtlcValidationInitial():
            break;
        }
      },
      builder: (BuildContext context, InitialHtlcValidationState state) {
        return InstructionButton(
          text: context.l10n.continueText,
          loadingText: context.l10n.searching,
          instructionText: context.l10n.inputDepositId,
          isEnabled: isEnabled,
          isLoading: state is InitialHtlcValidationLoading,
          onPressed: () => context.read<InitialHtlcValidationBloc>().add(
            InitialHtlcValidationRequested(id: Hash.parse(depositId)),
          ),
        );
      },
    );
  }
}
