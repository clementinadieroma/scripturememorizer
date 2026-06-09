import 'package:equatable/equatable.dart';

import 'verse.dart';

class FavoriteVerse extends Equatable {
  const FavoriteVerse({
    required this.verseId,
    required this.addedAt,
    this.reference,
    this.text,
    this.translation,
  });

  final String verseId;
  final DateTime addedAt;
  final String? reference;
  final String? text;
  final String? translation;

  factory FavoriteVerse.fromVerse(Verse verse) => FavoriteVerse(
        verseId: verse.id,
        addedAt: DateTime.now(),
        reference: verse.displayReference,
        text: verse.text,
        translation: verse.translation,
      );

  factory FavoriteVerse.fromMap(Map<String, dynamic> map) {
    return FavoriteVerse(
      verseId: map['verseId'] as String? ?? '',
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ??
          DateTime.now(),
      reference: map['reference'] as String?,
      text: map['text'] as String?,
      translation: map['translation'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'verseId': verseId,
        'addedAt': addedAt.toIso8601String(),
        'reference': reference,
        'text': text,
        'translation': translation,
      };

  @override
  List<Object?> get props =>
      [verseId, addedAt, reference, text, translation];
}
