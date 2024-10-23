part of 'project_vote_breakdown_bloc.dart';

sealed class ProjectVoteBreakdownState {}

class ProjectVoteBreakdownInitial extends ProjectVoteBreakdownState {}

class ProjectVoteBreakdownInProgress extends ProjectVoteBreakdownState {}

class ProjectVoteBreakdownSuccess extends ProjectVoteBreakdownState {
  final Pair<VoteBreakdown, List<PillarVote?>?> response;

  ProjectVoteBreakdownSuccess(this.response);
}

class ProjectVoteBreakdownFailure extends ProjectVoteBreakdownState {
  final Object error;

  ProjectVoteBreakdownFailure(this.error);
}