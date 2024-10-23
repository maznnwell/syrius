import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
part 'accelerator_balance_event.dart';
part 'accelerator_balance_state.dart';

class AcceleratorBalanceBloc extends Bloc<AcceleratorBalanceEvent, AcceleratorBalanceState> {
  AcceleratorBalanceBloc() : super(AcceleratorBalanceInitial()) {
    on<GetAcceleratorBalance>(getAcceleratorBalance);
  }

  Future<void> getAcceleratorBalance(
      GetAcceleratorBalance event,
      Emitter<AcceleratorBalanceState> emit,
      ) async {
    try {
      emit(AcceleratorBalanceInProgress());

     final accountInfo = await zenon!.ledger.getAccountInfoByAddress(
        acceleratorAddress,
      );
      if (accountInfo.qsr()! > BigInt.zero ||
          accountInfo.znn()! > BigInt.zero) {
        emit(AcceleratorBalanceSuccess(accountInfo));
      } else {
        throw 'Accelerator fund empty';
      }
    } catch (error) {
      emit(AcceleratorBalanceFailure(error));
    }
  }
}