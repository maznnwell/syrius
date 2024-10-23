import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PhaseList extends StatelessWidget {

  const PhaseList(
    this.pillarInfo,
    this.project,
    this.onRefreshButtonPressed, {
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final PillarInfo? pillarInfo;
  final Project project;
  final VoidCallback onRefreshButtonPressed;
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.phaseListTitle,
      childBuilder: () => project.phases.isEmpty
          ? SyriusErrorWidget(context.l10n.projectHasNoPhases)
          : AcceleratorProjectList(
              pillarInfo,
              project.phases.reversed.toList(),
              projects: project,
              onStepperNotificationSeeMorePressed:
                  onStepperNotificationSeeMorePressed,
            ),
      onRefreshPressed: onRefreshButtonPressed,
      description: context.l10n.phaseListDescription,
    );
  }
}
