import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_options/widgets/view_swap_tutorial_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/recover_swap_funds/bloc/recover_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/recover_swap_funds/widgets/recover_swap_funds_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/swap_warning.dart';

/// Modal containing the flow used to recover funds from an expired swap.
class RecoverDepositModal extends StatelessWidget {
  /// Creates a [RecoverDepositModal].
  const RecoverDepositModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecoverSwapFundsBloc>(
      create: (_) => RecoverSwapFundsBloc(
        accountBlockUtils: AccountBlockUtils(),
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _depositIdController = TextEditingController();

  @override
  void dispose() {
    _depositIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecoverSwapFundsBloc, RecoverSwapFundsState>(
      builder: (_, RecoverSwapFundsState state) => BaseModal(
        title: state is RecoverSwapFundsDone
            ? null
            : context.l10n.recoverDeposit,
        child: state is RecoverSwapFundsDone
            ? _buildPendingFundsView()
            : _buildSearchView(state),
      ),
    );
  }

  Widget _buildPendingFundsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_completed_symbol.svg',
          colorFilter: const ColorFilter.mode(
            AppColors.znnColor,
            BlendMode.srcIn,
          ),
          height: 70,
        ),
        Text(
          context.l10n.recoveryTransactionSentFundsShortly,
          style: context.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchView(RecoverSwapFundsState state) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _depositIdController,
      builder: (_, TextEditingValue value, _) {
        final String? depositIdError = InputValidators.checkHash(value.text);

        return Column(
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            Text(
              context.l10n.recoverDepositedFundsWithDepositId,
            ),
            const ViewSwapTutorialButton(),
            TextField(
              decoration: InputDecoration(
                errorText: value.text.isNotEmpty ? depositIdError : null,
                hintText: context.l10n.depositId,
                suffixIcon: FieldSuffixButtons(
                  controller: _depositIdController,
                ),
              ),
              controller: _depositIdController,
            ),
            if (state case RecoverSwapFundsFailure(
              :final SyriusException exception,
            ))
              SwapWarning(
                text: exception.toString(),
              ),
            RecoverSwapFundsButton(
              htlcId: value.text,
              isEnabled: depositIdError == null && value.text.isNotEmpty,
              text: context.l10n.recoverDeposit,
              loadingText: context.l10n.sendingTransaction,
              instructionText: context.l10n.inputDepositId,
            ),
          ],
        );
      },
    );
  }
}
