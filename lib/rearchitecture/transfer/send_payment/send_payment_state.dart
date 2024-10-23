part of 'send_payment_bloc.dart';

sealed class SendPaymentState {}

class SendPaymentInitial extends SendPaymentState {}

class SendPaymentInProgress extends SendPaymentState {}

class SendPaymentSuccess extends SendPaymentState {
  final AccountBlockTemplate response;

  SendPaymentSuccess(this.response);
}

class SendPaymentFailure extends SendPaymentState {
  final Object error;

  SendPaymentFailure(this.error);
}
