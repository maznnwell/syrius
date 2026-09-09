import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  late Directory temporaryDirectory;
  late File databaseFile;
  late HtlcSwapsService service;
  late int? originalChainId;

  final List<int> encryptionKey = Crypto.digest(utf8.encode('password'));
  final List<int> newEncryptionKey = Crypto.digest(
    utf8.encode('new-password'),
  );

  setUp(() async {
    originalChainId = kNodeChainId;
    kNodeChainId = 1;
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'syrius_htlc_drift_test_',
    );
    databaseFile = File('${temporaryDirectory.path}/htlc_swaps.sqlite');
    service = HtlcSwapsService(databaseFile: databaseFile);
    await service.open(encryptionKey);
  });

  tearDown(() async {
    await service.close();
    kNodeChainId = originalChainId;
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('stores and queries swaps for the current chain', () async {
    final HtlcSwap swap = _buildSwap();
    await service.storeSwap(swap);

    expect(await service.getAllSwaps(), <HtlcSwap>[swap]);
    expect(await service.getSwapById(swap.id), swap);
    expect(await service.getSwapByHashLock(swap.hashLock), swap);
    expect(await service.getSwapByHtlcId(swap.initialHtlcId), swap);
    expect(await service.getSwapByHtlcId(swap.counterHtlcId!), swap);
    expect(
      await service.getSwapsByState(<P2pSwapState>[P2pSwapState.active]),
      <HtlcSwap>[swap],
    );

    kNodeChainId = 2;
    expect(await service.getAllSwaps(), isEmpty);
  });

  test('stores scan checkpoints independently for each chain', () async {
    await service.storeLastCheckedHtlcBlockHeight(10);
    expect(await service.getLastCheckedHtlcBlockHeight(), 10);

    kNodeChainId = 2;
    expect(await service.getLastCheckedHtlcBlockHeight(), 0);
    await service.storeLastCheckedHtlcBlockHeight(20);
    expect(await service.getLastCheckedHtlcBlockHeight(), 20);

    kNodeChainId = 1;
    expect(await service.getLastCheckedHtlcBlockHeight(), 10);
  });

  test('deletes inactive swaps only on the current chain', () async {
    final HtlcSwap active = _buildSwap(id: 'active');
    final HtlcSwap completed = _buildSwap(
      id: 'completed',
      state: P2pSwapState.completed,
    );
    final HtlcSwap otherChain = _buildSwap(
      id: 'other-chain',
      chainId: 2,
      state: P2pSwapState.completed,
    );
    await service.storeSwap(active);
    await service.storeSwap(completed);
    await service.storeSwap(otherChain);

    await service.deleteInactiveSwaps();

    expect(await service.getAllSwaps(), <HtlcSwap>[active]);
    kNodeChainId = 2;
    expect(await service.getAllSwaps(), <HtlcSwap>[otherChain]);
  });

  test('encrypts the database and rejects an incorrect key', () async {
    const String secretPreimage = 'unencrypted-preimage-marker';
    await service.storeSwap(_buildSwap(preimage: secretPreimage));
    await service.close();

    final String databaseContents = latin1.decode(
      await databaseFile.readAsBytes(),
      allowInvalid: true,
    );
    expect(databaseContents, isNot(contains('SQLite format 3')));
    expect(databaseContents, isNot(contains(secretPreimage)));

    final HtlcSwapsService incorrectKeyService = HtlcSwapsService(
      databaseFile: databaseFile,
    );
    await expectLater(
      incorrectKeyService.open(newEncryptionKey),
      throwsA(anything),
    );
    await incorrectKeyService.close();

    service = HtlcSwapsService(databaseFile: databaseFile);
    await service.open(encryptionKey);
    expect(await service.getAllSwaps(), hasLength(1));
  });

  test('rekeys the database when the password changes', () async {
    final HtlcSwap swap = _buildSwap();
    await service.storeSwap(swap);

    await service.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );
    await service.commitRekey();
    await service.close();

    final HtlcSwapsService oldKeyService = HtlcSwapsService(
      databaseFile: databaseFile,
    );
    await expectLater(oldKeyService.open(encryptionKey), throwsA(anything));
    await oldKeyService.close();

    service = HtlcSwapsService(databaseFile: databaseFile);
    await service.open(newEncryptionKey);
    expect(await service.getAllSwaps(), <HtlcSwap>[swap]);
  });

  test('restores the old key after an interrupted password change', () async {
    final HtlcSwap swap = _buildSwap();
    await service.storeSwap(swap);
    await service.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );
    await service.close();

    service = HtlcSwapsService(databaseFile: databaseFile);
    await service.open(encryptionKey);

    expect(await service.getAllSwaps(), <HtlcSwap>[swap]);
    expect(await File('${databaseFile.path}.rekey-backup').exists(), isFalse);
  });

  test('rolls back a prepared password change', () async {
    final HtlcSwap swap = _buildSwap();
    await service.storeSwap(swap);
    await service.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );

    await service.rollbackRekey(encryptionKey);

    expect(await service.getAllSwaps(), <HtlcSwap>[swap]);
    await service.close();
    service = HtlcSwapsService(databaseFile: databaseFile);
    await service.open(encryptionKey);
    expect(await service.getAllSwaps(), <HtlcSwap>[swap]);
  });
}

HtlcSwap _buildSwap({
  String id = 'swap-id',
  int chainId = 1,
  P2pSwapState state = P2pSwapState.active,
  String? preimage,
}) => HtlcSwap(
  hashLock: 'hash-lock-$id',
  initialHtlcId: 'initial-htlc-id-$id',
  initialHtlcExpirationTime: 1000,
  hashType: htlcHashTypeSha3,
  id: id,
  chainId: chainId,
  type: P2pSwapType.native,
  direction: P2pSwapDirection.incoming,
  selfAddress: 'self-address',
  counterpartyAddress: 'counterparty-address',
  fromAmount: BigInt.from(100),
  fromToken: kZnnCoin,
  fromChain: P2pSwapChain.nom,
  toChain: P2pSwapChain.nom,
  startTime: 1,
  state: state,
  toAmount: BigInt.from(200),
  toToken: kQsrCoin,
  counterHtlcId: 'counter-htlc-id-$id',
  counterHtlcExpirationTime: 900,
  preimage: preimage,
);
