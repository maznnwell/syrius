import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';

part 'vote_project_event.dart';
part 'vote_project_state.dart';

class VoteProjectBloc extends Bloc<VoteProjectEvent, VoteProjectState> {
  VoteProjectBloc() : super(VoteProjectInitial()) {
    on<VoteProject>(_onVoteProject);
  }

  Future<void> _onVoteProject(
      VoteProject event,
      Emitter<VoteProjectState> emit,
      ) async {
    try {
      emit(VoteProjectInProgress());

      final pillarInfo = (await zenon!.embedded.pillar.getByOwner(
        Address.parse('kDemoAddress'),
      ))
          .first;
      final transactionParams =
      zenon!.embedded.accelerator.voteByName(
        event.id,
        pillarInfo.name,
        event.vote.index,
      );
      final response = await AccountBlockUtils.createAccountBlock(
          transactionParams,
          'vote for project',
        );

      emit(VoteProjectSuccess(response));
    } catch (error) {
      emit(VoteProjectFailure(error));
    }
  }
}
