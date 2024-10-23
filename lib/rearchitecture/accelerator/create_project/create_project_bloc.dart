import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'create_project_event.dart';
part 'create_project_state.dart';

class CreateProjectBloc extends Bloc<CreateProjectEvent, CreateProjectState> {
  CreateProjectBloc() : super(CreateProjectInitial()) {
    on<CreateProject>(_onCreateProject);
  }

  Future<void> _onCreateProject(
      CreateProject event,
      Emitter<CreateProjectState> emit,
      ) async {
    try {
      emit(CreateProjectInProgress());

      final transactionParams =
      zenon!.embedded.accelerator.createProject(
        event.name,
        event.description,
        event.url,
        event.znnFundsNeeded,
        event.qsrFundsNeeded,
      );

      final response = await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'creating project',
      );
      ZenonAddressUtils.refreshBalance();

      emit(CreateProjectSuccess(response));
    } catch (error) {
      emit(CreateProjectFailure(error));
    }
  }
}
