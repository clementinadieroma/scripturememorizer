import 'package:firebase_auth/firebase_auth.dart';

import '../datasources/cloud_functions_datasource.dart';
import '../datasources/firestore_user_datasource.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/favorite_verse.dart';
import '../models/verse.dart';

class FavoritesRepository {
  FavoritesRepository(
    this._local,
    this._firestore,
    this._cloudFunctions,
  );

  final LocalStorageDatasource _local;
  final FirestoreUserDatasource? _firestore;
  final CloudFunctionsDatasource? _cloudFunctions;

  String _userKey(User? user) => user?.uid ?? 'guest';

  Future<List<FavoriteVerse>> getFavorites(User? user) async {
    final key = _userKey(user);
    if (user != null && _firestore != null) {
      try {
        final remote = await _firestore!.getFavorites(user.uid);
        await _local.saveFavorites(
          key,
          remote.map((f) => f.toMap()).toList(),
        );
        return remote;
      } catch (_) {
        // Fall back to local
      }
    }
    final maps = await _local.getFavorites(key);
    return maps.map(FavoriteVerse.fromMap).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> addFavorite(User? user, Verse verse) async {
    if (user != null && _cloudFunctions != null) {
      try {
        await _cloudFunctions!.toggleFavorite(
          verseId: verse.id,
          reference: verse.displayReference,
          text: verse.text,
          translation: verse.translation,
          book: verse.book,
          chapter: verse.chapter,
          verse: verse.verse,
          add: true,
        );
        await getFavorites(user);
        return;
      } catch (_) {
        // Fall back to local + legacy Firestore
      }
    }

    final favorites = await getFavorites(user);
    if (favorites.any((f) => f.verseId == verse.id)) return;

    favorites.insert(0, FavoriteVerse.fromVerse(verse));
    await _persistLocal(user, favorites);
  }

  Future<void> removeFavorite(User? user, String verseId) async {
    if (user != null && _cloudFunctions != null) {
      try {
        await _cloudFunctions!.toggleFavorite(
          verseId: verseId,
          reference: '',
          text: '',
          translation: 'WEB',
          add: false,
        );
        await getFavorites(user);
        return;
      } catch (_) {
        // Fall back to local + legacy Firestore
      }
    }

    final favorites = await getFavorites(user);
    favorites.removeWhere((f) => f.verseId == verseId);
    await _persistLocal(user, favorites);
  }

  Future<bool> isFavorite(User? user, String verseId) async {
    final favorites = await getFavorites(user);
    return favorites.any((f) => f.verseId == verseId);
  }

  Future<void> _persistLocal(User? user, List<FavoriteVerse> favorites) async {
    final key = _userKey(user);
    await _local.saveFavorites(
      key,
      favorites.map((f) => f.toMap()).toList(),
    );
    if (user != null && _firestore != null) {
      try {
        await _firestore!.setFavorites(user.uid, favorites);
      } catch (_) {}
    }
  }
}
