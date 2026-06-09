import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  const Verse({
    required this.id,
    required this.translation,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.reference,
  });

  final String id;
  final String translation;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? reference;

  String get displayReference =>
      reference ?? '$book $chapter:$verse';

  String get apiReference => '$book $chapter:$verse';

  factory Verse.fromBibleApiJson(Map<String, dynamic> json) {
    final ref = json['reference'] as String? ?? '';
    final parts = _parseReference(ref);
    final translation = (json['translation_name'] as String?) ?? 'WEB';
    return Verse(
      id: '${translation}-${parts['book']}-${parts['chapter']}-${parts['verse']}',
      translation: translation,
      book: parts['book'] ?? ref,
      chapter: parts['chapter'] ?? 1,
      verse: parts['verse'] ?? 1,
      text: (json['text'] as String?)?.trim() ?? '',
      reference: ref,
    );
  }

  factory Verse.fromFirestore(Map<String, dynamic> data, String id) {
    return Verse(
      id: id,
      translation: data['translation'] as String? ?? 'WEB',
      book: data['book'] as String? ?? '',
      chapter: (data['chapter'] as num?)?.toInt() ?? 1,
      verse: (data['verse'] as num?)?.toInt() ?? 1,
      text: data['text'] as String? ?? '',
      reference: data['reference'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'translation': translation,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'reference': displayReference,
      };

  static Map<String, dynamic> _parseReference(String ref) {
    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(ref.trim());
    if (match == null) {
      return {'book': ref, 'chapter': 1, 'verse': 1};
    }
    return {
      'book': match.group(1)!.trim(),
      'chapter': int.parse(match.group(2)!),
      'verse': int.parse(match.group(3)!),
    };
  }

  @override
  List<Object?> get props =>
      [id, translation, book, chapter, verse, text, reference];
}
