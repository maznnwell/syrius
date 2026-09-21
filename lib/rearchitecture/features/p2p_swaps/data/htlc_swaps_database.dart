import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hex/hex.dart';
import 'package:sqlite3/src/ffi/api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_dao.dart';

part 'htlc_swaps_database.g.dart';

@TableIndex(name: 'htlc_swaps_chain_state', columns: <Symbol>{#chainId, #state})
@TableIndex(name: 'htlc_swaps_hash_lock', columns: <Symbol>{#hashLock})
@TableIndex(
  name: 'htlc_swaps_initial_htlc_id',
  columns: <Symbol>{#initialHtlcId},
)
@TableIndex(
  name: 'htlc_swaps_counter_htlc_id',
  columns: <Symbol>{#counterHtlcId},
)
@TableIndex(
  name: 'htlc_swaps_chain_start_time',
  columns: <Symbol>{#chainId, #startTime},
)
class HtlcSwapEntries extends Table {
  TextColumn get id => text()();

  IntColumn get chainId => integer()();

  TextColumn get state => text()();

  TextColumn get direction => text()();

  TextColumn get hashLock => text()();

  TextColumn get initialHtlcId => text()();

  TextColumn get counterHtlcId => text().nullable()();

  IntColumn get startTime => integer()();

  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  String get tableName => 'htlc_swaps';
}

class HtlcScanCheckpoints extends Table {
  IntColumn get chainId => integer()();

  IntColumn get lastCheckedHeight => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{chainId};
}

@DriftDatabase(
  tables: <Type>[HtlcSwapEntries, HtlcScanCheckpoints],
  daos: <Type>[HtlcSwapsDao],
)
class HtlcSwapsDatabase extends _$HtlcSwapsDatabase {
  HtlcSwapsDatabase(super.executor);

  factory HtlcSwapsDatabase.encrypted(File file, List<int> encryptionKey) {
    if (encryptionKey.length != 32 ||
        encryptionKey.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
        encryptionKey,
        'encryptionKey',
        'The database encryption key must contain exactly 32 bytes',
      );
    }

    final String keyHex = HEX.encode(encryptionKey);
    return HtlcSwapsDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (Database database) {
          if (database.select('PRAGMA cipher;').isEmpty) {
            throw UnsupportedError(
              'SQLite3MultipleCiphers is required for HTLC swap storage',
            );
          }

          database
            ..execute("PRAGMA cipher = 'sqlcipher';")
            ..execute('PRAGMA legacy = 4;')
            ..execute("PRAGMA hexkey = '$keyHex';")
            ..select('SELECT count(*) FROM sqlite_master;');
        },
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  Future<void> verifyOpen() async {
    await customSelect('SELECT count(*) FROM sqlite_master;').getSingle();
  }

  Future<void> rekey(List<int> encryptionKey) async {
    if (encryptionKey.length != 32 ||
        encryptionKey.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
        encryptionKey,
        'encryptionKey',
        'The database encryption key must contain exactly 32 bytes',
      );
    }

    await customStatement(
      "PRAGMA hexrekey = '${HEX.encode(encryptionKey)}';",
    );
  }
}
