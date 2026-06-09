import 'package:flutter_tts/flutter_tts.dart';

import '../../data/models/tts_settings.dart';

class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  TtsSettings _settings = const TtsSettings();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
    await _applySettings(_settings);
  }

  TtsSettings get settings => _settings;

  Future<void> updateSettings(TtsSettings settings) async {
    _settings = settings;
    await _applySettings(settings);
  }

  Future<void> _applySettings(TtsSettings settings) async {
    await _tts.setSpeechRate(settings.speed);
    await _tts.setPitch(settings.pitch);

    final voices = await _tts.getVoices;
    if (voices is List) {
      final enVoices = voices
          .where((v) {
            final locale = (v['locale'] as String?) ?? '';
            return locale.toLowerCase().startsWith('en');
          })
          .cast<Map>()
          .toList();

      if (enVoices.isNotEmpty) {
        Map? selected;
        for (final v in enVoices) {
          final name = ((v['name'] as String?) ?? '').toLowerCase();
          final isFemale = name.contains('female') ||
              name.contains('samantha') ||
              name.contains('karen') ||
              name.contains('victoria');
          final isMale = name.contains('male') ||
              name.contains('daniel') ||
              name.contains('fred') ||
              name.contains('alex');

          if (settings.gender == TtsVoiceGender.female && isFemale) {
            selected = v;
            break;
          }
          if (settings.gender == TtsVoiceGender.male && isMale) {
            selected = v;
            break;
          }
        }
        selected ??= enVoices.first;
        await _tts.setVoice({
          'name': selected['name'],
          'locale': selected['locale'],
        });
      }
    }
  }

  Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<void> pause() => _tts.pause();

  void dispose() {
    _tts.stop();
  }
}
