import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'create_phase_event.dart';
part 'create_phase_state.dart';

class CreatePhaseBloc extends Bloc<CreatePhaseEvent, CreatePhaseState> {
  CreatePhaseBloc() : super(CreatePhaseInitial()) {
    on<CreatePhase>(_onCreatePhase);
  }

  Future<void> _onCreatePhase(
      CreatePhase event,
      Emitter<CreatePhaseState> emit,
      ) async {
    try {
      emit(CreatePhaseInProgress());

      final transactionParams =
      zenon!.embedded.accelerator.addPhase(
        event.id,
        event.name,
        event.description,
        event.url,
        event.znnFundsNeeded,
        event.qsrFundsNeeded,
      );

      final response = await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'create phase',
      );

      emit(CreatePhaseSuccess(response));
    } catch (error) {
      emit(CreatePhaseFailure(error));
    }
  }
}
