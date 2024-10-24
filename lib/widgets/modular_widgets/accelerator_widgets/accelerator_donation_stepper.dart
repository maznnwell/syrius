import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum AcceleratorDonationStep {
  donationAddress,
  donationDetails,
  submitDonation,
}

class AcceleratorDonationStepper extends StatefulWidget {
  const AcceleratorDonationStepper({super.key});

  @override
  State<AcceleratorDonationStepper> createState() =>
      _AcceleratorDonationStepperState();
}

class _AcceleratorDonationStepperState
    extends State<AcceleratorDonationStepper> {
  AcceleratorDonationStep? _lastCompletedStep;
  AcceleratorDonationStep _currentStep = AcceleratorDonationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _qsrAmountController = TextEditingController();

  final GlobalKey<FormState> _znnAmountKey = GlobalKey();
  final GlobalKey<FormState> _qsrAmountKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _submitButtonKey = GlobalKey();

  BigInt _znnAmount = BigInt.zero;
  BigInt _qsrAmount = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<BalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getWidgetBody(
              context,
              snapshot.data![_addressController.text]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == AcceleratorDonationStep.values.last,
          child: Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepperButton.icon(
                  label: context.l10n.makeAnotherDonation,
                  onPressed: () {
                    setState(() {
                      _currentStep = AcceleratorDonationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                ),
                const SizedBox(
                  width: 75,
                ),
                StepperButton(
                  text: context.l10n.returnToProjects,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == AcceleratorDonationStep.values.last,
          child: Positioned(
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/ic_anim_zts.json',
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMaterialStepper(BuildContext context, AccountInfo accountInfo) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: [
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.donationAddress,
            stepContent: _getDonationAddressStepContent(context, accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.donationAddress.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.donationDetails,
            stepContent: _getDonationDetailsStepContent(context, accountInfo),
            stepSubtitle: _getDonationDetailsStepSubtitle(),
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.donationDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.submitDonation,
            stepContent: _getSubmitDonationStepContent(context),
            stepSubtitle: context.l10n.donationSubmitted,
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.submitDonation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  String _getDonationDetailsStepSubtitle() {
    final znnPrefix = _znnAmountController.text.isNotEmpty
        ? '${_znnAmountController.text} ${kZnnCoin.symbol}'
        : '';
    final qsrSuffix = _qsrAmountController.text.isNotEmpty
        ? '${_qsrAmountController.text} ${kQsrCoin.symbol}'
        : '';
    final splitter = znnPrefix.isNotEmpty && qsrSuffix.isNotEmpty ? ' ● ' : '';

    return znnPrefix + splitter + qsrSuffix;
  }

  Widget _getDonationAddressStepContent(BuildContext context,
      AccountInfo accountInfo,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisabledAddressField(_addressController),
        Row(children: [
          StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
          StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
        ],),
        DottedBorderInfoWidget(
          text: context.l10n.donatedFundsAddress,
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: context.l10n.cancel,
            ),
            const SizedBox(
              width: 15,
            ),
            StepperButton(
              onPressed: accountInfo.znn()! > BigInt.zero ||
                      accountInfo.qsr()! > BigInt.zero
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            AcceleratorDonationStep.donationAddress;
                        _currentStep = AcceleratorDonationStep.donationDetails;
                      });
                    }
                  : null,
              text: context.l10n.continueKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getDonationDetailsStepContent(BuildContext context,
      AccountInfo accountInfo,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.totalDonationBudget),
            StandardTooltipIcon(
              context.l10n.yourDonationMatters,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Form(
          key: _znnAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: context.l10n.znnAmount,
            controller: _znnAmountController,
            suffixIcon: AmountSuffixWidgets(
              kZnnCoin,
              onMaxPressed: () {
                final maxZnn = accountInfo.getBalance(
                  kZnnCoin.tokenStandard,
                );
                if (_znnAmountController.text.isEmpty ||
                    _znnAmountController.text.extractDecimals(coinDecimals) <
                        maxZnn) {
                  setState(() {
                    _znnAmountController.text =
                        maxZnn.addDecimals(coinDecimals);
                  });
                }
              },
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              accountInfo.znn()!,
              coinDecimals,
              BigInt.zero,
              canBeEqualToMin: true,
              canBeBlank: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _znnAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        Form(
          key: _qsrAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: context.l10n.qsrAmount,
            controller: _qsrAmountController,
            suffixIcon: AmountSuffixWidgets(
              kQsrCoin,
              onMaxPressed: () {
                final maxQsr = accountInfo.getBalance(
                  kQsrCoin.tokenStandard,
                );
                if (_qsrAmountController.text.isEmpty ||
                    _qsrAmountController.text.extractDecimals(coinDecimals) <
                        maxQsr) {
                  setState(() {
                    _qsrAmountController.text =
                        maxQsr.addDecimals(coinDecimals);
                  });
                }
              },
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              accountInfo.qsr()!,
              coinDecimals,
              BigInt.zero,
              canBeEqualToMin: true,
              canBeBlank: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _qsrAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
        Row(
          children: [
            StepperButton(
              text: context.l10n.cancel,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 15,
            ),
            StepperButton(
              text: context.l10n.continueKey,
              onPressed: _ifInputValid(accountInfo)
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            AcceleratorDonationStep.donationDetails;
                        _currentStep = AcceleratorDonationStep.submitDonation;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  bool _ifInputValid(AccountInfo accountInfo) {
    try {
      _znnAmount = _znnAmountController.text.isNotEmpty
          ? _znnAmountController.text.extractDecimals(coinDecimals)
          : BigInt.zero;
      _qsrAmount = _qsrAmountController.text.isNotEmpty
          ? _qsrAmountController.text.extractDecimals(coinDecimals)
          : BigInt.zero;
    } catch (_) {}

    return InputValidators.correctValue(
                  _znnAmountController.text,
                  accountInfo.znn()!,
                  coinDecimals,
                  BigInt.zero,
                  canBeEqualToMin: true,
                  canBeBlank: true,
                ) ==
                null &&
            InputValidators.correctValue(
                  _qsrAmountController.text,
                  accountInfo.qsr()!,
                  coinDecimals,
                  BigInt.zero,
                  canBeEqualToMin: true,
                  canBeBlank: true,
                ) ==
                null &&
            (_znnAmountController.text.isNotEmpty &&
                _qsrAmountController.text.isNotEmpty &&
                _znnAmount > BigInt.zero &&
                _znnAmount <= accountInfo.znn()! &&
                _qsrAmount > BigInt.zero &&
                _qsrAmount <= accountInfo.qsr()!) ||
        (_znnAmountController.text.isNotEmpty &&
            _qsrAmountController.text.isEmpty &&
            _znnAmount > BigInt.zero &&
            _znnAmount <= accountInfo.znn()!) ||
        (_znnAmountController.text.isEmpty &&
            !_qsrAmountController.text.isNotEmpty &&
            _qsrAmount > BigInt.zero &&
            _qsrAmount <= accountInfo.qsr()!);
  }

  Widget _getSubmitDonationStepContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DottedBorderInfoWidget(
          text: context.l10n.acceleratorThanks,
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = AcceleratorDonationStep.donationDetails;
                  _lastCompletedStep = AcceleratorDonationStep.donationAddress;
                });
              },
              text: context.l10n.goBack,
            ),
            const SizedBox(
              width: 15,
            ),
            _getSubmitDonationViewModel(context),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitDonationButton(BuildContext context,
      SubmitDonationBloc model) {
    return LoadingButton.stepper(
      onPressed: () {
        _submitButtonKey.currentState?.animateForward();
        model.submitDonation(
          _znnAmount,
          _qsrAmount,
        );
      },
      text: context.l10n.submit,
      key: _submitButtonKey,
    );
  }

  Widget _getSubmitDonationViewModel(BuildContext context) {
    return ViewModelBuilder<SubmitDonationBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _submitButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = AcceleratorDonationStep.values.last;
              });
            }
          },
          onError: (error) async {
            _submitButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.donationError,
            );
          },
        );
      },
      builder: (_, model, __) => _getSubmitDonationButton(context, model),
      viewModelBuilder: SubmitDonationBloc.new,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _znnAmountController.dispose();
    _qsrAmountController.dispose();
    super.dispose();
  }
}
