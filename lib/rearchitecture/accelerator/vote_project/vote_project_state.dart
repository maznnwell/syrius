part of 'vote_project_bloc.dart';

sealed class VoteProjectState {}

class VoteProjectInitial extends VoteProjectState {}

class VoteProjectInProgress extends VoteProjectState {}

class VoteProjectSuccess extends VoteProjectState {
  final AccountBlockTemplate response;

  VoteProjectSuccess(this.response);
}

class VoteProjectFailure extends VoteProjectState {
  final Object error;

  VoteProjectFailure(this.error);
}