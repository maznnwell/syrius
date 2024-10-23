import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CreateProject extends StatelessWidget {

  const CreateProject({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.createProjectTitle,
      childBuilder: () => _getWidgetBody(context),
      description: context.l10n.createProjectDescription,
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Icon(
          MaterialCommunityIcons.alien,
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
                context.l10n.createProjectDescriptionTooltip,
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
                      stepper: const ProjectCreationStepper(),
                      onStepperNotificationSeeMorePressed:
                          onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              text: context.l10n.createProjectButton,
              initialFillColor: AppColors.znnColor,
              icon: SyriusElevatedButton.getFilledButtonPlusIcon(),
            ),
          ],
        ),
      ],
    );
  }
}
