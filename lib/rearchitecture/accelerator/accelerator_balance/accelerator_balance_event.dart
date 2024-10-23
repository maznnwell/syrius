part of 'accelerator_balance_bloc.dart';

sealed class AcceleratorBalanceEvent {}

class GetAcceleratorBalance extends AcceleratorBalanceEvent {
  GetAcceleratorBalance();
}
