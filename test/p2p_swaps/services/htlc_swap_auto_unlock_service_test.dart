import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockEmbeddedApi extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockStatsApi extends Mock implements StatsApi {}

class MockZenon extends Mock implements Zenon {}

class MockNotificationsBloc extends Mock implements NotificationsBloc {}

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

    late MockAccountBlockUtils accountBlockUtils;
    late MockEmbeddedApi embeddedApi;
    late MockHtlcApi htlcApi;
    late MockNotificationsBloc notificationsBloc;
    late MockStatsApi statsApi;
    late MockZenon zenon;
    late AccountBlockTemplate transactionParams;
    late HtlcSwap swap;
    late HtlcSwapAutoUnlockService service;
    late List<WalletNotification> notifications;
    late DateTime now;
    late WalletFile? previousWalletFile;
    late List<String?> previousDefaultAddressList;

    setUp(() {
      previousWalletFile = kWalletFile;
      previousDefaultAddressList = kDefaultAddressList;
      accountBlockUtils = MockAccountBlockUtils();
      embeddedApi = MockEmbeddedApi();
      htlcApi = MockHtlcApi();
      notificationsBloc = MockNotificationsBloc();
      statsApi = MockStatsApi();
      zenon = MockZenon();
      transactionParams = AccountBlockTemplate(blockType: 1);
      notifications = <WalletNotification>[];
      now = DateTime(2026);
      kWalletFile = MockWalletFile();
      kDefaultAddressList = <String?>[selfAddress.toString()];

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

      final HtlcInfo htlc = HtlcInfo(
        id: htlcId,
        timeLocked: htlcAddress,
        hashLocked: selfAddress,
        tokenStandard: kZnnCoin.tokenStandard,
        amount: BigInt.one,
        expirationTime: 2000,
        hashType: htlcHashTypeSha3,
        keyMaxSize: htlcPreimageMaxLength,
        hashLock: Hash.digest(preimage).getBytes()!,
      );
      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncDone.index,
        'currentHeight': 100,
        'targetHeight': 100,
      });

      when(() => zenon.stats).thenReturn(statsApi);
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);
      when(() => zenon.embedded).thenReturn(embeddedApi);
      when(() => embeddedApi.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(htlcId)).thenAnswer((_) async => htlc);
      when(
        () => htlcApi.unlock(htlcId, preimage),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);
      when(
        () => notificationsBloc.addNotification(any()),
      ).thenAnswer((Invocation invocation) async {
        notifications.add(
          invocation.positionalArguments.single as WalletNotification,
        );
      });

      service = HtlcSwapAutoUnlockService(
        accountBlockUtils: accountBlockUtils,
        notificationsBloc: notificationsBloc,
        zenon: zenon,
        now: () => now,
      );
    });

    tearDown(() {
      kWalletFile = previousWalletFile;
      kDefaultAddressList = previousDefaultAddressList;
    });

    test(
      'unlocks one eligible swap and sends a success notification',
      () async {
        await service.unlockNext(<HtlcSwap>[swap]);

        verify(() => htlcApi.getById(htlcId)).called(1);
        verify(() => htlcApi.unlock(htlcId, preimage)).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'complete swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.paymentReceived);
      },
    );

    test('exposes an in-progress unlock attempt', () async {
      final Completer<AccountBlockTemplate> completer =
          Completer<AccountBlockTemplate>();
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
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

      verify(() => htlcApi.getById(htlcId)).called(1);

      now = now.add(const Duration(minutes: 2));
      await service.unlockNext(<HtlcSwap>[swap]);

      verify(() => htlcApi.getById(htlcId)).called(1);
    });

    test(
      'does not attempt an unlock while the wallet is unavailable',
      () async {
        kWalletFile = null;

        await service.unlockNext(<HtlcSwap>[swap]);

        verifyNever(() => statsApi.syncInfo());
        verifyNever(() => htlcApi.getById(htlcId));
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

      verifyNever(() => htlcApi.getById(htlcId));
      expect(notifications, isEmpty);
    });

    test('reports an HTLC that does not belong to the wallet', () async {
      kDefaultAddressList = <String?>[];

      await service.unlockNext(<HtlcSwap>[swap]);

      verifyNever(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      );
      expect(notifications, hasLength(1));
      expect(notifications.single.type, NotificationType.error);
      expect(
        notifications.single.details,
        contains('Swap address not in default addresses'),
      );
    });
  });
}
