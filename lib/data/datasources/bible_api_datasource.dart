import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../models/verse.dart';

class BibleApiDatasource {
  BibleApiDatasource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.bibleApiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  final Dio _dio;

  Future<Verse> fetchVerse(
    String reference, {
    String translation = AppConstants.defaultTranslation,
  }) async {
    final encodedRef = Uri.encodeComponent(reference.replaceAll(' ', '+'));
    final path = translation == AppConstants.defaultTranslation
        ? '/$encodedRef'
        : '/$encodedRef?translation=$translation';

    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data;
    if (data == null) {
      throw Exception('No verse data returned for $reference');
    }
    return Verse.fromBibleApiJson(data);
  }

  Future<List<Verse>> fetchCuratedVerses() async {
    final verses = <Verse>[];
    for (final ref in AppConstants.curatedReferences) {
      try {
        verses.add(await fetchVerse(ref));
      } catch (_) {
        // Skip failed fetches in curated list
      }
    }
    return verses;
  }

  Future<List<Verse>> searchVerses(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Reference pattern: "John 3:16"
    final refMatch = RegExp(
      r'^([\d\s\w]+?)\s+(\d+):(\d+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (refMatch != null) {
      final verse = await fetchVerse(trimmed);
      return [verse];
    }

    // Keyword: search curated + book name matches
    final lower = trimmed.toLowerCase();
    final curated = await fetchCuratedVerses();
    return curated
        .where(
          (v) =>
              v.text.toLowerCase().contains(lower) ||
              v.book.toLowerCase().contains(lower) ||
              v.displayReference.toLowerCase().contains(lower),
        )
        .toList();
  }
}
