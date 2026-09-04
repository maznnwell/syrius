import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/recover_htlc_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/base_modal.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
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
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
  }

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
      children: <Widget>[
        const SizedBox(
          height: 10,
        ),
        Container(
          width: 72,
          height: 72,
          color: Colors.transparent,
          child: SvgPicture.asset(
            'assets/svg/ic_completed_symbol.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.znnColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Text(
          context.l10n.recoveryTransactionSentFundsShortly,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(
          height: 30,
        ),
      ],
    );
  }

  Widget _getSearchView() {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 20,
        ),
        Text(
          context.l10n.recoverDepositedFundsWithDepositId,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            child: Row(
              children: <Widget>[
                Text(
                  context.l10n.viewSwapTutorial,
                  style: const TextStyle(
                    color: AppColors.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: AppColors.subtitleColor,
                ),
              ],
            ),
            onTap: () => NavigationUtils.openUrl(kP2pSwapTutorialLink),
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            validator: InputValidators.checkHash,
            controller: _depositIdController,
            suffixIcon: RawMaterialButton(
              shape: const CircleBorder(),
              onPressed: () => ClipboardUtils.pasteToClipboard(
                callback: (String value) {
                  _depositIdController.text = value;
                  setState(() {});
                },
              ),
              child: const Icon(
                Icons.content_paste,
                color: AppColors.darkHintTextColor,
                size: 15,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              maxWidth: 45,
              maxHeight: 20,
            ),
            hintText: context.l10n.depositId,
            contentLeftPadding: 10,
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        Visibility(
          visible: _errorText != null,
          child: Column(
            children: <Widget>[
              SwapWarning(
                text: _errorText ?? '',
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
        _getRecoverButton(),
      ],
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
      builder: (_, RecoverHtlcSwapFundsBloc model, __) => InstructionButton(
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
      InputValidators.checkHash(_depositIdController.text) == null;
}
