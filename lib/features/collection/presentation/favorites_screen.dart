import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/favorite_verse.dart';
import '../../../data/models/verse.dart';

final favoritesListProvider = FutureProvider<List<FavoriteVerse>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(favoritesRepositoryProvider).getFavorites(user);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesListProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user == null
                          ? 'Sign in to sync favorites across devices, or save locally as a guest.'
                          : 'Tap the heart on any verse to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (user == null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return Dismissible(
                key: ValueKey(fav.verseId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await ref
                      .read(favoritesRepositoryProvider)
                      .removeFavorite(user, fav.verseId);
                  ref.invalidate(favoritesListProvider);
                },
                child: Card(
                  child: ListTile(
                    title: Text(
                      fav.reference ?? fav.verseId,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      fav.text ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      if (fav.text != null && fav.reference != null) {
                        final verse = Verse(
                          id: fav.verseId,
                          translation: fav.translation ?? 'WEB',
                          book: '',
                          chapter: 1,
                          verse: 1,
                          text: fav.text!,
                          reference: fav.reference,
                        );
                        context.push('/verse', extra: verse);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
