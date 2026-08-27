import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/view/join_native_swap_form.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Modal containing the flow used to join a native P2P swap.
class JoinNativeSwapModal extends StatelessWidget {
  /// Creates a [JoinNativeSwapModal].
  const JoinNativeSwapModal({
    required this.onJoinedSwap,
    super.key,
  });

  /// Called with the identifier of the successfully joined swap.
  final ValueChanged<String> onJoinedSwap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InitialHtlcValidationBloc>(
      create: (_) => InitialHtlcValidationBloc(
        accountBlocksAfterTimeFetcher:
            AccountBlockUtils.getAccountBlocksAfterTime,
        htlcSwapsService: htlcSwapsService!,
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
      ),
      child: _View(onJoinedSwap: onJoinedSwap),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.onJoinedSwap});

  final ValueChanged<String> onJoinedSwap;

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: context.l10n.joinSwap,
      child: BlocBuilder<InitialHtlcValidationBloc, InitialHtlcValidationState>(
        builder: (_, InitialHtlcValidationState state) => switch (state) {
          InitialHtlcValidationDone(:final HtlcInfo htlc) => JoinNativeSwapForm(
            initialHtlc: htlc,
            onJoinedSwap: onJoinedSwap,
          ),
          _ => const InitialHtlcValidationForm(),
        },
      ),
    );
  }
}
