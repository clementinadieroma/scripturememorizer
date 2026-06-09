import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/verse.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dailyAsync = ref.watch(dailyVerseProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripture Memorizer'),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Sign In', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyVerseProvider);
          ref.invalidate(streakProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            streakAsync.when(
              data: (streak) => Card(
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: AppTheme.accent, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${streak.currentCount} day streak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Longest: ${streak.longestCount} days',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verse of the Day',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            dailyAsync.when(
              data: (verse) => _DailyVerseCard(verse: verse),
              loading: () => const Card(
                child: SizedBox(
                  height: 160,
                  child: LoadingView(message: 'Loading today\'s verse...'),
                ),
              ),
              error: (e, _) => Card(
                child: ErrorView(
                  message: 'Could not load daily verse.\n$e',
                  onRetry: () => ref.invalidate(dailyVerseProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/verse', extra: verse),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse.displayReference,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                verse.translation,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                verse.text,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/verse', extra: verse),
                    icon: const Icon(Icons.volume_up, size: 18),
                    label: const Text('Listen & Memorize'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
