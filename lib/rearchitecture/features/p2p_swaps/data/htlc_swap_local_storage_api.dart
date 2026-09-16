import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_dao.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapLocalStorageApi {
  HtlcSwapLocalStorageApi({File? databaseFile})
    : _storageFile =
          databaseFile ??
          File(path.join(znnDefaultPaths.cache.path, kHtlcSwapsDatabase));

  final File _storageFile;
  final Mutex _mutex = Mutex();

  HtlcSwapsDatabase? _connection;

  File get _rekeyBackupFile => File('${_storageFile.path}.rekey-backup');

  Future<void> open(List<int> encryptionKey) => _mutex.protect(() async {
    if (_connection != null) {
      return;
    }

    await _storageFile.parent.create(recursive: true);
    try {
      _connection = await _openConnection(_storageFile, encryptionKey);
    } catch (_) {
      if (!_rekeyBackupFile.existsSync()) {
        rethrow;
      }

      final HtlcSwapsDatabase backupConnection = await _openConnection(
        _rekeyBackupFile,
        encryptionKey,
      );
      await backupConnection.close();
      await _deleteSqliteFiles(_storageFile);
      await _rekeyBackupFile.rename(_storageFile.path);
      _connection = await _openConnection(_storageFile, encryptionKey);
    }

    try {
      await _deleteSqliteFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A valid primary database makes a stale encrypted backup disposable.
    }
  });

  Future<void> close() => _mutex.protect(_closeConnection);

  Future<void> deleteDatabase() => _mutex.protect(() async {
    await _closeConnection();
    await _deleteSqliteFiles(_storageFile);
    await _deleteSqliteFiles(_rekeyBackupFile);
  });

  Future<void> beginRekey({
    required List<int> oldEncryptionKey,
    required List<int> newEncryptionKey,
  }) => _mutex.protect(() async {
    final HtlcSwapsDatabase connection = _requireConnection();
    await connection.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    await _closeConnection();
    await _deleteSqliteFiles(_rekeyBackupFile);
    await _storageFile.copy(_rekeyBackupFile.path);

    try {
      _connection = await _openConnection(_storageFile, oldEncryptionKey);
      await _connection!.rekey(newEncryptionKey);
      await _closeConnection();
      _connection = await _openConnection(_storageFile, newEncryptionKey);
    } catch (_) {
      await _restoreRekeyBackup(oldEncryptionKey);
      rethrow;
    }
  });

  Future<void> commitRekey() => _mutex.protect(() async {
    try {
      await _deleteSqliteFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A stale encrypted backup is removed the next time the database opens.
    }
  });

  Future<void> rollbackRekey(List<int> oldEncryptionKey) =>
      _mutex.protect(() => _restoreRekeyBackup(oldEncryptionKey));

  Future<List<HtlcSwapEntry>> readAllSwapEntries() =>
      _withDao((HtlcSwapsDao dao) => dao.readAllSwapEntries());

  Stream<List<HtlcSwapEntry>> watchAllSwapEntries() =>
      _requireConnection().htlcSwapsDao.watchAllSwapEntries();

  Future<List<HtlcSwapEntry>> readSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntriesByState(chainId, states),
  );

  Future<HtlcSwapEntry?> readSwapEntryByHashLock(
    int chainId,
    String hashLock,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntryByHashLock(chainId, hashLock),
  );

  Future<HtlcSwapEntry?> readSwapEntryByHtlcId(int chainId, String htlcId) =>
      _withDao(
        (HtlcSwapsDao dao) => dao.readSwapEntryByHtlcId(chainId, htlcId),
      );

  Future<HtlcSwapEntry?> readSwapEntryById(String id) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntryById(id),
  );

  Future<int> readLastCheckedHtlcBlockHeight(int chainId) => _withDao(
    (HtlcSwapsDao dao) => dao.readLastCheckedHtlcBlockHeight(chainId),
  );

  Future<void> writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) => _withDao(
    (HtlcSwapsDao dao) => dao.writeSwapEntry(
      entry,
      maximumStoredSwaps: maximumStoredSwaps,
      pruneChainId: pruneChainId,
      prunableStates: prunableStates,
    ),
  );

  Future<void> writeProcessedHtlcBlock({
    required int chainId,
    required int height,
    required HtlcSwapEntry? updatedEntry,
    required int maximumStoredSwaps,
    required List<String> prunableStates,
  }) => _withDao(
    (HtlcSwapsDao dao) => dao.writeProcessedHtlcBlock(
      chainId: chainId,
      height: height,
      updatedEntry: updatedEntry,
      maximumStoredSwaps: maximumStoredSwaps,
      prunableStates: prunableStates,
    ),
  );

  Future<void> writeLastCheckedHtlcBlockHeight(int chainId, int height) =>
      _withDao(
        (HtlcSwapsDao dao) =>
            dao.writeLastCheckedHtlcBlockHeight(chainId, height),
      );

  Future<void> deleteSwapEntry(String swapId) =>
      _withDao((HtlcSwapsDao dao) => dao.deleteSwapEntry(swapId));

  Future<void> deleteSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.deleteSwapEntriesByState(chainId, states),
  );

  Future<T> _withDao<T>(
    Future<T> Function(HtlcSwapsDao dao) operation,
  ) => _mutex.protect(
    () => operation(_requireConnection().htlcSwapsDao),
  );

  HtlcSwapsDatabase _requireConnection() {
    return _connection ??
        (throw StateError('The HTLC swaps database is not open'));
  }

  Future<HtlcSwapsDatabase> _openConnection(
    File file,
    List<int> encryptionKey,
  ) async {
    final HtlcSwapsDatabase connection = HtlcSwapsDatabase.encrypted(
      file,
      encryptionKey,
    );
    try {
      await connection.verifyOpen();
      return connection;
    } catch (_) {
      await connection.close();
      rethrow;
    }
  }

  Future<void> _closeConnection() async {
    final HtlcSwapsDatabase? connection = _connection;
    _connection = null;
    await connection?.close();
  }

  Future<void> _restoreRekeyBackup(List<int> oldEncryptionKey) async {
    await _closeConnection();
    if (!_rekeyBackupFile.existsSync()) {
      throw StateError('The HTLC swaps rekey backup does not exist');
    }

    await _deleteSqliteFiles(_storageFile);
    await _rekeyBackupFile.rename(_storageFile.path);
    _connection = await _openConnection(_storageFile, oldEncryptionKey);
  }

  Future<void> _deleteSqliteFiles(File storageFile) async {
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File file = File('${storageFile.path}$suffix');
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
