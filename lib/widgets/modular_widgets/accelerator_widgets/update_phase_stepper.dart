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

enum UpdatePhaseStep {
  phaseDetails,
  updatePhase,
}

class UpdatePhaseStepper extends StatefulWidget {

  const UpdatePhaseStepper(
    this.phase,
    this.project, {
    super.key,
  });
  final Phase phase;
  final Project project;

  @override
  State<UpdatePhaseStepper> createState() => _UpdatePhaseStepperState();
}

class _UpdatePhaseStepperState extends State<UpdatePhaseStepper> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phaseNameController = TextEditingController();
  final TextEditingController _phaseDescriptionController =
      TextEditingController();
  final TextEditingController _phaseUrlController = TextEditingController();
  final TextEditingController _phaseZnnAmountController =
      TextEditingController();
  final TextEditingController _phaseQsrAmountController =
      TextEditingController();

  final GlobalKey<FormState> _phaseNameKey = GlobalKey();
  final GlobalKey<FormState> _phaseDescriptionKey = GlobalKey();
  final GlobalKey<FormState> _phaseUrlKey = GlobalKey();
  final GlobalKey<FormState> _phaseZnnAmountKey = GlobalKey();
  final GlobalKey<FormState> _phaseQsrAmountKey = GlobalKey();

  UpdatePhaseStep? _lastCompletedStep;

  UpdatePhaseStep _currentStep = UpdatePhaseStep.values.first;

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    _phaseNameController.text = widget.phase.name;
    _phaseDescriptionController.text = widget.phase.description;
    _phaseUrlController.text = widget.phase.url;
    _phaseZnnAmountController.text =
        widget.phase.znnFundsNeeded.addDecimals(coinDecimals);
    _phaseQsrAmountController.text =
        widget.phase.qsrFundsNeeded.addDecimals(coinDecimals);
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
          visible: _lastCompletedStep == UpdatePhaseStep.updatePhase,
          child: Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepperButton(
                  text: context.l10n.viewPhases,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == UpdatePhaseStep.updatePhase,
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
            stepTitle: context.l10n.phaseDetails,
            stepContent: _getPhaseDetailsStepContent(accountInfo),
            stepSubtitle: '${_phaseNameController.text} ● '
                '${_phaseZnnAmountController.text} ${kZnnCoin.symbol} ● '
                '${_phaseQsrAmountController.text} ${kQsrCoin.symbol}',
            stepState: _getStepState(UpdatePhaseStep.phaseDetails),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.updatePhase,
            stepContent: _getUpdatePhaseStepContent(),
            stepSubtitle: 'ID ${widget.phase.id.toShortString()}',
            stepState: _getStepState(UpdatePhaseStep.updatePhase),
            context: context,
          ),
        ],
      ),
    );
  }

  custom_material_stepper.StepState _getStepState(UpdatePhaseStep step) {
    final stepIndex = step.index;
    return stepIndex <= (_lastCompletedStep?.index ?? -1)
        ? custom_material_stepper.StepState.complete
        : custom_material_stepper.StepState.indexed;
  }

  Widget _getPhaseDetailsStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${context.l10n.phaseBelongsToProjectID}'
                '${widget.phase.id.toShortString()}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Form(
          key: _phaseNameKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseNameController,
            hintText: context.l10n.phaseName,
            onChanged: (value) {
              setState(() {});
            },
            validator: Validations.projectName,
          ),
        ),
        kVerticalSpacing,
        Form(
          key: _phaseDescriptionKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseDescriptionController,
            hintText: context.l10n.phaseDescription,
            onChanged: (value) {
              setState(() {});
            },
            validator: Validations.projectDescription,
          ),
        ),
        kVerticalSpacing,
        Form(
          key: _phaseUrlKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseUrlController,
            hintText: context.l10n.phaseURL,
            onChanged: (value) {
              setState(() {});
            },
            validator: InputValidators.checkUrl,
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.totalPhaseBudget,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        Form(
          key: _phaseZnnAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseZnnAmountController,
            hintText: context.l10n.znnAmount,
            suffixIcon: AmountSuffixWidgets(
              kZnnCoin,
              onMaxPressed: () {
                setState(() {
                  _phaseZnnAmountController.text = widget.project
                      .getRemainingZnnFunds()
                      .addDecimals(coinDecimals);
                });
              },
            ),
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _phaseZnnAmountController.text,
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              widget.project.getRemainingZnnFunds(),
              kZnnCoin.decimals,
              BigInt.zero,
              canBeEqualToMin: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        Form(
          key: _phaseQsrAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseQsrAmountController,
            hintText: context.l10n.qsrAmount,
            suffixIcon: AmountSuffixWidgets(
              kQsrCoin,
              onMaxPressed: () {
                setState(() {
                  _phaseQsrAmountController.text = widget.project
                      .getRemainingQsrFunds()
                      .addDecimals(coinDecimals);
                });
              },
            ),
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _phaseQsrAmountController.text,
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              widget.project.getRemainingQsrFunds(),
              kQsrCoin.decimals,
              BigInt.zero,
              canBeEqualToMin: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              text: context.l10n.cancelKey,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 15,
            ),
            StepperButton(
              text: context.l10n.continueKey,
              onPressed: _areInputDetailsValid()
                  ? () {
                      setState(() {
                        _lastCompletedStep = UpdatePhaseStep.phaseDetails;
                        _currentStep = UpdatePhaseStep.updatePhase;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getUpdatePhaseStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         DottedBorderInfoWidget(
          text: context.l10n.updatePhaseVoteReset,
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = UpdatePhaseStep.phaseDetails;
                  _lastCompletedStep = null;
                });
              },
              text: context.l10n.goBackKey,
            ),
            const SizedBox(
              width: 15,
            ),
            _getUpdatePhaseViewModel(),
          ],
        ),
      ],
    );
  }

  StepperButton _getUpdatePhaseButton(UpdatePhaseBloc model) {
    return StepperButton(
      onPressed: () {
        model.updatePhase(
          widget.project.id,
          _phaseNameController.text,
          _phaseDescriptionController.text,
          _phaseUrlController.text,
          _phaseZnnAmountController.text.extractDecimals(coinDecimals),
          _phaseQsrAmountController.text.extractDecimals(coinDecimals),
        );
      },
      text: context.l10n.updatePhase,
    );
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(_phaseNameController.text) == null &&
      Validations.projectDescription(_phaseDescriptionController.text) ==
          null &&
      InputValidators.checkUrl(_phaseUrlController.text) == null &&
      InputValidators.correctValue(
            _phaseZnnAmountController.text,
            widget.project.getRemainingZnnFunds(),
            kZnnCoin.decimals,
            BigInt.zero,
            canBeEqualToMin: true,
          ) ==
          null &&
      InputValidators.correctValue(
            _phaseQsrAmountController.text,
            widget.project.getRemainingQsrFunds(),
            kQsrCoin.decimals,
            BigInt.zero,
            canBeEqualToMin: true,
          ) ==
          null;

  Widget _getUpdatePhaseViewModel() {
    return ViewModelBuilder<UpdatePhaseBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              setState(() {
                _lastCompletedStep = UpdatePhaseStep.updatePhase;
              });
            }
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.updatePhaseError,
            );
          },
        );
      },
      builder: (_, model, __) => StreamBuilder<AccountBlockTemplate?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return _getUpdatePhaseButton(model);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getUpdatePhaseButton(model);
            }
            return const SyriusLoadingWidget();
          }
          return _getUpdatePhaseButton(model);
        },
      ),
      viewModelBuilder: UpdatePhaseBloc.new,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phaseNameController.dispose();
    _phaseDescriptionController.dispose();
    _phaseUrlController.dispose();
    _phaseZnnAmountController.dispose();
    _phaseQsrAmountController.dispose();
    super.dispose();
  }
}
