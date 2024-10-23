import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [CubitStatus.success] that displays the current number of sentinels
class SentinelsPopulated extends StatelessWidget {

  const SentinelsPopulated({required this.sentinelInfoList, super.key});
  final SentinelInfoList sentinelInfoList;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/svg/ic_sentinels_dashboard.svg',
            width: 42,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: sentinelInfoList.count,
              isInt: true,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Active Sentinels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}