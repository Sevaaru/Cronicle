import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/achievements/domain/achievement.dart';

const _kStateKey = 'cronicle_achievements_state_v1';
const _kIncrementCounterKey = 'cronicle_progress_increments_total';
const _kWearCounterKey = 'cronicle_wear_updates_total';
const _kNightOwlKey = 'cronicle_used_at_night';

class AchievementState {
  const AchievementState({this.unlockedAt, this.progress = 0});

  final DateTime? unlockedAt;
  final int progress;

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() => {
        'u': unlockedAt?.millisecondsSinceEpoch,
        'p': progress,
      };

  factory AchievementState.fromJson(Map<String, dynamic> j) {
    final u = j['u'];
    return AchievementState(
      unlockedAt: u is int ? DateTime.fromMillisecondsSinceEpoch(u) : null,
      progress: (j['p'] as num?)?.toInt() ?? 0,
    );
  }

  AchievementState copyWith({DateTime? unlockedAt, int? progress}) =>
      AchievementState(
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
      );
}

class AchievementsNotifier
    extends Notifier<Map<String, AchievementState>> {
  final _unlockController = StreamController<Achievement>.broadcast();

  Stream<Achievement> get unlockStream => _unlockController.stream;

  @override
  Map<String, AchievementState> build() {
    ref.onDispose(_unlockController.close);
    final prefs = ref.read(sharedPreferencesProvider);
    return _loadFromPrefs(prefs);
  }

  static Map<String, AchievementState> _loadFromPrefs(
      SharedPreferences prefs) {
    final raw = prefs.getString(_kStateKey);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          AchievementState.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = jsonEncode(state.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_kStateKey, json);
  }

  /// Apply evaluation results. Returns the achievements that were just unlocked.
  Future<List<Achievement>> applyContext(AchievementContext ctx) async {
    final newState = Map<String, AchievementState>.from(state);
    final unlocked = <Achievement>[];

    // Two-pass so platinum sees other unlocks in same evaluation.
    for (final a in AchievementCatalog.all) {
      if (a.tier == AchievementTier.platinum) continue;
      final cur = newState[a.id] ?? const AchievementState();
      if (cur.isUnlocked) continue;
      final progress = a.evaluate(ctx).clamp(0, a.target);
      if (progress >= a.target) {
        newState[a.id] = cur.copyWith(
          progress: a.target,
          unlockedAt: DateTime.now(),
        );
        unlocked.add(a);
      } else if (progress != cur.progress) {
        newState[a.id] = cur.copyWith(progress: progress);
      }
    }

    // Re-build context with the freshly unlocked count for platinum check.
    final unlockedCount = newState.values.where((s) => s.isUnlocked).length;
    final ctxForPlat = AchievementContext(
      entries: ctx.entries,
      completedCount: ctx.completedCount,
      totalCount: ctx.totalCount,
      kindCounts: ctx.kindCounts,
      notesCount: ctx.notesCount,
      scoredCount: ctx.scoredCount,
      totalAnimeProgress: ctx.totalAnimeProgress,
      totalChapterProgress: ctx.totalChapterProgress,
      completedBooks: ctx.completedBooks,
      completedGames: ctx.completedGames,
      completedAnime: ctx.completedAnime,
      completedMangaSeries: ctx.completedMangaSeries,
      completedMoviesAndShows: ctx.completedMoviesAndShows,
      progressIncrementsTotal: ctx.progressIncrementsTotal,
      wearUpdatesTotal: ctx.wearUpdatesTotal,
      usedAtNight: ctx.usedAtNight,
      unlockedCount: unlockedCount,
      totalAchievementsExceptPlatinum: AchievementCatalog.nonPlatinumCount,
    );

    for (final a in AchievementCatalog.all) {
      if (a.tier != AchievementTier.platinum) continue;
      final cur = newState[a.id] ?? const AchievementState();
      if (cur.isUnlocked) continue;
      final progress = a.evaluate(ctxForPlat);
      if (progress >= a.target) {
        newState[a.id] = cur.copyWith(
          progress: a.target,
          unlockedAt: DateTime.now(),
        );
        unlocked.add(a);
      }
    }

    if (!mapEquals(state, newState)) {
      state = newState;
      await _persist();
    }

    for (final a in unlocked) {
      // Subtle haptic ping per unlock.
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      _unlockController.add(a);
    }
    return unlocked;
  }

  /// Called from UI after a +1 / increment action.
  Future<void> bumpProgressIncrement() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cur = prefs.getInt(_kIncrementCounterKey) ?? 0;
    await prefs.setInt(_kIncrementCounterKey, cur + 1);
  }

  /// Reset state (debug/dev). Not exposed in UI by default.
  Future<void> resetAll() async {
    state = const {};
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kStateKey);
    await prefs.setInt(_kIncrementCounterKey, 0);
    await prefs.setInt(_kWearCounterKey, 0);
    await prefs.setBool(_kNightOwlKey, false);
  }

  /// Forces re-load from prefs (used after backup restore).
  void reloadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = _loadFromPrefs(prefs);
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, Map<String, AchievementState>>(
  AchievementsNotifier.new,
);

/// Build a snapshot from current DB + counters and evaluate.
class AchievementsEvaluator {
  AchievementsEvaluator(this.ref);
  final Ref ref;

  Future<List<Achievement>> evaluateNow() async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final entries = await db.getAllLibraryEntries();

    final ctx = _buildContext(entries, prefs, unlockedCountSeed: 0);
    return ref.read(achievementsProvider.notifier).applyContext(ctx);
  }

  AchievementContext _buildContext(
    List<LibraryEntry> entries,
    SharedPreferences prefs, {
    required int unlockedCountSeed,
  }) {
    final kindCounts = <int, int>{};
    var completed = 0;
    var notes = 0;
    var scored = 0;
    var totalAnimeProgress = 0;
    var totalChapterProgress = 0;
    var completedBooks = 0;
    var completedGames = 0;
    var completedAnime = 0;
    var completedMangaSeries = 0;
    var completedMoviesAndShows = 0;

    for (final e in entries) {
      kindCounts[e.kind] = (kindCounts[e.kind] ?? 0) + 1;
      final status = e.status.toUpperCase();
      final isCompleted = status == 'COMPLETED';
      if (isCompleted) completed++;
      if ((e.notes ?? '').trim().isNotEmpty) notes++;
      if (e.score != null && e.score! > 0) scored++;

      // anime episodes contributions
      if (e.kind == 0) {
        totalAnimeProgress += (e.progress ?? 0);
        if (isCompleted) completedAnime++;
      }
      // manga / book chapter+pages contributions
      if (e.kind == 4) {
        totalChapterProgress += (e.progress ?? 0);
        if (isCompleted) completedMangaSeries++;
      }
      if (e.kind == 5) {
        // book pages (or chapters when chapter mode)
        totalChapterProgress += (e.currentChapter ?? e.progress ?? 0);
        if (isCompleted) completedBooks++;
      }
      if (e.kind == 3 && isCompleted) completedGames++;
      if ((e.kind == 1 || e.kind == 2) && isCompleted) {
        completedMoviesAndShows++;
      }
    }

    return AchievementContext(
      entries: entries.length,
      totalCount: entries.length,
      completedCount: completed,
      kindCounts: kindCounts,
      notesCount: notes,
      scoredCount: scored,
      totalAnimeProgress: totalAnimeProgress,
      totalChapterProgress: totalChapterProgress,
      completedBooks: completedBooks,
      completedGames: completedGames,
      completedAnime: completedAnime,
      completedMangaSeries: completedMangaSeries,
      completedMoviesAndShows: completedMoviesAndShows,
      progressIncrementsTotal: prefs.getInt(_kIncrementCounterKey) ?? 0,
      wearUpdatesTotal: prefs.getInt(_kWearCounterKey) ?? 0,
      usedAtNight: prefs.getBool(_kNightOwlKey) ?? false,
      unlockedCount: unlockedCountSeed,
      totalAchievementsExceptPlatinum: AchievementCatalog.nonPlatinumCount,
    );
  }
}

final achievementsEvaluatorProvider = Provider<AchievementsEvaluator>(
  (ref) => AchievementsEvaluator(ref),
);

/// Helpers for non-UI callers (e.g. wear isolate, app boot).
abstract final class AchievementsCounters {
  static Future<void> bumpProgressIncrement(SharedPreferences prefs) async {
    final cur = prefs.getInt(_kIncrementCounterKey) ?? 0;
    await prefs.setInt(_kIncrementCounterKey, cur + 1);
  }

  static Future<void> bumpWearUpdate(SharedPreferences prefs) async {
    final cur = prefs.getInt(_kWearCounterKey) ?? 0;
    await prefs.setInt(_kWearCounterKey, cur + 1);
  }

  static Future<void> markUsedAtNightIfApplicable(
      SharedPreferences prefs) async {
    if (prefs.getBool(_kNightOwlKey) == true) return;
    final h = DateTime.now().hour;
    if (h >= 0 && h < 4) {
      await prefs.setBool(_kNightOwlKey, true);
    }
  }
}
