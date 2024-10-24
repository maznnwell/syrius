import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard_cubit.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'general_stats.dart';
part 'general_stats_state.dart';

class GeneralStatsCubit extends DashboardCubit<GeneralStats, GeneralStatsState> {
  GeneralStatsCubit(super.zenon, super.initialState)
      : super(refreshInterval: kIntervalBetweenMomentums);

  @override
  Future<GeneralStats> fetch() async {
    try {
      final generalStats = GeneralStats(
          frontierMomentum: await zenon.ledger.getFrontierMomentum(),
          processInfo: await zenon.stats.processInfo(),
          networkInfo: await zenon.stats.networkInfo(),
          osInfo: await zenon.stats.osInfo(),
      );
      return generalStats;
    } catch (e) {
      rethrow;
    }
  }
}
