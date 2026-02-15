import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service for managing text-to-speech and audio playback
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _audioPlayer.setVolume(1.0);
      print('🎵 AudioPlayer configured');

      // Configure TTS for female English voice
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.2); // Slightly higher pitch for female voice
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('Audio service initialized successfully');
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      //Check if this needs to be removed to make the voice finish its current sentence
      await _tts.stop();

      await _tts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  /// Play sound effect
  Future<void> playSoundEffect(String soundFile) async {
    try {
      // Stop any currently playing sound first
      await _audioPlayer.stop();

      // Play the new sound
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('❌ Error playing sound effect $soundFile: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }

  Future<void> playRedLightSound() async {
    await playSoundEffect('red_light.wav');
  }

  Future<void> playEliminationSound() async {
    await playSoundEffect('eliminated.wav');
  }

  Future<void> playGameOverSound() async {
    await playSoundEffect('game_over.wav');
  }

  Future<void> playVictorySound() async {
    await playSoundEffect('victory.wav');
  }

  Future<void> playLobbySound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Set to loop
      await _audioPlayer.play(AssetSource('sounds/lobby.wav'));
    } catch (e) {
      print('❌ Error playing lobby music: $e');
    }
  }

  Future<void> stopLobbySound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop); // Reset to normal
    } catch (e) {
      print('❌ Error stopping lobby music: $e');
    }
  }

  /// Announce game event with appropriate sound
  Future<void> announceGameEvent(String event, String message) async {
    switch (event.toLowerCase()) {
      case 'red_light':
        // Play sound first, then TTS
        await playRedLightSound();
        await Future.delayed(const Duration(milliseconds: 200)); // Small delay
        await speak(message);
        break;
      case 'green_light':
        await speak(message);
        break;
      case 'elimination':
        // Play elimination sound first, then TTS
        await playEliminationSound();
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // Slightly longer delay
        await speak(message);
        break;
      case 'game_over':
        // Play game over sound first, then TTS
        await playGameOverSound();
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Longer delay for dramatic effect
        await speak(message);
        break;
      default:
        await speak(message);
        break;
    }
  }

  Future<void> announceRedLight(String message) async {
    await playRedLightSound();
    await Future.delayed(const Duration(milliseconds: 200));
    await speak(message);
  }

  Future<void> announceElimination(String message) async {
    await playEliminationSound();
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(message);
  }

  Future<void> announceGameOver(String message) async {
    await playGameOverSound();
    await Future.delayed(const Duration(milliseconds: 500));
    await speak(message);
  }

  Future<void> announceVictory(String message) async {
    try {
      await playVictorySound();
      await Future.delayed(const Duration(milliseconds: 600));
      await speak(message);
    } catch (e, stackTrace) {
      print('❌ Stack trace: $stackTrace');
      try {
        await speak(message);
      } catch (e2) {
        print('❌ Error in fallback TTS: $e2');
      }
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose of resources
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
  }
}
