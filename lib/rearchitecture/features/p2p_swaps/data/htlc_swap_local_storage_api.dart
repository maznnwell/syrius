import 'dart:io';

import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapLocalStorageApi {
  HtlcSwapLocalStorageApi({File? databaseFile})
    : _databaseFileOverride = databaseFile;

  final File? _databaseFileOverride;
  final Mutex _mutex = Mutex();

  HtlcSwapsDatabase? _database;

  File get _databaseFile =>
      _databaseFileOverride ??
      File(path.join(znnDefaultPaths.cache.path, kHtlcSwapsDatabase));

  File get _rekeyBackupFile => File('${_databaseFile.path}.rekey-backup');

  Future<void> open(List<int> encryptionKey) => _mutex.protect(() async {
    if (_database != null) {
      return;
    }

    await _databaseFile.parent.create(recursive: true);
    try {
      _database = await _openDatabase(_databaseFile, encryptionKey);
    } catch (_) {
      if (!_rekeyBackupFile.existsSync()) {
        rethrow;
      }

      final HtlcSwapsDatabase backup = await _openDatabase(
        _rekeyBackupFile,
        encryptionKey,
      );
      await backup.close();
      await _deleteDatabaseFiles(_databaseFile);
      await _rekeyBackupFile.rename(_databaseFile.path);
      _database = await _openDatabase(_databaseFile, encryptionKey);
    }

    try {
      await _deleteDatabaseFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A valid primary database makes a stale encrypted backup disposable.
    }
  });

  Future<void> close() => _mutex.protect(_closeDatabase);

  Future<void> deleteDatabase() => _mutex.protect(() async {
    await _closeDatabase();
    await _deleteDatabaseFiles(_databaseFile);
    await _deleteDatabaseFiles(_rekeyBackupFile);
  });

  Future<void> beginRekey({
    required List<int> oldEncryptionKey,
    required List<int> newEncryptionKey,
  }) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    await _closeDatabase();
    await _deleteDatabaseFiles(_rekeyBackupFile);
    await _databaseFile.copy(_rekeyBackupFile.path);

    try {
      _database = await _openDatabase(_databaseFile, oldEncryptionKey);
      await _database!.rekey(newEncryptionKey);
      await _closeDatabase();
      _database = await _openDatabase(_databaseFile, newEncryptionKey);
    } catch (_) {
      await _restoreRekeyBackup(oldEncryptionKey);
      rethrow;
    }
  });

  Future<void> commitRekey() => _mutex.protect(() async {
    try {
      await _deleteDatabaseFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A stale encrypted backup is removed the next time the database opens.
    }
  });

  Future<void> rollbackRekey(List<int> oldEncryptionKey) =>
      _mutex.protect(() => _restoreRekeyBackup(oldEncryptionKey));

  Future<List<HtlcSwapEntry>> readAllSwapEntries(int chainId) =>
      _mutex.protect(() async {
        final HtlcSwapsDatabase database = _requireDatabase();
        return (database.select(
              database.htlcSwapEntries,
            )..where(
              ($HtlcSwapEntriesTable table) => table.chainId.equals(chainId),
            ))
            .get();
      });

  Future<List<HtlcSwapEntry>> readSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    return (database.select(database.htlcSwapEntries)..where(
          ($HtlcSwapEntriesTable table) =>
              table.chainId.equals(chainId) & table.state.isIn(states),
        ))
        .get();
  });

  Future<HtlcSwapEntry?> readSwapEntryByHashLock(
    int chainId,
    String hashLock,
  ) => _readSingleSwapEntry(
    ($HtlcSwapEntriesTable table) =>
        table.chainId.equals(chainId) & table.hashLock.equals(hashLock),
  );

  Future<HtlcSwapEntry?> readSwapEntryByHtlcId(int chainId, String htlcId) =>
      _readSingleSwapEntry(
        ($HtlcSwapEntriesTable table) =>
            table.chainId.equals(chainId) &
            (table.initialHtlcId.equals(htlcId) |
                table.counterHtlcId.equals(htlcId)),
      );

  Future<HtlcSwapEntry?> readSwapEntryById(int chainId, String id) =>
      _readSingleSwapEntry(
        ($HtlcSwapEntriesTable table) =>
            table.chainId.equals(chainId) & table.id.equals(id),
      );

  Future<int> readLastCheckedHtlcBlockHeight(int chainId) =>
      _mutex.protect(() async {
        final HtlcSwapsDatabase database = _requireDatabase();
        final HtlcScanCheckpoint? checkpoint =
            await (database.select(
                  database.htlcScanCheckpoints,
                )..where(
                  ($HtlcScanCheckpointsTable table) =>
                      table.chainId.equals(chainId),
                ))
                .getSingleOrNull();
        return checkpoint?.lastCheckedHeight ?? 0;
      });

  Future<void> writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await database.transaction(() async {
      await database
          .into(database.htlcSwapEntries)
          .insertOnConflictUpdate(entry);
      await _pruneSwapHistoryIfNeeded(
        database,
        maximumStoredSwaps: maximumStoredSwaps,
        pruneChainId: pruneChainId,
        prunableStates: prunableStates,
      );
    });
  });

  Future<void> writeLastCheckedHtlcBlockHeight(
    int chainId,
    int height,
  ) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await database
        .into(database.htlcScanCheckpoints)
        .insertOnConflictUpdate(
          HtlcScanCheckpointsCompanion.insert(
            chainId: Value<int>(chainId),
            lastCheckedHeight: height,
          ),
        );
  });

  Future<void> deleteSwapEntry(String swapId) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await (database.delete(
      database.htlcSwapEntries,
    )..where(($HtlcSwapEntriesTable table) => table.id.equals(swapId))).go();
  });

  Future<void> deleteSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await (database.delete(database.htlcSwapEntries)..where(
          ($HtlcSwapEntriesTable table) =>
              table.chainId.equals(chainId) & table.state.isIn(states),
        ))
        .go();
  });

  Future<HtlcSwapEntry?> _readSingleSwapEntry(
    Expression<bool> Function($HtlcSwapEntriesTable table) predicate,
  ) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    return (database.select(database.htlcSwapEntries)
          ..where(predicate)
          ..limit(1))
        .getSingleOrNull();
  });

  Future<void> _pruneSwapHistoryIfNeeded(
    HtlcSwapsDatabase database, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) async {
    final Expression<int> count = database.htlcSwapEntries.id.count();
    final TypedResult countResult = await (database.selectOnly(
      database.htlcSwapEntries,
    )..addColumns(<Expression<Object>>[count])).getSingle();
    if ((countResult.read(count) ?? 0) <= maximumStoredSwaps ||
        pruneChainId == null) {
      return;
    }

    final HtlcSwapEntry? oldest =
        await (database.select(database.htlcSwapEntries)
              ..where(
                ($HtlcSwapEntriesTable table) =>
                    table.chainId.equals(pruneChainId) &
                    table.state.isIn(prunableStates),
              )
              ..orderBy(<OrderingTerm Function($HtlcSwapEntriesTable)>[
                ($HtlcSwapEntriesTable table) =>
                    OrderingTerm.asc(table.startTime),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (oldest != null) {
      await (database.delete(
            database.htlcSwapEntries,
          )..where(($HtlcSwapEntriesTable table) => table.id.equals(oldest.id)))
          .go();
    }
  }

  HtlcSwapsDatabase _requireDatabase() {
    return _database ??
        (throw StateError('The HTLC swaps database is not open'));
  }

  Future<HtlcSwapsDatabase> _openDatabase(
    File file,
    List<int> encryptionKey,
  ) async {
    final HtlcSwapsDatabase database = HtlcSwapsDatabase.encrypted(
      file,
      encryptionKey,
    );
    try {
      await database.verifyOpen();
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<void> _closeDatabase() async {
    final HtlcSwapsDatabase? database = _database;
    _database = null;
    await database?.close();
  }

  Future<void> _restoreRekeyBackup(List<int> oldEncryptionKey) async {
    await _closeDatabase();
    if (!_rekeyBackupFile.existsSync()) {
      throw StateError('The HTLC swaps rekey backup does not exist');
    }

    await _deleteDatabaseFiles(_databaseFile);
    await _rekeyBackupFile.rename(_databaseFile.path);
    _database = await _openDatabase(_databaseFile, oldEncryptionKey);
  }

  Future<void> _deleteDatabaseFiles(File databaseFile) async {
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File file = File('${databaseFile.path}$suffix');
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
