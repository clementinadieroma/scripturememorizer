import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  const UserStats({
    this.versesMemorizedCount = 0,
    this.versesInProgressCount = 0,
    this.favoritesCount = 0,
    this.totalSessionsCount = 0,
    this.totalPracticeMinutes = 0,
  });

  final int versesMemorizedCount;
  final int versesInProgressCount;
  final int favoritesCount;
  final int totalSessionsCount;
  final int totalPracticeMinutes;

  factory UserStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserStats();
    return UserStats(
      versesMemorizedCount: (map['versesMemorizedCount'] as num?)?.toInt() ?? 0,
      versesInProgressCount:
          (map['versesInProgressCount'] as num?)?.toInt() ?? 0,
      favoritesCount: (map['favoritesCount'] as num?)?.toInt() ?? 0,
      totalSessionsCount: (map['totalSessionsCount'] as num?)?.toInt() ?? 0,
      totalPracticeMinutes: (map['totalPracticeMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        versesMemorizedCount,
        versesInProgressCount,
        favoritesCount,
        totalSessionsCount,
        totalPracticeMinutes,
      ];
}
