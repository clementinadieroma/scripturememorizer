import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../datasources/cloud_functions_datasource.dart';
import '../datasources/firestore_user_datasource.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/memorization_status.dart';
import '../models/streak_data.dart';
import '../models/user_progress.dart';
import '../models/user_stats.dart';
import '../models/verse.dart';

class ProgressRepository {
  ProgressRepository(
    this._local,
    this._firestore,
    this._cloudFunctions,
  );

  final LocalStorageDatasource _local;
  final FirestoreUserDatasource? _firestore;
  final CloudFunctionsDatasource? _cloudFunctions;
  final _uuid = const Uuid();

  String _userKey(User? user) => user?.uid ?? 'guest';

  Future<List<UserProgress>> getAllProgress(User? user) async {
    final key = _userKey(user);
    if (user != null && _firestore != null) {
      try {
        final remote = await _firestore!.getProgress(user.uid);
        await _local.saveProgress(
          key,
          remote.map((p) => p.toMap()).toList(),
        );
        return remote;
      } catch (_) {}
    }
    final maps = await _local.getProgress(key);
    return maps.map(UserProgress.fromMap).toList();
  }

  Future<UserProgress?> getProgressForVerse(User? user, String verseId) async {
    final all = await getAllProgress(user);
    try {
      return all.firstWhere((p) => p.verseId == verseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> recordPractice(
    User? user,
    Verse verse, {
    int percentDelta = 10,
    bool completedSession = false,
    int loopsCompleted = 0,
    String lastMode = 'repeat',
    int? durationSeconds,
  }) async {
    if (user != null && _cloudFunctions != null) {
      try {
        await _recordViaCloudFunction(
          user,
          verse,
          percentDelta: percentDelta,
          completedSession: completedSession,
          loopsCompleted: loopsCompleted,
          lastMode: lastMode,
          durationSeconds: durationSeconds,
        );
        return;
      } catch (_) {
        // Fall back to local logic
      }
    }

    await _recordLocally(
      user,
      verse,
      percentDelta: percentDelta,
      completedSession: completedSession,
      loopsCompleted: loopsCompleted,
    );
  }

  Future<void> _recordViaCloudFunction(
    User user,
    Verse verse, {
    required int percentDelta,
    required bool completedSession,
    required int loopsCompleted,
    required String lastMode,
    int? durationSeconds,
  }) async {
    final existing = await getProgressForVerse(user, verse.id);
    var percent = (existing?.percent ?? 0) + percentDelta;
    if (completedSession) {
      percent = (percent + 15).clamp(0, 100);
    }
    percent = percent.clamp(0, 100);

    MemorizationStatus status;
    if (percent >= 100 || (completedSession && percent >= 80)) {
      status = MemorizationStatus.memorized;
      percent = 100;
    } else if (existing == null ||
        existing.status == MemorizationStatus.notStarted) {
      status = MemorizationStatus.inProgress;
    } else {
      status = existing.status;
      if (status == MemorizationStatus.notStarted) {
        status = MemorizationStatus.inProgress;
      }
    }

    final resolvedDuration = durationSeconds ??
        (loopsCompleted > 0 ? loopsCompleted * 20 : 30);

    final response = await _cloudFunctions!.updateMemorizationProgress(
      verseId: verse.id,
      reference: verse.displayReference,
      status: status.toStorageString(),
      percent: percent,
      repeatCountDelta: loopsCompleted,
      loopsCompleted: loopsCompleted > 0 ? loopsCompleted : null,
      lastMode: lastMode,
      durationSeconds: resolvedDuration,
      completed: completedSession || loopsCompleted > 0 || percentDelta > 0,
      clientId: _uuid.v4(),
    );

    final progressMap = response['progress'] as Map<dynamic, dynamic>?;
    final streakMap = response['streak'] as Map<dynamic, dynamic>?;

    if (progressMap != null) {
      final all = await getAllProgress(user);
      final updated = UserProgress.fromMap(
        Map<String, dynamic>.from(progressMap),
      );
      all.removeWhere((p) => p.verseId == verse.id);
      all.add(updated);
      await _local.saveProgress(
        user.uid,
        all.map((p) => p.toMap()).toList(),
      );
    }

    if (streakMap != null) {
      await _local.saveStreak(
        user.uid,
        Map<String, dynamic>.from(streakMap),
      );
    }
  }

  Future<void> _recordLocally(
    User? user,
    Verse verse, {
    required int percentDelta,
    required bool completedSession,
    required int loopsCompleted,
  }) async {
    final all = await getAllProgress(user);
    UserProgress? existing;
    for (final p in all) {
      if (p.verseId == verse.id) {
        existing = p;
        break;
      }
    }
    final now = DateTime.now();

    UserProgress updated;
    if (existing == null) {
      updated = UserProgress(
        verseId: verse.id,
        status: MemorizationStatus.inProgress,
        percent: percentDelta.clamp(0, 100),
        lastPracticedAt: now,
        repeatCount: loopsCompleted,
        reference: verse.displayReference,
      );
      all.add(updated);
    } else {
      var percent = existing.percent + percentDelta;
      if (completedSession) percent = (percent + 15).clamp(0, 100);
      var status = existing.status;
      if (percent >= 100 || completedSession && percent >= 80) {
        status = MemorizationStatus.memorized;
        percent = 100;
      } else if (status == MemorizationStatus.notStarted) {
        status = MemorizationStatus.inProgress;
      }

      updated = existing.copyWith(
        status: status,
        percent: percent.clamp(0, 100),
        lastPracticedAt: now,
        repeatCount: existing.repeatCount + loopsCompleted,
        reference: verse.displayReference,
      );
      all.removeWhere((p) => p.verseId == verse.id);
      all.add(updated);
    }

    await _persistProgress(user, all);
    await _updateStreakLocally(user);
  }

  Future<StreakData> getStreak(User? user) async {
    final key = _userKey(user);
    if (user != null && _firestore != null) {
      try {
        final streak = await _firestore!.getStreak(user.uid);
        await _local.saveStreak(key, streak.toMap());
        return streak;
      } catch (_) {}
    }
    final map = await _local.getStreak(key);
    return StreakData.fromMap(map);
  }

  /// Fetch dashboard stats from Cloud Functions (signed-in users only).
  Future<UserStats?> getUserStats(User? user, {bool recalculate = false}) async {
    if (user == null || _cloudFunctions == null) return null;

    try {
      final response = await _cloudFunctions!.getUserStats(
        recalculate: recalculate,
      );
      final statsMap = response['stats'] as Map<dynamic, dynamic>?;
      final streakMap = response['streak'] as Map<dynamic, dynamic>?;

      if (streakMap != null) {
        await _local.saveStreak(
          user.uid,
          Map<String, dynamic>.from(streakMap),
        );
      }

      return UserStats.fromMap(
        statsMap != null ? Map<String, dynamic>.from(statsMap) : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateStreakLocally(User? user) async {
    final key = _userKey(user);
    var streak = await getStreak(user);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (streak.lastActivityDate == null) {
      streak = streak.copyWith(
        currentCount: 1,
        longestCount: 1,
        lastActivityDate: todayDate,
      );
    } else {
      final last = DateTime(
        streak.lastActivityDate!.year,
        streak.lastActivityDate!.month,
        streak.lastActivityDate!.day,
      );
      final diff = todayDate.difference(last).inDays;
      if (diff == 0) {
        return;
      } else if (diff == 1) {
        final newCurrent = streak.currentCount + 1;
        streak = streak.copyWith(
          currentCount: newCurrent,
          longestCount: newCurrent > streak.longestCount
              ? newCurrent
              : streak.longestCount,
          lastActivityDate: todayDate,
        );
      } else {
        streak = streak.copyWith(
          currentCount: 1,
          lastActivityDate: todayDate,
        );
      }
    }

    await _local.saveStreak(key, streak.toMap());
    if (user != null && _firestore != null) {
      try {
        await _firestore!.setStreak(user.uid, streak);
      } catch (_) {}
    }
  }

  Future<void> _persistProgress(
    User? user,
    List<UserProgress> progress,
  ) async {
    final key = _userKey(user);
    await _local.saveProgress(
      key,
      progress.map((p) => p.toMap()).toList(),
    );
    if (user != null && _firestore != null) {
      try {
        await _firestore!.setProgress(user.uid, progress);
      } catch (_) {}
    }
  }

  Future<int> memorizedCount(User? user) async {
    final stats = await getUserStats(user, recalculate: false);
    if (stats != null) return stats.versesMemorizedCount;

    final all = await getAllProgress(user);
    return all.where((p) => p.status == MemorizationStatus.memorized).length;
  }
}
