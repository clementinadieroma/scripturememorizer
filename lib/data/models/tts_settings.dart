enum TtsVoiceGender { male, female }

class TtsSettings {
  const TtsSettings({
    this.gender = TtsVoiceGender.female,
    this.speed = 0.5,
    this.pitch = 1.0,
  });

  final TtsVoiceGender gender;
  /// flutter_tts rate: 0.0 slow — 1.0 fast (platform-dependent)
  final double speed;
  final double pitch;

  TtsSettings copyWith({
    TtsVoiceGender? gender,
    double? speed,
    double? pitch,
  }) {
    return TtsSettings(
      gender: gender ?? this.gender,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
    );
  }
}
