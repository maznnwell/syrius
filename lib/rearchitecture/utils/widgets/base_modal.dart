import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';

class BaseModal extends StatelessWidget {

  const BaseModal({
    required this._title, required this._child, super.key,
  });
  final String _title;
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      _title,
                      style: context.textTheme.titleLarge,
                    ),
                  ],
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
