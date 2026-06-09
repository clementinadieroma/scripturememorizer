import 'package:equatable/equatable.dart';

import 'memorization_status.dart';
import 'verse.dart';

class UserProgress extends Equatable {
  const UserProgress({
    required this.verseId,
    required this.status,
    required this.percent,
    required this.lastPracticedAt,
    this.repeatCount = 0,
    this.reference,
  });

  final String verseId;
  final MemorizationStatus status;
  final int percent;
  final DateTime lastPracticedAt;
  final int repeatCount;
  final String? reference;

  UserProgress copyWith({
    MemorizationStatus? status,
    int? percent,
    DateTime? lastPracticedAt,
    int? repeatCount,
    String? reference,
  }) {
    return UserProgress(
      verseId: verseId,
      status: status ?? this.status,
      percent: percent ?? this.percent,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      repeatCount: repeatCount ?? this.repeatCount,
      reference: reference ?? this.reference,
    );
  }

  factory UserProgress.initial(Verse verse) => UserProgress(
        verseId: verse.id,
        status: MemorizationStatus.notStarted,
        percent: 0,
        lastPracticedAt: DateTime.now(),
        reference: verse.displayReference,
      );

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      verseId: map['verseId'] as String? ?? '',
      status: MemorizationStatus.fromString(map['status'] as String?),
      percent: (map['percent'] as num?)?.toInt() ?? 0,
      lastPracticedAt: DateTime.tryParse(map['lastPracticedAt'] as String? ?? '') ??
          DateTime.now(),
      repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 0,
      reference: map['reference'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'verseId': verseId,
        'status': status.toStorageString(),
        'percent': percent,
        'lastPracticedAt': lastPracticedAt.toIso8601String(),
        'repeatCount': repeatCount,
        'reference': reference,
      };

  @override
  List<Object?> get props =>
      [verseId, status, percent, lastPracticedAt, repeatCount, reference];
}
