import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_unlock_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const Duration _kRetryCooldown = Duration(minutes: 2);

class HtlcSwapAutoUnlockService {
  HtlcSwapAutoUnlockService({
    required this._notificationsBloc,
    required this._unlockService,
    required this._zenon,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Logger _logger = Logger('HtlcSwapAutoUnlockService');
  final Zenon _zenon;
  final DateTime Function() _now;
  final Map<String, DateTime> _recentAttempts = <String, DateTime>{};
  final NotificationsBloc _notificationsBloc;
  final HtlcSwapUnlockService _unlockService;

  bool _isUnlocking = false;

  bool get isUnlocking => _isUnlocking;

  Future<void> unlockNext(Iterable<HtlcSwap> candidates) async {
    final bool walletIsAvailable = kWalletFile != null;

    if (_isUnlocking || !walletIsAvailable) {
      return;
    }

    final DateTime now = _now();
    _recentAttempts.removeWhere(
      (_, DateTime attemptedAt) =>
          now.difference(attemptedAt) >= _kRetryCooldown,
    );

    HtlcSwap? swap;
    for (final HtlcSwap candidate in candidates) {
      if (!_recentAttempts.containsKey(candidate.initialHtlcId)) {
        swap = candidate;
        break;
      }
    }
    if (swap == null) {
      return;
    }

    _isUnlocking = true;
    try {
      if (!await _isNodeSynced()) {
        return;
      }

      _recentAttempts[swap.initialHtlcId] = now;
      await _unlock(swap);
    } finally {
      _isUnlocking = false;
    }
  }

  Future<bool> _isNodeSynced() async {
    try {
      final SyncInfo syncInfo = await _zenon.stats.syncInfo();
      return syncInfo.state == SyncState.syncDone ||
          (syncInfo.targetHeight > 0 &&
              syncInfo.currentHeight > 0 &&
              syncInfo.targetHeight - syncInfo.currentHeight < 3);
    } catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'unlockNext', error, stackTrace);
      return false;
    }
  }

  Future<void> _unlock(HtlcSwap swap) async {
    try {
      final AccountBlockTemplate response = await _unlockService.unlock(swap);
      await _sendSuccessNotification(response, swap.selfAddress);
    } on RpcException catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'unlockNext', error, stackTrace);
      if (!error.message.contains('data non existent')) {
        await _sendErrorNotification(error.toString());
      }
    } catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'unlockNext', error, stackTrace);
      await _sendErrorNotification(error.toString());
    }
  }

  Future<void> _sendErrorNotification(String errorText) => _notify(
    WalletNotification(
      title: 'Failed to complete swap',
      timestamp: _now().millisecondsSinceEpoch,
      details: 'Failed to complete the swap: $errorText',
      type: NotificationType.error,
    ),
  );

  Future<void> _sendSuccessNotification(
    AccountBlockTemplate block,
    String toAddress,
  ) => _notify(
    WalletNotification(
      title: 'Transaction received on ${ZenonAddressUtils.getLabel(toAddress)}',
      timestamp: _now().millisecondsSinceEpoch,
      details: 'Transaction hash: ${block.hash}',
      type: NotificationType.paymentReceived,
    ),
  );

  Future<void> _notify(WalletNotification notification) async {
    try {
      await _notificationsBloc.addNotification(notification);
    } catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'notify', error, stackTrace);
    }
  }
}
