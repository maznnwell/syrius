
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'refresh_project_event.dart';
part 'refresh_project_state.dart';

class RefreshProjectBloc extends Bloc<RefreshProjectEvent, RefreshProjectState> {
  RefreshProjectBloc() : super(RefreshProjectInitial()) {
    on<RefreshProject>(_refreshProject);
  }

  Future<void> _refreshProject(
      RefreshProject event,
      Emitter<RefreshProjectState> emit,
      ) async {
    try {
      emit(RefreshProjectInProgress());

      final response = await zenon!.embedded.accelerator.getProjectById(event.projectID.toString());

      emit(RefreshProjectSuccess(response));
    } catch (error) {
      emit(RefreshProjectFailure(error));
    }
  }
}
