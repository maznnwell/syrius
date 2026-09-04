import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/recover_htlc_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/swap_warning.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RecoverDepositModal extends StatefulWidget {
  const RecoverDepositModal({
    super.key,
  });

  @override
  State<RecoverDepositModal> createState() => _RecoverDepositModalState();
}

class _RecoverDepositModalState extends State<RecoverDepositModal> {
  final TextEditingController _depositIdController = TextEditingController();

  String? _errorText;

  bool _isLoading = false;
  bool _isPendingFunds = false;

  @override
  void dispose() {
    _depositIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: _getTitle(),
      child: _getContent(),
    );
  }

  String? _getTitle() {
    return _isPendingFunds ? null : context.l10n.recoverDeposit;
  }

  Widget _getContent() {
    return _isPendingFunds ? _getPendingFundsView() : _getSearchView();
  }

  Widget _getPendingFundsView() {
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

  Widget _getSearchView() {
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
                    controller: _depositIdController),
              ),
              controller: _depositIdController,
            ),
            if (_errorText != null)
              SwapWarning(
                text: _errorText ?? '',
              ),
            _getRecoverButton(),
          ],
        );
      },
    );
  }

  Widget _getRecoverButton() {
    return ViewModelBuilder<RecoverHtlcSwapFundsBloc>.reactive(
      onViewModelReady: (RecoverHtlcSwapFundsBloc model) {
        model.stream.listen(
              (AccountBlockTemplate? event) async {
            if (event is AccountBlockTemplate) {
              setState(() {
                _isPendingFunds = true;
              });
            }
          },
          onError: (error) {
            setState(() {
              _errorText = error.toString();
              _isLoading = false;
            });
          },
        );
      },
      builder: (_, RecoverHtlcSwapFundsBloc model, _) =>
          InstructionButton(
            text: context.l10n.recoverDeposit,
            isEnabled: _isHashValid(),
            isLoading: _isLoading,
            loadingText: context.l10n.sendingTransaction,
            instructionText: context.l10n.inputDepositId,
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorText = null;
              });
              model.recoverFunds(htlcId: Hash.parse(_depositIdController.text));
            },
          ),
      viewModelBuilder: RecoverHtlcSwapFundsBloc.new,
    );
  }

  bool _isHashValid() =>
      _depositIdController.text.isNotEmpty &&
          InputValidators.checkHash(_depositIdController.text) == null;
}
