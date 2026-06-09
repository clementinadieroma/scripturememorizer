import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageDatasource {
  LocalStorageDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _favoritesKey = 'favorites_local';
  static const _progressKey = 'progress_local';
  static const _streakKey = 'streak_local';
  static const _dailyVerseKey = 'daily_verse_cache';
  static const _dailyVerseDateKey = 'daily_verse_date';

  Future<List<Map<String, dynamic>>> getFavorites(String userKey) async {
    final raw = _prefs.getString('${_favoritesKey}_$userKey');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveFavorites(
    String userKey,
    List<Map<String, dynamic>> favorites,
  ) async {
    await _prefs.setString(
      '${_favoritesKey}_$userKey',
      jsonEncode(favorites),
    );
  }

  Future<List<Map<String, dynamic>>> getProgress(String userKey) async {
    final raw = _prefs.getString('${_progressKey}_$userKey');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveProgress(
    String userKey,
    List<Map<String, dynamic>> progress,
  ) async {
    await _prefs.setString(
      '${_progressKey}_$userKey',
      jsonEncode(progress),
    );
  }

  Future<Map<String, dynamic>?> getStreak(String userKey) async {
    final raw = _prefs.getString('${_streakKey}_$userKey');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveStreak(String userKey, Map<String, dynamic> streak) async {
    await _prefs.setString('${_streakKey}_$userKey', jsonEncode(streak));
  }

  Future<Map<String, dynamic>?> getCachedDailyVerse() async {
    final raw = _prefs.getString(_dailyVerseKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String?> getCachedDailyVerseDate() async {
    return _prefs.getString(_dailyVerseDateKey);
  }

  Future<void> cacheDailyVerse(Map<String, dynamic> verse, String date) async {
    await _prefs.setString(_dailyVerseKey, jsonEncode(verse));
    await _prefs.setString(_dailyVerseDateKey, date);
  }
}
