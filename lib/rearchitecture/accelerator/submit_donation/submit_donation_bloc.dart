import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/accelerator/accelerator_balance/accelerator_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';

part 'submit_donation_event.dart';
part 'submit_donation_state.dart';

class SubmitDonationBloc extends Bloc<SubmitDonationEvent, SubmitDonationState> {
  SubmitDonationBloc() : super(SubmitDonationInitial()) {
    on<SubmitDonation>(_onSubmitDonation);
  }

  Future<void> _onSubmitDonation(
      SubmitDonation event,
      Emitter<SubmitDonationState> emit,
      ) async {
    try {
      emit(SubmitDonationInProgress());

      if (event.znnAmount > BigInt.zero) {
        final transactionParams = zenon!.embedded.accelerator.donate(
          event.znnAmount,
          kZnnCoin.tokenStandard,
        );
        await _sendDonationBlock(transactionParams, emit);
      }
      if (event.qsrAmount > BigInt.zero) {
        final transactionParams = zenon!.embedded.accelerator.donate(
          event.qsrAmount,
          kQsrCoin.tokenStandard,
        );
        await _sendDonationBlock(transactionParams, emit);
      }
    } catch (error) {
      emit(SubmitDonationFailure(error));
    }
  }

  Future<void> _sendDonationBlock(
      AccountBlockTemplate transactionParams,
      Emitter<SubmitDonationState> emit,
      )
  async {
    try {
      final response = await AccountBlockUtils.createAccountBlock(
         transactionParams,
         'donate for accelerator',
       );

      sl.get<AcceleratorBalanceBloc>()
          .add(GetAcceleratorBalance());
      emit(SubmitDonationSuccess(response));

    } catch (error){
      rethrow;
    }
  }
}
