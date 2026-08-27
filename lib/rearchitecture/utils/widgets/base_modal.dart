import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';

class BaseModal extends StatelessWidget {
  const BaseModal({
    required this._child, this._title,
    super.key,
  });

  final Widget _child;
  final String? _title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _title ?? '',
                  style: context.textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(
                    Icons.clear,
                  ),
                ),
              ],
            ),
            _child,
          ],
        ),
      ),
    );
  }
}
