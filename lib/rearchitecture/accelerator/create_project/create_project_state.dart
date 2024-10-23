part of 'create_project_bloc.dart';

sealed class CreateProjectState {}

class CreateProjectInitial extends CreateProjectState {}

class CreateProjectInProgress extends CreateProjectState {}

class CreateProjectSuccess extends CreateProjectState {
  final AccountBlockTemplate response;

  CreateProjectSuccess(this.response);
}

class CreateProjectFailure extends CreateProjectState {
  final Object error;

  CreateProjectFailure(this.error);
}