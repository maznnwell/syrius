part of 'send_payment_bloc.dart';

sealed class SendPaymentEvent {}

class SendTransfer extends SendPaymentEvent {
  final String fromAddress;
  final String toAddress;
  final BigInt amount;
  final List<int>? data;
  final Token token;

  SendTransfer({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    this.data,
    required this.token,
  });
}

class SendTransferWithBlock extends SendPaymentEvent {
  final AccountBlockTemplate block;
  final String fromAddress;

  SendTransferWithBlock({
    required this.block,
    required this.fromAddress,
  });
}
