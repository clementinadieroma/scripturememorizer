import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/verse.dart';

final curatedVersesProvider = FutureProvider<List<Verse>>((ref) {
  return ref.watch(verseRepositoryProvider).getCuratedVerses();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Verse>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return [];
  return ref.watch(verseRepositoryProvider).search(query);
});

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final curatedAsync = ref.watch(curatedVersesProvider);
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Scriptures')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reference (John 3:16) or keyword',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: query.trim().length >= 2
                ? searchAsync.when(
                    data: (verses) => _VerseList(verses: verses),
                    loading: () => const LoadingView(message: 'Searching...'),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
                  )
                : curatedAsync.when(
                    data: (verses) => _VerseList(verses: verses),
                    loading: () =>
                        const LoadingView(message: 'Loading verses...'),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(curatedVersesProvider),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VerseList extends StatelessWidget {
  const _VerseList({required this.verses});

  final List<Verse> verses;

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const Center(child: Text('No verses found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: verses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final verse = verses[index];
        return Card(
          child: ListTile(
            title: Text(
              verse.displayReference,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              verse.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/verse', extra: verse),
          ),
        );
      },
    );
  }
}
