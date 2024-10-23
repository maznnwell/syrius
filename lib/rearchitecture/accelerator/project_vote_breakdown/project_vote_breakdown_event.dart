part of 'project_vote_breakdown_bloc.dart';

sealed class ProjectVoteBreakdownEvent {}

class ProjectVoteBreakdown extends ProjectVoteBreakdownEvent {
  final String? pillarName;
  final Hash projectId;

  ProjectVoteBreakdown({
    this.pillarName,
    required this.projectId,
  });
}
