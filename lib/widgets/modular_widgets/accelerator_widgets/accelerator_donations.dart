import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class AcceleratorDonations extends StatelessWidget {

  const AcceleratorDonations({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.acceleratorDonationsTitle,
      childBuilder: () => _getWidgetBody(context),
      description: context.l10n.acceleratorThanks,
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Icon(
          MaterialCommunityIcons.ufo_outline,
          size: 75,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: Text(
                context.l10n.fuelMothership,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            SyriusElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StepperScreen(
                      stepper: const AcceleratorDonationStepper(),
                      onStepperNotificationSeeMorePressed:
                          onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              text: context.l10n.donate,
              initialFillColor: AppColors.znnColor,
              icon: SyriusElevatedButton.getFilledButtonPlusIcon(),
            ),
          ],
        ),
      ],
    );
  }
}
