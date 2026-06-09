import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/memorization_status.dart';
import '../../../data/models/user_progress.dart';

final allProgressProvider = FutureProvider<List<UserProgress>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(progressRepositoryProvider).getAllProgress(user);
});

final memorizedCountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(progressRepositoryProvider).memorizedCount(user);
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final memorizedAsync = ref.watch(memorizedCountProvider);
    final progressAsync = ref.watch(allProgressProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            await ref
                .read(progressRepositoryProvider)
                .getUserStats(user, recalculate: true);
          }
          ref.invalidate(streakProvider);
          ref.invalidate(memorizedCountProvider);
          ref.invalidate(allProgressProvider);
          ref.invalidate(userStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user == null)
              Card(
                color: AppTheme.accent.withValues(alpha: 0.15),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Guest mode'),
                  subtitle: const Text(
                    'Progress is saved on this device. Sign in to sync with Firebase.',
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign In'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: streakAsync.when(
                    data: (streak) => _StatCard(
                      icon: Icons.local_fire_department,
                      label: 'Current Streak',
                      value: '${streak.currentCount}',
                      subtitle: 'Longest: ${streak.longestCount}',
                    ),
                    loading: () => const _StatCard.loading(),
                    error: (_, __) => const _StatCard(
                      icon: Icons.local_fire_department,
                      label: 'Streak',
                      value: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: memorizedAsync.when(
                    data: (count) => _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Memorized',
                      value: '$count',
                      subtitle: 'verses',
                    ),
                    loading: () => const _StatCard.loading(),
                    error: (_, __) => const _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Memorized',
                      value: '0',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            progressAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Start memorizing verses to see your progress here.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final sorted = [...items]
                  ..sort(
                    (a, b) => b.lastPracticedAt.compareTo(a.lastPracticedAt),
                  );
                return Column(
                  children: sorted.map(_ProgressTile.new).toList(),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  const _StatCard.loading()
      : icon = Icons.hourglass_empty,
        label = '...',
        value = '—',
        subtitle = null;

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile(this.progress);

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().format(progress.lastPracticedAt);
    Color statusColor;
    switch (progress.status) {
      case MemorizationStatus.memorized:
        statusColor = Colors.green;
      case MemorizationStatus.inProgress:
        statusColor = Colors.orange;
      case MemorizationStatus.notStarted:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(progress.reference ?? progress.verseId),
        subtitle: Text('$date · ${progress.percent}% complete'),
        trailing: Chip(
          label: Text(
            progress.status.label,
            style: TextStyle(fontSize: 11, color: statusColor),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
