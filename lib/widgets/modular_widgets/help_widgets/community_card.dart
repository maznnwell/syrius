import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.communityTitle,
      description: context.l10n.communityDescription,
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          context.l10n.communityWebsites,
          _getWebsitesExpandableChild(context),
        ),
        CustomExpandablePanel(
          context.l10n.communityExplorers,
          _getExplorersExpandableChild(context),
        ),
        CustomExpandablePanel(
          context.l10n.communitySocialMedia,
          _getSocialMediaExpandableChild(context),
        ),
        CustomExpandablePanel(
          context.l10n.communityDocumentation,
          _getDocumentationExpandableChild(context),
        ),
      ],
    );
  }

  Widget _getWebsitesExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.home,
          title: context.l10n.zenonNetwork,
          url: kWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.forum,
          title: context.l10n.zenonOrgForum,
          url: kOrgCommunityForum,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.tools,
          title: context.l10n.zenonTools,
          url: kTools,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.web,
          title: context.l10n.zenonOrgCommunity,
          url: kOrgCommunityWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.lan,
          title: context.l10n.zenonHub,
          url: kHubCommunityWebsite,
          context: context,
        ),
      ],
    );
  }

  Widget _getExplorersExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: Icons.explore,
          title: context.l10n.zenonExplorer,
          url: kExplorer,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.explore_off_outlined,
          title: context.l10n.zenonHubExplorer,
          url: kHubCommunityExplorer,
          context: context,
        ),
      ],
    );
  }

  Widget _getSocialMediaExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.twitter,
          title: context.l10n.zenonTwitter,
          url: kTwitter,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.discord,
          title: context.l10n.zenonDiscord,
          url: kDiscord,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.telegram,
          title: context.l10n.zenonTelegram,
          url: kTelegram,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.article,
          title: context.l10n.zenonMedium,
          url: kMedium,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.github,
          title: context.l10n.zenonGithub,
          url: kGithub,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.bitcoin,
          title: context.l10n.zenonBitcoinTalk,
          url: kBitcoinTalk,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.reddit,
          title: context.l10n.zenonReddit,
          url: kReddit,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.youtube,
          title: context.l10n.zenonYoutube,
          url: kYoutube,
          context: context,
        ),
      ],
    );
  }

  Widget _getDocumentationExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.book_open_page_variant,
          title: context.l10n.zenonWiki,
          url: kWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.book_multiple,
          title: context.l10n.zenonCommunityWiki,
          url: kOrgCommunityWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.file_document,
          title: context.l10n.zenonWhitepaper,
          url: kWhitepaper,
          context: context,
        ),
      ],
    );
  }

  Widget _getListViewChild({
    required IconData iconData,
    required String title,
    required String url,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(
          iconData,
          color: AppColors.znnColor,
          size: 20,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(
          width: 10,
        ),
        LinkIcon(url: url),
      ],
    );
  }
}
