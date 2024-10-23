part of 'refresh_project_bloc.dart';

sealed class RefreshProjectState {}

class RefreshProjectInitial extends RefreshProjectState {}

class RefreshProjectInProgress extends RefreshProjectState {}

class RefreshProjectSuccess extends RefreshProjectState {
  final response;
  RefreshProjectSuccess(this.response);
}

class RefreshProjectFailure extends RefreshProjectState {
  final Object error;

  RefreshProjectFailure(this.error);
}