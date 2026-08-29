import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/bloc/join_native_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/join_native_swap/view/join_native_swap_form.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Modal containing the flow used to join a native P2P swap.
class JoinNativeSwapModal extends StatelessWidget {
  /// Creates a [JoinNativeSwapModal].
  const JoinNativeSwapModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<JoinNativeSwapBloc>(
          create: (_) => JoinNativeSwapBloc(
            accountBlockUtils: AccountBlockUtils(),
            htlcSwapsService: htlcSwapsService!,
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<InitialHtlcValidationBloc>(
          create: (_) => InitialHtlcValidationBloc(
            accountBlocksAfterTimeFetcher:
                AccountBlockUtils.getAccountBlocksAfterTime,
            htlcSwapsService: htlcSwapsService!,
            walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
            zenon: zenon!,
          ),
        ),
      ],
      child: _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: context.l10n.joinSwap,
      child: BlocBuilder<InitialHtlcValidationBloc, InitialHtlcValidationState>(
        builder: (_, InitialHtlcValidationState state) => switch (state) {
          InitialHtlcValidationDone(
            :final HtlcInfo htlc,
            :final Token token,
          ) =>
            JoinNativeSwapForm(initialHtlc: htlc, token: token),
          _ => const InitialHtlcValidationForm(),
        },
      ),
    );
  }
}
