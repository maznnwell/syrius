part of 'create_phase_bloc.dart';

sealed class CreatePhaseState {}

class CreatePhaseInitial extends CreatePhaseState {}

class CreatePhaseInProgress extends CreatePhaseState {}

class CreatePhaseSuccess extends CreatePhaseState {
  final AccountBlockTemplate response;

  CreatePhaseSuccess(this.response);
}

class CreatePhaseFailure extends CreatePhaseState {
  final Object error;

  CreatePhaseFailure(this.error);
}
