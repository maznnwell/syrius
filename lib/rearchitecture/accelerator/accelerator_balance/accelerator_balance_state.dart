part of 'accelerator_balance_bloc.dart';

sealed class AcceleratorBalanceState {}

class AcceleratorBalanceInitial extends AcceleratorBalanceState {}

class AcceleratorBalanceInProgress extends AcceleratorBalanceState {}

class AcceleratorBalanceSuccess extends AcceleratorBalanceState {
  final AccountInfo response;

  AcceleratorBalanceSuccess(this.response);
}

class AcceleratorBalanceFailure extends AcceleratorBalanceState {
  final Object error;

  AcceleratorBalanceFailure(this.error);
}
