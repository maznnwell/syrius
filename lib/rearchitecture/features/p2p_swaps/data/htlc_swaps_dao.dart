import 'package:drift/drift.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';

part 'htlc_swaps_dao.g.dart';

@DriftAccessor(tables: <Type>[HtlcSwapEntries, HtlcScanCheckpoints])
class HtlcSwapsDao extends DatabaseAccessor<HtlcSwapsDatabase>
    with _$HtlcSwapsDaoMixin {
  HtlcSwapsDao(super.attachedDatabase);

  Future<List<HtlcSwapEntry>> readAllSwapEntries() =>
      (select(htlcSwapEntries)..orderBy(<
            OrderingTerm Function(
              $HtlcSwapEntriesTable,
            )
          >[
            ($HtlcSwapEntriesTable table) => OrderingTerm.desc(table.startTime),
          ]))
          .get();

  Stream<List<HtlcSwapEntry>> watchAllSwapEntries() =>
      (select(htlcSwapEntries)..orderBy(<
            OrderingTerm Function(
              $HtlcSwapEntriesTable,
            )
          >[
            ($HtlcSwapEntriesTable table) => OrderingTerm.desc(table.startTime),
          ]))
          .watch();

  Future<List<HtlcSwapEntry>> readSwapEntriesByState(
    int chainId,
    List<String> states,
  ) =>
      (select(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) =>
                table.chainId.equals(chainId) & table.state.isIn(states),
          ))
          .get();

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

  Future<HtlcSwapEntry?> readSwapEntryById(String id) => _readSingleSwapEntry(
    ($HtlcSwapEntriesTable table) => table.id.equals(id),
  );

  Future<int> readLastCheckedHtlcBlockHeight(int chainId) async {
    final HtlcScanCheckpoint? checkpoint =
        await (select(htlcScanCheckpoints)..where(
              ($HtlcScanCheckpointsTable table) =>
                  table.chainId.equals(chainId),
            ))
            .getSingleOrNull();
    return checkpoint?.lastCheckedHeight ?? 0;
  }

  Future<void> writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) => transaction(
    () => _writeSwapEntry(
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
  }) => transaction(() async {
    if (updatedEntry != null) {
      if (updatedEntry.chainId != chainId) {
        throw StateError(
          'Cannot store an HTLC swap update for a different chain',
        );
      }
      await _writeSwapEntry(
        updatedEntry,
        maximumStoredSwaps: maximumStoredSwaps,
        pruneChainId: chainId,
        prunableStates: prunableStates,
      );
    }
    await _writeLastCheckedHtlcBlockHeight(chainId, height);
  });

  Future<void> writeLastCheckedHtlcBlockHeight(int chainId, int height) =>
      _writeLastCheckedHtlcBlockHeight(chainId, height);

  Future<void> deleteSwapEntry(String swapId) =>
      (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) => table.id.equals(swapId),
          ))
          .go();

  Future<void> deleteSwapEntriesByState(
    int chainId,
    List<String> states,
  ) =>
      (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) =>
                table.chainId.equals(chainId) & table.state.isIn(states),
          ))
          .go();

  Future<HtlcSwapEntry?> _readSingleSwapEntry(
    Expression<bool> Function($HtlcSwapEntriesTable table) predicate,
  ) =>
      (select(htlcSwapEntries)
            ..where(predicate)
            ..limit(1))
          .getSingleOrNull();

  Future<void> _writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) async {
    await into(htlcSwapEntries).insertOnConflictUpdate(entry);
    await _pruneSwapHistoryIfNeeded(
      maximumStoredSwaps: maximumStoredSwaps,
      pruneChainId: pruneChainId,
      prunableStates: prunableStates,
    );
  }

  Future<void> _writeLastCheckedHtlcBlockHeight(
    int chainId,
    int height,
  ) => into(htlcScanCheckpoints).insertOnConflictUpdate(
    HtlcScanCheckpointsCompanion.insert(
      chainId: Value<int>(chainId),
      lastCheckedHeight: height,
    ),
  );

  Future<void> _pruneSwapHistoryIfNeeded({
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) async {
    final Expression<int> count = htlcSwapEntries.id.count();
    final TypedResult countResult = await (selectOnly(
      htlcSwapEntries,
    )..addColumns(<Expression<Object>>[count])).getSingle();
    if ((countResult.read(count) ?? 0) <= maximumStoredSwaps ||
        pruneChainId == null) {
      return;
    }

    final HtlcSwapEntry? oldest =
        await (select(htlcSwapEntries)
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
      await (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) => table.id.equals(oldest.id),
          ))
          .go();
    }
  }
}
