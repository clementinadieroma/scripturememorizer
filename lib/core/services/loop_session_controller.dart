import 'dart:async';

import '../../data/models/loop_count.dart';
import '../../data/models/verse.dart';
import 'tts_service.dart';

typedef LoopProgressCallback = void Function(int current, int? total);

class LoopSessionController {
  LoopSessionController(this._tts);

  final TtsService _tts;
  bool _running = false;
  bool _paused = false;
  int _current = 0;

  bool get isRunning => _running;
  bool get isPaused => _paused;
  int get currentIteration => _current;

  Future<void> run({
    required Verse verse,
    required LoopCount loopCount,
    required LoopProgressCallback onProgress,
    void Function()? onComplete,
  }) async {
    _running = true;
    _paused = false;
    _current = 0;

    final total = loopCount.isUnlimited ? null : loopCount.value;

    while (_running) {
      if (_paused) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      _current++;
      onProgress(_current, total);

      await _tts.speak(verse.text);

      if (!_running) break;
      if (total != null && _current >= total) break;

      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    _running = false;
    onComplete?.call();
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  Future<void> stop() async {
    _running = false;
    _paused = false;
    await _tts.stop();
  }
}
