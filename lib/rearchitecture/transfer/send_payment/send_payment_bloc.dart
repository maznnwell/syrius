import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'send_payment_event.dart';
part 'send_payment_state.dart';

class SendPaymentBloc extends Bloc<SendPaymentEvent, SendPaymentState> {
  SendPaymentBloc() : super(SendPaymentInitial()) {
    on<SendTransfer>(_onSendTransfer);
    on<SendTransferWithBlock>(_onSendTransferWithBlock);
  }

  Future<void> _onSendTransfer(
      SendTransfer event,
      Emitter<SendPaymentState> emit,
      ) async {
    try {
      emit(SendPaymentInProgress());

      final accountBlock = AccountBlockTemplate.send(
        Address.parse(event.toAddress),
        event.token.tokenStandard,
        event.amount,
        event.data,
      );

      final response = await AccountBlockUtils.createAccountBlock(
        accountBlock,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      ZenonAddressUtils.refreshBalance();
      emit(SendPaymentSuccess(response));
    } catch (error) {
      emit(SendPaymentFailure(error));
    }
  }

  Future<void> _onSendTransferWithBlock(
      SendTransferWithBlock event,
      Emitter<SendPaymentState> emit,
      ) async {
    try {
      emit(SendPaymentInProgress());
      final response = await AccountBlockUtils.createAccountBlock(
        event.block,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      ZenonAddressUtils.refreshBalance();
      emit(SendPaymentSuccess(response));
    } catch (error) {
      emit(SendPaymentFailure(error));
    }
  }
}
