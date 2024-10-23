part of 'vote_project_bloc.dart';

sealed class VoteProjectEvent {}

class VoteProject extends VoteProjectEvent {
  final Hash id;
  final AcceleratorProjectVote vote;

  VoteProject({
    required this.id,
    required this.vote,
  });
}
