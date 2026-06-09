import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorite_verse.dart';
import '../models/memorization_status.dart';
import '../models/streak_data.dart';
import '../models/user_progress.dart';

class FirestoreUserDatasource {
  FirestoreUserDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _legacyData(String uid) =>
      _userDoc(uid).collection('data');

  CollectionReference<Map<String, dynamic>> _favoritesCol(String uid) =>
      _userDoc(uid).collection('favorites');

  CollectionReference<Map<String, dynamic>> _progressCol(String uid) =>
      _userDoc(uid).collection('progress');

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  FavoriteVerse _favoriteFromMap(Map<String, dynamic> map) {
    return FavoriteVerse(
      verseId: map['verseId'] as String? ?? '',
      addedAt: _parseDateTime(map['addedAt']),
      reference: map['reference'] as String?,
      text: map['text'] as String?,
      translation: map['translation'] as String?,
    );
  }

  UserProgress _progressFromMap(Map<String, dynamic> map) {
    return UserProgress(
      verseId: map['verseId'] as String? ?? '',
      status: MemorizationStatus.fromString(map['status'] as String?),
      percent: (map['percent'] as num?)?.toInt() ?? 0,
      lastPracticedAt: _parseDateTime(map['lastPracticedAt']),
      repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 0,
      reference: map['reference'] as String?,
    );
  }

  /// Reads favorites subcollection; falls back to legacy data/favorites doc.
  Future<List<FavoriteVerse>> getFavorites(String uid) async {
    final subSnap = await _favoritesCol(uid)
        .orderBy('addedAt', descending: true)
        .get();

    if (subSnap.docs.isNotEmpty) {
      return subSnap.docs
          .map((doc) => _favoriteFromMap({...doc.data(), 'verseId': doc.id}))
          .toList();
    }

    final legacy = await _legacyData(uid).doc('favorites').get();
    if (!legacy.exists) return [];
    final list = legacy.data()?['items'] as List<dynamic>? ?? [];
    return list
        .map((e) => _favoriteFromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setFavorites(String uid, List<FavoriteVerse> favorites) async {
    await _legacyData(uid).doc('favorites').set({
      'items': favorites.map((f) => f.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads progress subcollection; falls back to legacy data/progress doc.
  Future<List<UserProgress>> getProgress(String uid) async {
    final subSnap = await _progressCol(uid).get();

    if (subSnap.docs.isNotEmpty) {
      return subSnap.docs
          .map((doc) => _progressFromMap({...doc.data(), 'verseId': doc.id}))
          .toList();
    }

    final legacy = await _legacyData(uid).doc('progress').get();
    if (!legacy.exists) return [];
    final list = legacy.data()?['items'] as List<dynamic>? ?? [];
    return list
        .map((e) => _progressFromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setProgress(String uid, List<UserProgress> progress) async {
    await _legacyData(uid).doc('progress').set({
      'items': progress.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads streak from user profile; falls back to legacy data/streak doc.
  Future<StreakData> getStreak(String uid) async {
    final userSnap = await _userDoc(uid).get();
    final streakMap = userSnap.data()?['streak'] as Map<String, dynamic>?;
    if (streakMap != null) {
      return StreakData.fromMap(streakMap);
    }

    final legacy = await _legacyData(uid).doc('streak').get();
    return StreakData.fromMap(legacy.data());
  }

  Future<void> setStreak(String uid, StreakData streak) async {
    await _userDoc(uid).set(
      {
        'streak': streak.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
