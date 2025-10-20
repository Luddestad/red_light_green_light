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
      print('🎵 Initializing audio service...');
      
      // Initialize audio player with Android-compatible settings
      await _audioPlayer.setVolume(1.0);
      print('🎵 AudioPlayer configured');
      
      // Configure TTS for female English voice
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.6); // Slower speech (was 0.8)
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.2); // Slightly higher pitch for female voice
      
      // Try to set a female voice if available
      final voices = await _tts.getVoices;
      if (voices != null) {
        for (final voice in voices) {
          final voiceMap = voice as Map<String, dynamic>;
          final name = (voiceMap['name'] ?? '').toString().toLowerCase();
          final gender = (voiceMap['gender'] ?? '').toString().toLowerCase();

          // Look for female voices or voices with female-sounding names
          if (gender.contains('female') ||
              name.contains('female') ||
              name.contains('samantha') ||
              name.contains('karen') ||
              name.contains('moira') ||
              name.contains('tessa') ||
              name.contains('fiona')) {
            // Convert the voice map to the correct format (string values)
            final Map<String, String> voiceData = {};
            voiceMap.forEach((k, v) {
              final key = k.toString();
              if (v != null) voiceData[key] = v.toString();
            });
            await _tts.setVoice(voiceData);
            print('Set female voice: ${voiceMap['name']}');
            break;
          }
        }
      }

      // Set up TTS callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((message) {
        print('TTS Error: $message');
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
      // Stop any current speech
      await _tts.stop();
      
      // Speak the new text
      print('Speaking: $text');
      await _tts.speak(text);
      
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  /// Stop current speech
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  /// Play sound effect
  Future<void> playSoundEffect(String soundFile) async {
    try {
      print('🔊 Attempting to play sound effect: $soundFile');
      
      // Stop any currently playing sound first
      await _audioPlayer.stop();
      
      // Play the new sound
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      print('🔊 Sound effect started successfully: $soundFile');
    } catch (e) {
      print('❌ Error playing sound effect $soundFile: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }

  /// Play red light sound
  Future<void> playRedLightSound() async {
    await playSoundEffect('red_light.wav');
  }

  /// Play green light sound (placeholder for future)
  Future<void> playGreenLightSound() async {
    // No green light sound file yet
    print('Green light sound would play here');
  }

  /// Play elimination sound
  Future<void> playEliminationSound() async {
    await playSoundEffect('eliminated.wav');
  }

  /// Play countdown sound
  Future<void> playCountdownSound() async {
    await playSoundEffect('countdown.mp3');
  }

  /// Play game over sound
  Future<void> playGameOverSound() async {
    await playSoundEffect('game_over.wav');
  }

  /// Play victory sound
  Future<void> playVictorySound() async {
    await playSoundEffect('victory.wav');
  }

  /// Play lobby sound (looping)
  Future<void> playLobbySound() async {
    try {
      print('🎵 Starting lobby music loop');
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Set to loop
      await _audioPlayer.play(AssetSource('sounds/lobby.wav'));
      print('🎵 Lobby music started successfully');
    } catch (e) {
      print('❌ Error playing lobby music: $e');
    }
  }

  /// Stop lobby sound
  Future<void> stopLobbySound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop); // Reset to normal
      print('🎵 Lobby music stopped');
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
        // Play sound first (when available), then TTS
        await playGreenLightSound();
        await speak(message);
        break;
      case 'elimination':
        // Play elimination sound first, then TTS
        await playEliminationSound();
        await Future.delayed(const Duration(milliseconds: 300)); // Slightly longer delay
        await speak(message);
        break;
      case 'countdown':
        await playCountdownSound();
        await speak(message);
        break;
      case 'game_over':
        // Play game over sound first, then TTS
        await playGameOverSound();
        await Future.delayed(const Duration(milliseconds: 500)); // Longer delay for dramatic effect
        await speak(message);
        break;
      default:
        await speak(message);
        break;
    }
  }

  /// Play red light sound and speak message with proper timing
  Future<void> announceRedLight(String message) async {
    print('🔴 Starting red light announcement');
    await playRedLightSound();
    print('🔴 Red light sound played, waiting 200ms');
    await Future.delayed(const Duration(milliseconds: 200));
    print('🔴 Speaking message: $message');
    await speak(message);
    print('🔴 Red light announcement complete');
  }

  /// Play elimination sound and speak message with proper timing
  Future<void> announceElimination(String message) async {
    print('❌ Starting elimination announcement');
    await playEliminationSound();
    print('❌ Elimination sound played, waiting 300ms');
    await Future.delayed(const Duration(milliseconds: 300));
    print('❌ Speaking message: $message');
    await speak(message);
    print('❌ Elimination announcement complete');
  }

  /// Play game over sound and speak message with proper timing
  Future<void> announceGameOver(String message) async {
    print('🏁 Starting game over announcement');
    await playGameOverSound();
    print('🏁 Game over sound played, waiting 500ms');
    await Future.delayed(const Duration(milliseconds: 500));
    print('🏁 Speaking message: $message');
    await speak(message);
    print('🏁 Game over announcement complete');
  }

  /// Play victory sound and speak message with proper timing
  Future<void> announceVictory(String message) async {
    try {
      print('🏆 Starting victory announcement');
      await playVictorySound();
      print('🏆 Victory sound played, waiting 600ms');
      await Future.delayed(const Duration(milliseconds: 600)); // Slightly longer for victory celebration
      print('🏆 Speaking message: $message');
      await speak(message);
      print('🏆 Victory announcement complete');
    } catch (e, stackTrace) {
      print('❌ Error in announceVictory: $e');
      print('❌ Stack trace: $stackTrace');
      // Still try to speak the message even if sound fails
      try {
        await speak(message);
      } catch (e2) {
        print('❌ Error in fallback TTS: $e2');
      }
    }
  }

  /// Get available voices for debugging
  Future<List<dynamic>?> getAvailableVoices() async {
    try {
      return await _tts.getVoices;
    } catch (e) {
      print('Error getting voices: $e');
      return null;
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
