import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/pair.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'project_vote_breakdown_event.dart';
part 'project_vote_breakdown_state.dart';

class ProjectVoteBreakdownBloc extends Bloc<ProjectVoteBreakdownEvent, ProjectVoteBreakdownState> {
  ProjectVoteBreakdownBloc() : super(ProjectVoteBreakdownInitial()) {
    on<ProjectVoteBreakdown>(_onProjectVoteBreakdown);
  }

  Future<void> _onProjectVoteBreakdown(
      ProjectVoteBreakdown event,
      Emitter<ProjectVoteBreakdownState> emit,
      ) async {
    try {
      emit(ProjectVoteBreakdownInProgress());

      final voteBreakdown =
      await zenon!.embedded.accelerator.getVoteBreakdown(
        event.projectId,
      );
      List<PillarVote?>? pillarVoteList;
      if (event.pillarName != null) {
        pillarVoteList = await zenon!.embedded.accelerator.getPillarVotes(
          event.pillarName!,
          [
            event.projectId.toString(),
          ],
        );
      }
      final response = Pair(voteBreakdown, pillarVoteList);
      emit(ProjectVoteBreakdownSuccess(response));
    } catch (error) {
      emit(ProjectVoteBreakdownFailure(error));
    }
  }
}
