import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/loop_session_controller.dart';
import '../core/services/tts_service.dart';
import '../data/datasources/auth_datasource.dart';
import '../data/datasources/bible_api_datasource.dart';
import '../data/datasources/cloud_functions_datasource.dart';
import '../data/datasources/firestore_user_datasource.dart';
import '../data/datasources/local_storage_datasource.dart';
import '../data/models/streak_data.dart';
import '../data/models/user_stats.dart';
import '../data/models/verse.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/daily_verse_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/verse_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in main() after init.',
  );
});

final localStorageProvider = Provider<LocalStorageDatasource>((ref) {
  return LocalStorageDatasource(ref.watch(sharedPreferencesProvider));
});

final bibleApiProvider = Provider<BibleApiDatasource>((ref) {
  return BibleApiDatasource();
});

final cloudFunctionsProvider = Provider<CloudFunctionsDatasource?>((ref) {
  if (kSkipFirebase) return null;
  return CloudFunctionsDatasource();
});

final firestoreUserProvider = Provider<FirestoreUserDatasource?>((ref) {
  if (kSkipFirebase) return null;
  return FirestoreUserDatasource();
});

final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  return AuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authDatasourceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final verseRepositoryProvider = Provider<VerseRepository>((ref) {
  return VerseRepository(ref.watch(bibleApiProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(
    ref.watch(localStorageProvider),
    ref.watch(firestoreUserProvider),
    ref.watch(cloudFunctionsProvider),
  );
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(
    ref.watch(localStorageProvider),
    ref.watch(firestoreUserProvider),
    ref.watch(cloudFunctionsProvider),
  );
});

final dailyVerseRepositoryProvider = Provider<DailyVerseRepository>((ref) {
  return DailyVerseRepository(
    ref.watch(bibleApiProvider),
    ref.watch(localStorageProvider),
    ref.watch(cloudFunctionsProvider),
  );
});

final dailyVerseProvider = FutureProvider<Verse>((ref) {
  return ref.watch(dailyVerseRepositoryProvider).getDailyVerse();
});

final streakProvider = FutureProvider<StreakData>((ref) async {
  final user = ref.watch(currentUserProvider);
  return ref.watch(progressRepositoryProvider).getStreak(user);
});

final userStatsProvider = FutureProvider<UserStats?>((ref) async {
  final user = ref.watch(currentUserProvider);
  return ref.watch(progressRepositoryProvider).getUserStats(user);
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final loopControllerProvider = Provider<LoopSessionController>((ref) {
  return LoopSessionController(ref.watch(ttsServiceProvider));
});
