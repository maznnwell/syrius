import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_rewards_history_state.dart';

class SentinelRewardsHistoryCubit extends Cubit<SentinelRewardsHistoryState> {
  final Zenon zenon;

  SentinelRewardsHistoryCubit(this.zenon)
      : super(SentinelRewardsHistoryState(
    status: CubitStatus.initial,
  ));

  Future<void> getDataAsync(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: CubitStatus.loading));

      final response =
      await zenon.embedded.sentinel.getFrontierRewardByPage(
          Address.parse('kDemoAddress'),
          pageSize: kStandardChartNumDays.toInt(),
      );
      if (response.list.any(
              (element) => element.qsrAmount > BigInt.zero || element.znnAmount > BigInt.zero)) {
        emit(state.copyWith(status: CubitStatus.success, data: response));}
      else {
        throw 'No rewards in the last week';
      }
    } catch (e) {
      emit(state.copyWith(status: CubitStatus.failure, error: e));
    }
  }
}
