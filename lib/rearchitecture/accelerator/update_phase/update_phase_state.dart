part of 'update_phase_bloc.dart';

sealed class UpdatePhaseState {}

class UpdatePhaseInitial extends UpdatePhaseState {}

class UpdatePhaseInProgress extends UpdatePhaseState {}

class UpdatePhaseSuccess extends UpdatePhaseState {
  final AccountBlockTemplate response;

  UpdatePhaseSuccess(this.response);
}

class UpdatePhaseFailure extends UpdatePhaseState {
  final Object error;

  UpdatePhaseFailure(this.error);
}