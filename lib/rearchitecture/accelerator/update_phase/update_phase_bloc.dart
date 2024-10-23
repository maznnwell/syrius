import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';

part 'update_phase_event.dart';
part 'update_phase_state.dart';

class UpdatePhaseBloc extends Bloc<UpdatePhaseEvent, UpdatePhaseState> {
  UpdatePhaseBloc() : super(UpdatePhaseInitial()) {
    on<UpdatePhase>(_onUpdatePhase);
  }

  Future<void> _onUpdatePhase(
      UpdatePhase event,
      Emitter<UpdatePhaseState> emit,
      ) async {
    try {
      emit(UpdatePhaseInProgress());

      final transactionParams =
      zenon!.embedded.accelerator.updatePhase(
        event.id,
        event.name,
        event.description,
        event.url,
        event.znnFundsNeeded,
        event.qsrFundsNeeded,
      );

      final response = await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'update phase',
      );

      emit(UpdatePhaseSuccess(response));
    } catch (error) {
      emit(UpdatePhaseFailure(error));
    }
  }
}
