import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/metadata.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AboutCard extends StatefulWidget {
  const AboutCard({super.key});

  @override
  State createState() {
    return AboutCardState();
  }
}

class AboutCardState extends State<AboutCard> {
  GeneralStatsBloc? _generalStatsBloc;

  @override
  void initState() {
    _generalStatsBloc = GeneralStatsBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.aboutTitle,
      description: context.l10n.aboutDescription,
      childBuilder: _getStreamBuilder,
    );
  }

  Widget _getNewBody(GeneralStats generalStats) {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          context.l10n.syriusWalletVersion,
          _getGenericTextExpandedChild(kWalletVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeChainIdentifier,
          _getGenericTextExpandedChild(
              generalStats.frontierMomentum.chainIdentifier.toString(),),
        ),
        CustomExpandablePanel(
          context.l10n.clientChainIdentifier,
          _getGenericTextExpandedChild(getChainIdentifier().toString()),
        ),
        CustomExpandablePanel(
          context.l10n.zenonSdkVersion,
          _getGenericTextExpandedChild(znnSdkVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeBuildVersion,
          _getGenericTextExpandedChild(generalStats.processInfo.version),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeGitCommitHash,
          _getGenericTextExpandedChild(generalStats.processInfo.commit),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitOriginUrl,
          _getGenericLinkButtonExpandedChild(gitOriginUrl),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitBranchName,
          _getGenericTextExpandedChild(gitBranchName),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitHash,
          _getGenericTextExpandedChild(gitCommitHash),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitMessage,
          _getGenericTextExpandedChild(gitCommitMessage),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitDate,
          _getGenericTextExpandedChild(gitCommitDate),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeKernelVersion,
          _getGenericTextExpandedChild(generalStats.osInfo.kernelVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeOperatingSystem,
          _getGenericTextExpandedChild(generalStats.osInfo.os),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodePlatform,
          _getGenericTextExpandedChild(generalStats.osInfo.platform),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodePlatformVersion,
          _getGenericTextExpandedChild(generalStats.osInfo.platformVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeNumberProcessors,
          _getGenericTextExpandedChild(generalStats.osInfo.numCPU.toString()),
        ),
        CustomExpandablePanel(
          context.l10n.zenonMainDataPath,
          _getGenericOpenButtonExpandedChild(
              znnDefaultPaths.main.absolute.path,),
        ),
        CustomExpandablePanel(
          context.l10n.syriusCachePath,
          _getGenericOpenButtonExpandedChild(
              znnDefaultPaths.cache.absolute.path,),
        ),
        CustomExpandablePanel(
          context.l10n.syriusWalletPath,
          _getGenericOpenButtonExpandedChild(
              znnDefaultPaths.wallet.absolute.path,),
        ),
        CustomExpandablePanel(
          context.l10n.syriusWalletType,
          _getGenericOpenButtonExpandedChild(
              kWalletFile!.walletType,),
        ),
        CustomExpandablePanel(
          context.l10n.clientHostname,
          _getGenericTextExpandedChild(Platform.localHostname),
        ),
        CustomExpandablePanel(
          context.l10n.clientLocalIpAddress,
          _getGenericTextExpandedChild(kLocalIpAddress!),
        ),
        CustomExpandablePanel(
          context.l10n.clientOperatingSystem,
          _getGenericTextExpandedChild(Platform.operatingSystem),
        ),
        CustomExpandablePanel(
          context.l10n.clientOperatingSystemVersion,
          _getGenericTextExpandedChild(Platform.operatingSystemVersion),
        ),
        CustomExpandablePanel(
          context.l10n.clientNumberProcessors,
          _getGenericTextExpandedChild(Platform.numberOfProcessors.toString()),
        ),
      ],
    );
  }

  Widget _getGenericTextExpandedChild(String expandedText) {
    return Row(children: [
      CustomTableCell.withMarquee(
        expandedText,
      ),
    ],);
  }

  Widget _getGenericLinkButtonExpandedChild(String url) {
    return Row(children: [
      CustomTableCell.withMarquee(
        url,
      ),
      IconButton(
        splashRadius: 16,
        onPressed: () async {
          NavigationUtils.openUrl(url);
        },
        icon: const Icon(
          Icons.link,
          size: 16,
          color: AppColors.znnColor,
        ),
      ),
    ],);
  }

  Widget _getGenericOpenButtonExpandedChild(String expandedText) {
    return Row(children: [
      CustomTableCell.withMarquee(
        expandedText,
      ),
      IconButton(
        splashRadius: 16,
        onPressed: () async {
          await OpenFilex.open(expandedText);
        },
        icon: const Icon(
          Icons.open_in_new,
          size: 16,
          color: AppColors.znnColor,
        ),
      ),
    ],);
  }

  Widget _getStreamBuilder() {
    return StreamBuilder<GeneralStats>(
      stream: _generalStatsBloc!.stream,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return _getNewBody(snapshot.data!);
        } else if (snapshot.hasError) {
          return SyriusErrorWidget(
            snapshot.error.toString(),
          );
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  @override
  void dispose() {
    _generalStatsBloc!.dispose();
    super.dispose();
  }
}
