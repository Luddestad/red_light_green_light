/// Audio and TTS constants
class AudioConstants {
  // TTS Configuration
  static const String voiceLanguage = 'en-US';
  static const String voiceGender = 'female';
  static const double speechRate = 0.8;
  static const double speechPitch = 1.0;
  static const double speechVolume = 1.0;
  
  // Voice Announcements
  static const String getInPositionText = 'Get in position!';
  static const String redLightText = 'Red light!';
  static const String greenLightText = 'Green light!';
  static const String gameOverText = 'Game Over!';
  static const String winnerText = 'Congratulations! You are the winner!';
  static const String eliminationText = 'You are out!';
  
  // Audio File Paths (matching actual files in assets/sounds/)
  static const String redLightSoundPath = 'assets/sounds/red_light.wav';
  static const String eliminationSoundPath = 'assets/sounds/eliminated.wav';
  static const String gameOverSoundPath = 'assets/sounds/game_over.wav';
  static const String victorySoundPath = 'assets/sounds/victory.wav';
  static const String lobbySoundPath = 'assets/sounds/lobby.wav';
  
  // Audio Settings
  static const double soundEffectVolume = 0.7;
  static const double backgroundMusicVolume = 0.3;
  static const bool enableSoundEffects = true;
  static const bool enableBackgroundMusic = false; // Optional
  
  // Timing
  static const Duration announcementDelay = Duration(milliseconds: 500);
  static const Duration soundEffectFadeIn = Duration(milliseconds: 200);
  static const Duration soundEffectFadeOut = Duration(milliseconds: 300);
  
  // Error Messages
  static const String ttsInitializationFailed = 'Failed to initialize text-to-speech';
  static const String audioPlaybackFailed = 'Failed to play audio';
  static const String permissionDenied = 'Audio permission denied';
}
