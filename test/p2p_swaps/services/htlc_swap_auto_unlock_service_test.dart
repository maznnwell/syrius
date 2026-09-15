import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockStatsApi extends Mock implements StatsApi {}

class MockZenon extends Mock implements Zenon {}

class MockNotificationsBloc extends Mock implements NotificationsBloc {}

class MockHtlcSwapUnlockService extends Mock implements HtlcSwapUnlockService {}

class MockWalletFile extends Mock implements WalletFile {}

class FakeWalletNotification extends Fake implements WalletNotification {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWalletNotification());
  });

  group('HtlcSwapAutoUnlockService', () {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final List<int> preimage = <int>[4, 5, 6];
    final Address selfAddress = emptyAddress;

    late MockHtlcSwapUnlockService unlockService;
    late MockNotificationsBloc notificationsBloc;
    late MockStatsApi statsApi;
    late MockZenon zenon;
    late AccountBlockTemplate transactionParams;
    late HtlcSwap swap;
    late HtlcSwapAutoUnlockService service;
    late List<WalletNotification> notifications;
    late DateTime now;
    late WalletFile? previousWalletFile;

    setUp(() {
      previousWalletFile = kWalletFile;
      unlockService = MockHtlcSwapUnlockService();
      notificationsBloc = MockNotificationsBloc();
      statsApi = MockStatsApi();
      zenon = MockZenon();
      transactionParams = AccountBlockTemplate(blockType: 1);
      notifications = <WalletNotification>[];
      now = DateTime(2026);
      kWalletFile = MockWalletFile();

      swap = HtlcSwap(
        hashLock: Hash.digest(preimage).toString(),
        initialHtlcId: htlcId.toString(),
        initialHtlcExpirationTime: 2000,
        hashType: htlcHashTypeSha3,
        id: htlcId.toString(),
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.incoming,
        selfAddress: selfAddress.toString(),
        counterpartyAddress: htlcAddress.toString(),
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 1000,
        state: P2pSwapState.active,
        preimage: FormatUtils.encodeHexString(preimage),
      );

      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncDone.index,
        'currentHeight': 100,
        'targetHeight': 100,
      });

      when(() => zenon.stats).thenReturn(statsApi);
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);
      when(
        () => unlockService.unlock(swap),
      ).thenAnswer((_) async => transactionParams);
      when(
        () => notificationsBloc.addNotification(any()),
      ).thenAnswer((Invocation invocation) async {
        notifications.add(
          invocation.positionalArguments.single as WalletNotification,
        );
      });

      service = HtlcSwapAutoUnlockService(
        notificationsBloc: notificationsBloc,
        unlockService: unlockService,
        zenon: zenon,
        now: () => now,
      );
    });

    tearDown(() {
      kWalletFile = previousWalletFile;
    });

    test(
      'unlocks one eligible swap and sends a success notification',
      () async {
        await service.unlockNext(<HtlcSwap>[swap]);

        verify(() => unlockService.unlock(swap)).called(1);
        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.paymentReceived);
      },
    );

    test('exposes an in-progress unlock attempt', () async {
      final Completer<AccountBlockTemplate> completer =
          Completer<AccountBlockTemplate>();
      when(
        () => unlockService.unlock(swap),
      ).thenAnswer((_) => completer.future);

      final Future<void> unlock = service.unlockNext(<HtlcSwap>[swap]);
      await Future<void>.delayed(Duration.zero);

      expect(service.isUnlocking, isTrue);

      completer.complete(transactionParams);
      await unlock;
      expect(service.isUnlocking, isFalse);
    });

    test('retries a swap only after the cooldown', () async {
      await service.unlockNext(<HtlcSwap>[swap]);
      await service.unlockNext(<HtlcSwap>[swap]);

      verify(() => unlockService.unlock(swap)).called(1);

      now = now.add(const Duration(minutes: 2));
      await service.unlockNext(<HtlcSwap>[swap]);

      verify(() => unlockService.unlock(swap)).called(1);
    });

    test(
      'does not attempt an unlock while the wallet is unavailable',
      () async {
        kWalletFile = null;

        await service.unlockNext(<HtlcSwap>[swap]);

        verifyNever(() => statsApi.syncInfo());
        verifyNever(() => unlockService.unlock(swap));
        expect(notifications, isEmpty);
      },
    );

    test('does not attempt an unlock while the node is syncing', () async {
      final SyncInfo syncing = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 50,
        'targetHeight': 100,
      });
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncing);

      await service.unlockNext(<HtlcSwap>[swap]);

      verifyNever(() => unlockService.unlock(swap));
      expect(notifications, isEmpty);
    });

    test('reports an unlock failure', () async {
      when(() => unlockService.unlock(swap)).thenThrow(
        SyriusException('Swap address not in default addresses.'),
      );

      await service.unlockNext(<HtlcSwap>[swap]);

      expect(notifications, hasLength(1));
      expect(notifications.single.type, NotificationType.error);
      expect(
        notifications.single.details,
        contains('Swap address not in default addresses'),
      );
    });
  });
}
