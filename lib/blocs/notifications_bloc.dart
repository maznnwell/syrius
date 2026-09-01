import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class NotificationsBloc extends BaseBloc<WalletNotification?> {
  Future<void> addNotification(WalletNotification? notification) async {
    try {
      await Hive.openBox(kNotificationsBox);
      final Box notificationsBox = Hive.box(kNotificationsBox);
      if (notificationsBox.length >= kNotificationsEntriesLimit) {
        while (notificationsBox.length >= kNotificationsEntriesLimit) {
          await notificationsBox.delete(notificationsBox.keys.first);
        }
      }
      await notificationsBox.add(notification);
      if (notification != null &&
          isDesktopPlatform() &&
          _areDesktopNotificationsEnabled()) {
        await desktopNotificationsPlugin.show(
          id: (notification.timestamp ?? DateTime.now().millisecondsSinceEpoch)
              .hashCode,
          title: notification.title ?? 'Empty title',
          body: notification.details ?? 'No details available',
        );
      }
      addEvent(notification);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<void> sendPlasmaNotification(String purposeOfGeneratingPlasma) async {
    await addNotification(
      WalletNotification(
        title:
            'Plasma will be generated in order to '
            '$purposeOfGeneratingPlasma',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Plasma will be generated for this account-block',
        type: NotificationType.generatingPlasma,
      ),
    );
  }

  Future<void> addErrorNotification(Object error, String title) async {
    await addNotification(
      WalletNotification(
        title: title,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: '$title: $error',
        type: NotificationType.error,
      ),
    );
  }

  bool _areDesktopNotificationsEnabled() => sharedPrefsService!.get(
    kEnableDesktopNotificationsKey,
    defaultValue: kEnableDesktopNotificationsDefaultValue,
  );
}
