import 'package:cloud_functions/cloud_functions.dart';

/// Wraps Firebase HTTPS callables for the Scripture Memorizer backend.
class CloudFunctionsDatasource {
  CloudFunctionsDatasource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Point callable requests at the local emulator (debug only).
  void useEmulator({String host = 'localhost', int port = 5001}) {
    _functions.useFunctionsEmulator(host, port);
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final result = await _functions.httpsCallable(name).call(data);
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw CloudFunctionsException(
      code: 'invalid-response',
      message: 'Unexpected response from $name',
    );
  }

  /// Fetch today's daily verse (auth optional).
  Future<Map<String, dynamic>> getDailyVerse({String? timezone}) {
    return _call('getDailyVerse', {
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    });
  }

  /// Add or remove a favorite. Set [add] to force action; omit to toggle.
  Future<Map<String, dynamic>> toggleFavorite({
    required String verseId,
    required String reference,
    required String text,
    required String translation,
    String? book,
    int? chapter,
    int? verse,
    bool? add,
  }) {
    return _call('toggleFavorite', {
      'verseId': verseId,
      'reference': reference,
      'text': text,
      'translation': translation,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (add != null) 'add': add,
    });
  }

  /// Update memorization progress after a practice or loop session.
  Future<Map<String, dynamic>> updateMemorizationProgress({
    required String verseId,
    String? reference,
    String? status,
    int? percent,
    int? repeatCountDelta,
    int? loopsCompleted,
    String? lastMode,
    int? durationSeconds,
    bool? completed,
    String? clientId,
  }) {
    return _call('updateMemorizationProgress', {
      'verseId': verseId,
      if (reference != null) 'reference': reference,
      if (status != null) 'status': status,
      if (percent != null) 'percent': percent,
      if (repeatCountDelta != null) 'repeatCountDelta': repeatCountDelta,
      if (loopsCompleted != null) 'loopsCompleted': loopsCompleted,
      if (lastMode != null) 'lastMode': lastMode,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (completed != null) 'completed': completed,
      if (clientId != null) 'clientId': clientId,
    });
  }

  /// Dashboard stats, streak, and recent progress for the signed-in user.
  Future<Map<String, dynamic>> getUserStats({bool recalculate = false}) {
    return _call('getUserStats', {'recalculate': recalculate});
  }
}

/// Thrown when a callable returns an unexpected payload.
class CloudFunctionsException implements Exception {
  CloudFunctionsException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'CloudFunctionsException($code): $message';
}
