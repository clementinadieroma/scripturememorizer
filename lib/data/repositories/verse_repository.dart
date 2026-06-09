import '../datasources/bible_api_datasource.dart';
import '../models/verse.dart';

class VerseRepository {
  VerseRepository(this._api);

  final BibleApiDatasource _api;

  Future<List<Verse>> getCuratedVerses() => _api.fetchCuratedVerses();

  Future<List<Verse>> search(String query) => _api.searchVerses(query);

  Future<Verse> getVerse(String reference) => _api.fetchVerse(reference);
}
