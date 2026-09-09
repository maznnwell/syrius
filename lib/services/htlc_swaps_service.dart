import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapsService {
  HtlcSwapsService({File? databaseFile}) : _databaseFileOverride = databaseFile;

  static HtlcSwapsService? _instance;

  static HtlcSwapsService getInstance() {
    _instance ??= HtlcSwapsService();
    return _instance!;
  }

  final File? _databaseFileOverride;
  final Mutex _mutex = Mutex();

  HtlcSwapsDatabase? _database;

  File get _databaseFile =>
      _databaseFileOverride ??
      File(path.join(znnDefaultPaths.cache.path, kHtlcSwapsDatabase));

  File get _rekeyBackupFile => File('${_databaseFile.path}.rekey-backup');

  bool get isOpen => _database != null;

  Future<void> open(List<int> encryptionKey) => _mutex.protect(() async {
    if (_database != null) {
      return;
    }

    await _databaseFile.parent.create(recursive: true);
    try {
      _database = await _openDatabase(_databaseFile, encryptionKey);
    } catch (_) {
      if (!await _rekeyBackupFile.exists()) {
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

  Future<void> close() => _mutex.protect(() async {
    await _closeDatabase();
  });

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

  Future<List<HtlcSwap>> getAllSwaps() async {
    final int? chainId = kNodeChainId;
    if (chainId == null) {
      return <HtlcSwap>[];
    }

    return _mutex.protect(() async {
      final HtlcSwapsDatabase database = _requireDatabase();
      final List<HtlcSwapEntry> entries = await (database.select(
        database.htlcSwapEntries,
      )..where((table) => table.chainId.equals(chainId))).get();
      return entries.map(_decodeSwap).toList();
    });
  }

  Future<List<HtlcSwap>> getSwapsByState(
    List<P2pSwapState> states,
  ) async {
    final int? chainId = kNodeChainId;
    if (chainId == null || states.isEmpty) {
      return <HtlcSwap>[];
    }

    return _mutex.protect(() async {
      final HtlcSwapsDatabase database = _requireDatabase();
      final List<HtlcSwapEntry> entries =
          await (database.select(
                database.htlcSwapEntries,
              )..where(
                (table) =>
                    table.chainId.equals(chainId) &
                    table.state.isIn(states.map((state) => state.name)),
              ))
              .get();
      return entries.map(_decodeSwap).toList();
    });
  }

  Future<HtlcSwap?> getSwapByHashLock(String hashLock) {
    return _getSingleSwap(
      (table, chainId) =>
          table.chainId.equals(chainId) & table.hashLock.equals(hashLock),
    );
  }

  Future<HtlcSwap?> getSwapByHtlcId(String htlcId) {
    return _getSingleSwap(
      (table, chainId) =>
          table.chainId.equals(chainId) &
          (table.initialHtlcId.equals(htlcId) |
              table.counterHtlcId.equals(htlcId)),
    );
  }

  Future<HtlcSwap?> getSwapById(String id) {
    return _getSingleSwap(
      (table, chainId) => table.chainId.equals(chainId) & table.id.equals(id),
    );
  }

  Future<int> getLastCheckedHtlcBlockHeight() async {
    final int? chainId = kNodeChainId;
    if (chainId == null) {
      return 0;
    }

    return _mutex.protect(() async {
      final HtlcSwapsDatabase database = _requireDatabase();
      final HtlcScanCheckpoint? checkpoint = await (database.select(
        database.htlcScanCheckpoints,
      )..where((table) => table.chainId.equals(chainId))).getSingleOrNull();
      return checkpoint?.lastCheckedHeight ?? 0;
    });
  }

  Future<void> storeSwap(HtlcSwap swap) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await database.transaction(() async {
      await database
          .into(database.htlcSwapEntries)
          .insertOnConflictUpdate(
            HtlcSwapEntriesCompanion.insert(
              id: swap.id,
              chainId: swap.chainId,
              state: swap.state.name,
              direction: swap.direction.name,
              hashLock: swap.hashLock,
              initialHtlcId: swap.initialHtlcId,
              counterHtlcId: Value<String?>(swap.counterHtlcId),
              startTime: swap.startTime,
              payloadJson: jsonEncode(swap.toJson()),
            ),
          );
      await _pruneSwapsHistoryIfNeeded(database);
    });
  });

  Future<void> storeLastCheckedHtlcBlockHeight(int height) async {
    final int? chainId = kNodeChainId;
    if (chainId == null) {
      throw StateError('Cannot store an HTLC checkpoint without a chain id');
    }

    await _mutex.protect(() async {
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
  }

  Future<void> deleteSwap(String swapId) => _mutex.protect(() async {
    final HtlcSwapsDatabase database = _requireDatabase();
    await (database.delete(
      database.htlcSwapEntries,
    )..where((table) => table.id.equals(swapId))).go();
  });

  Future<void> deleteInactiveSwaps() async {
    final int? chainId = kNodeChainId;
    if (chainId == null) {
      return;
    }

    await _mutex.protect(() async {
      final HtlcSwapsDatabase database = _requireDatabase();
      await (database.delete(database.htlcSwapEntries)..where(
            (table) =>
                table.chainId.equals(chainId) &
                table.state.isIn(<String>[
                  P2pSwapState.completed.name,
                  P2pSwapState.unsuccessful.name,
                  P2pSwapState.error.name,
                ]),
          ))
          .go();
    });
  }

  Future<HtlcSwap?> _getSingleSwap(
    Expression<bool> Function($HtlcSwapEntriesTable table, int chainId)
    predicate,
  ) async {
    final int? chainId = kNodeChainId;
    if (chainId == null) {
      return null;
    }

    return _mutex.protect(() async {
      final HtlcSwapsDatabase database = _requireDatabase();
      final HtlcSwapEntry? entry =
          await (database.select(database.htlcSwapEntries)
                ..where((table) => predicate(table, chainId))
                ..limit(1))
              .getSingleOrNull();
      return entry == null ? null : _decodeSwap(entry);
    });
  }

  Future<void> _pruneSwapsHistoryIfNeeded(
    HtlcSwapsDatabase database,
  ) async {
    final Expression<int> count = database.htlcSwapEntries.id.count();
    final TypedResult countResult = await (database.selectOnly(
      database.htlcSwapEntries,
    )..addColumns(<Expression<Object>>[count])).getSingle();
    if ((countResult.read(count) ?? 0) <= kMaxP2pSwapsToStore) {
      return;
    }

    final int? chainId = kNodeChainId;
    if (chainId == null) {
      return;
    }

    final HtlcSwapEntry? oldest =
        await (database.select(database.htlcSwapEntries)
              ..where(
                (table) =>
                    table.chainId.equals(chainId) &
                    table.state.isIn(<String>[
                      P2pSwapState.completed.name,
                      P2pSwapState.unsuccessful.name,
                    ]),
              )
              ..orderBy(<OrderingTerm Function($HtlcSwapEntriesTable)>[
                (table) => OrderingTerm.asc(table.startTime),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (oldest != null) {
      await (database.delete(
        database.htlcSwapEntries,
      )..where((table) => table.id.equals(oldest.id))).go();
    }
  }

  HtlcSwap _decodeSwap(HtlcSwapEntry entry) {
    return P2pSwap.fromJson(
          jsonDecode(entry.payloadJson) as Map<String, dynamic>,
        )
        as HtlcSwap;
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
    if (!await _rekeyBackupFile.exists()) {
      throw StateError('The HTLC swaps rekey backup does not exist');
    }

    await _deleteDatabaseFiles(_databaseFile);
    await _rekeyBackupFile.rename(_databaseFile.path);
    _database = await _openDatabase(_databaseFile, oldEncryptionKey);
  }

  Future<void> _deleteDatabaseFiles(File databaseFile) async {
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File file = File('${databaseFile.path}$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
