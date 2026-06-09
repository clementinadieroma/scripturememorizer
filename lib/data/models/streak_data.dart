import 'package:equatable/equatable.dart';

class StreakData extends Equatable {
  const StreakData({
    this.currentCount = 0,
    this.longestCount = 0,
    this.lastActivityDate,
  });

  final int currentCount;
  final int longestCount;
  final DateTime? lastActivityDate;

  StreakData copyWith({
    int? currentCount,
    int? longestCount,
    DateTime? lastActivityDate,
  }) {
    return StreakData(
      currentCount: currentCount ?? this.currentCount,
      longestCount: longestCount ?? this.longestCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  factory StreakData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const StreakData();
    return StreakData(
      currentCount: (map['currentCount'] as num?)?.toInt() ?? 0,
      longestCount: (map['longestCount'] as num?)?.toInt() ?? 0,
      lastActivityDate:
          DateTime.tryParse(map['lastActivityDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'currentCount': currentCount,
        'longestCount': longestCount,
        'lastActivityDate': lastActivityDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [currentCount, longestCount, lastActivityDate];
}
