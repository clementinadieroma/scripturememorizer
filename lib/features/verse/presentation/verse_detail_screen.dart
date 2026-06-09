import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/loop_count.dart';
import '../../../data/models/tts_settings.dart';
import '../../../data/models/verse.dart';

class VerseDetailScreen extends ConsumerStatefulWidget {
  const VerseDetailScreen({super.key, required this.verse});

  final Verse verse;

  @override
  ConsumerState<VerseDetailScreen> createState() => _VerseDetailScreenState();
}

class _VerseDetailScreenState extends ConsumerState<VerseDetailScreen> {
  TtsSettings _ttsSettings = const TtsSettings();
  LoopCount? _selectedLoop;
  bool _isSpeaking = false;
  bool _loopRunning = false;
  int _loopCurrent = 0;
  int? _loopTotal;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.init();
    await tts.updateSettings(_ttsSettings);
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    ref.read(loopControllerProvider).stop();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(favoritesRepositoryProvider);
    final isFav = await repo.isFavorite(user, widget.verse.id);
    if (isFav) {
      await repo.removeFavorite(user, widget.verse.id);
    } else {
      await repo.addFavorite(user, widget.verse);
    }
    ref.invalidate(isFavoriteProvider(widget.verse.id));
  }

  Future<void> _speakOnce() async {
    final tts = ref.read(ttsServiceProvider);
    await tts.updateSettings(_ttsSettings);
    setState(() => _isSpeaking = true);
    await tts.speak(widget.verse.text);
    if (mounted) setState(() => _isSpeaking = false);
    await _recordPractice(loops: 0);
  }

  Future<void> _startLoop() async {
    final loop = _selectedLoop;
    if (loop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a repeat count first')),
      );
      return;
    }

    final controller = ref.read(loopControllerProvider);
    final tts = ref.read(ttsServiceProvider);
    await tts.updateSettings(_ttsSettings);

    setState(() {
      _loopRunning = true;
      _loopCurrent = 0;
      _loopTotal = loop.isUnlimited ? null : loop.value;
    });

    await controller.run(
      verse: widget.verse,
      loopCount: loop,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _loopCurrent = current;
            _loopTotal = total;
          });
        }
      },
      onComplete: () async {
        if (mounted) {
          setState(() => _loopRunning = false);
          await _recordPractice(loops: _loopCurrent);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Completed $_loopCurrent repetitions')),
          );
        }
      },
    );
  }

  Future<void> _stopLoop() async {
    await ref.read(loopControllerProvider).stop();
    if (mounted) setState(() => _loopRunning = false);
  }

  Future<void> _recordPractice({required int loops}) async {
    final user = ref.read(currentUserProvider);
    await ref.read(progressRepositoryProvider).recordPractice(
          user,
          widget.verse,
          percentDelta: loops > 0 ? 5 : 3,
          completedSession: loops >= 5,
          loopsCompleted: loops,
          lastMode: loops > 0 ? 'repeat' : 'listen',
          durationSeconds: loops > 0 ? loops * 20 : 30,
        );
    ref.invalidate(verseProgressProvider(widget.verse.id));
    ref.invalidate(streakProvider);
  }

  @override
  Widget build(BuildContext context) {
    final favAsync = ref.watch(isFavoriteProvider(widget.verse.id));
    final progressAsync = ref.watch(verseProgressProvider(widget.verse.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.verse.displayReference),
        actions: [
          favAsync.when(
            data: (isFav) => IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            progressAsync.when(
              data: (p) {
                if (p == null) return const SizedBox.shrink();
                return Chip(
                  label: Text('${p.status.label} · ${p.percent}%'),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Text(
              widget.verse.translation,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              widget.verse.text,
              style: const TextStyle(fontSize: 22, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Text-to-Speech',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TtsVoiceGender>(
              segments: const [
                ButtonSegment(
                  value: TtsVoiceGender.male,
                  label: Text('Male'),
                  icon: Icon(Icons.record_voice_over),
                ),
                ButtonSegment(
                  value: TtsVoiceGender.female,
                  label: Text('Female'),
                  icon: Icon(Icons.record_voice_over),
                ),
              ],
              selected: {_ttsSettings.gender},
              onSelectionChanged: (set) {
                setState(() {
                  _ttsSettings =
                      _ttsSettings.copyWith(gender: set.first);
                });
                ref.read(ttsServiceProvider).updateSettings(_ttsSettings);
              },
            ),
            const SizedBox(height: 12),
            Text('Speed: ${_ttsSettings.speed.toStringAsFixed(1)}'),
            Slider(
              value: _ttsSettings.speed,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              label: _ttsSettings.speed.toStringAsFixed(1),
              onChanged: (v) {
                setState(() => _ttsSettings = _ttsSettings.copyWith(speed: v));
                ref.read(ttsServiceProvider).updateSettings(_ttsSettings);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSpeaking || _loopRunning ? null : _speakOnce,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_isSpeaking ? 'Playing...' : 'Play Once'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref.read(ttsServiceProvider).stop(),
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Repeat / Loop Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LoopCount.values.map((count) {
                final selected = _selectedLoop == count;
                return ChoiceChip(
                  label: Text(count.label),
                  selected: selected,
                  onSelected: _loopRunning
                      ? null
                      : (_) => setState(() => _selectedLoop = count),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            if (_loopRunning) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _loopTotal != null && _loopTotal! > 0
                    ? _loopCurrent / _loopTotal!
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                _loopTotal != null
                    ? '$_loopCurrent of $_loopTotal'
                    : 'Loop $_loopCurrent (unlimited)',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            if (_loopRunning)
              ElevatedButton.icon(
                onPressed: _stopLoop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Loop'),
              )
            else
              ElevatedButton.icon(
                onPressed: _startLoop,
                icon: const Icon(Icons.repeat),
                label: const Text('Start Loop'),
              ),
          ],
        ),
      ),
    );
  }
}

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, verseId) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(favoritesRepositoryProvider).isFavorite(user, verseId);
});

final verseProgressProvider =
    FutureProvider.family<dynamic, String>((ref, verseId) async {
  final user = ref.watch(currentUserProvider);
  return ref.watch(progressRepositoryProvider).getProgressForVerse(user, verseId);
});
