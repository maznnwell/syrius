import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.update,
      description: context.l10n.updateDescrition,
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          context.l10n.updateCheck,
          _getCheckUpdateExpandableChild(context),
        ),
      ],
    );
  }

  Widget _getCheckUpdateExpandableChild(BuildContext context) {
    return Center(
      child: SettingsButton(
        onPressed: () => NavigationUtils.openUrl(kGithubReleasesLink),
        text: context.l10n.update,
      ),
    );
  }
}
