import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this._swap,
    required this._onDelete,
    super.key,
  });

  final P2pSwap _swap;
  final Function(P2pSwap) _onDelete;

  @override
  Widget build(BuildContext context) {
    final Widget deleteButton = OutlinedButton.icon(
      onPressed: () => _onDelete.call(_swap),
      icon: const Icon(
        Icons.delete,
      ),
      label: Text(context.l10n.deleteSwap),
    );

    return SizedBox(
      height: 36,
      child: switch (_swap.state) {
        P2pSwapState.completed => deleteButton,
        _ => const SizedBox.shrink(),
      },
    );
  }
}
