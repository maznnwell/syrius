import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CompleteHtlcSwapBloc extends BaseBloc<HtlcSwap?> {
  Future<void> completeHtlcSwap({
    required HtlcSwap swap,
  }) async {
    try {
      addEvent(null);
      final String htlcId = swap.direction == P2pSwapDirection.outgoing
          ? swap.counterHtlcId!
          : swap.initialHtlcId;

      // Make sure that the HTLC exists and has a safe amount of time left
      // until expiration.
      final HtlcInfo htlc = await zenon!.embedded.htlc.getById(
        Hash.parse(htlcId),
      );
      if (htlc.expirationTime <=
          DateTimeUtils.unixTimeNow + kMinSafeTimeToCompleteSwap.inSeconds) {
        throw 'The swap will expire too soon for a safe swap.';
      }

      if (htlc.keyMaxSize <
          FormatUtils.decodeHexString(swap.preimage!).length) {
        throw 'The swap secret size exceeds the maximum allowed size.';
      }

      final AccountBlockTemplate transactionParams = zenon!.embedded.htlc
          .unlock(
            Hash.parse(htlcId),
            FormatUtils.decodeHexString(swap.preimage!),
          );
      AccountBlockUtils()
          .createAccountBlock(
            transactionParams,
            'complete swap',
            address: Address.parse(swap.selfAddress),
            waitForRequiredPlasma: true,
          )
          .then(
            (AccountBlockTemplate response) async {
              final HtlcSwap completedSwap = swap.copyWith(
                state: P2pSwapState.completed,
              );
              await htlcSwapsService!.storeSwap(completedSwap);
              ZenonAddressUtils().refreshBalance();
              addEvent(completedSwap);
            },
          )
          .onError(
            (Object? error, StackTrace stackTrace) {
              addError(error.toString(), stackTrace);
            },
          );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
