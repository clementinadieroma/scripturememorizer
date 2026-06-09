import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/bible_api_datasource.dart';
import '../datasources/cloud_functions_datasource.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/verse.dart';

class DailyVerseRepository {
  DailyVerseRepository(
    this._api,
    this._local,
    this._cloudFunctions,
  );

  final BibleApiDatasource _api;
  final LocalStorageDatasource _local;
  final CloudFunctionsDatasource? _cloudFunctions;

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<Verse> getDailyVerse() async {
    final today = _todayKey();
    final cachedDate = await _local.getCachedDailyVerseDate();
    final cached = await _local.getCachedDailyVerse();

    if (cachedDate == today && cached != null) {
      return Verse.fromBibleApiJson(cached);
    }

    if (_cloudFunctions != null) {
      try {
        final response = await _cloudFunctions!.getDailyVerse(
          timezone: DateTime.now().timeZoneName,
        );
        final dailyMap = response['dailyVerse'] as Map<dynamic, dynamic>?;
        if (dailyMap != null) {
          final verse = _verseFromDailyVerse(Map<String, dynamic>.from(dailyMap));
          await _local.cacheDailyVerse(
            {
              'reference': verse.displayReference,
              'text': verse.text,
              'translation_name': verse.translation,
              'verses': [
                {
                  'book_name': verse.book,
                  'chapter': verse.chapter,
                  'verse': verse.verse,
                  'text': verse.text,
                }
              ],
            },
            today,
          );
          return verse;
        }
      } catch (_) {
        // Fall back to Bible API rotation
      }
    }

    return _fetchLocalRotation(today);
  }

  Verse _verseFromDailyVerse(Map<String, dynamic> data) {
    return Verse(
      id: data['verseId'] as String? ?? '',
      translation: data['translation'] as String? ?? 'WEB',
      book: data['book'] as String? ?? '',
      chapter: (data['chapter'] as num?)?.toInt() ?? 1,
      verse: (data['verse'] as num?)?.toInt() ?? 1,
      text: data['text'] as String? ?? '',
      reference: data['reference'] as String?,
    );
  }

  Future<Verse> _fetchLocalRotation(String today) async {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    final index = dayOfYear % AppConstants.curatedReferences.length;
    final reference = AppConstants.curatedReferences[index];

    final verse = await _api.fetchVerse(reference);
    await _local.cacheDailyVerse(
      {
        'reference': verse.displayReference,
        'text': verse.text,
        'translation_name': verse.translation,
        'verses': [
          {
            'book_name': verse.book,
            'chapter': verse.chapter,
            'verse': verse.verse,
            'text': verse.text,
          }
        ],
      },
      today,
    );
    return verse;
  }
}
