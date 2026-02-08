import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:red_light_green_light/core/constants/game_constants.dart';
import 'package:red_light_green_light/core/services/audio_service.dart';
import 'package:red_light_green_light/core/services/camera_service.dart';
import 'package:red_light_green_light/core/services/pose_detection_service.dart';
import 'package:red_light_green_light/features/game/models/difficulty_settings.dart';
import 'package:red_light_green_light/features/game/models/game_state.dart';
import 'dart:math' as math;

class GameController extends ChangeNotifier {
  final AudioService audioService;
  final CameraService cameraService;
  final PoseDetectionService poseDetectionService;
  final DifficultySettings difficulty;

  final void Function() onGoHome;

  GameController({
    required this.audioService,
    required this.cameraService,
    required this.poseDetectionService,
    required this.difficulty,
    required this.onGoHome,
  });

  late GameSession gameSession;
  Pose? currentPose;
  Pose? baselinePose;
  int stabilityFrames = 0;
  bool isPlayerDetected = false;
  bool isPlayerStable = false;
  bool isPlayerMoving = false;
  bool isProcessing = false;
  int countdownSeconds = 20;
  int frameCount = 0;
  bool playerDetectionAnnounced = false;

  Timer? countdownTimer;
  Timer? gameTimer;
  bool _isTransitioningToRedLight = false;
  bool _hasReducedCountdownForStable = false;
  Future<void> initializeGame() async {
    gameSession = GameSession(
      greenLightDuration: difficulty.getGreenLightDuration(),
      redLightDuration: difficulty.getRedLightDuration(),
    );

    // Services are already initialized from StartScreen
    // Just start the camera stream and game-specific setup
    await cameraService.startPreview();
    cameraService.imageStream?.listen(processImage);

    await audioService.playLobbySound();
    await audioService.speak(GameConstants.welcomeMessage);

    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdownSeconds--;
      notifyListeners();

      if (countdownSeconds <= 4 && countdownSeconds > 0) {
        audioService.speak(countdownSeconds.toString());
      }

      if (countdownSeconds <= 0) {
        timer.cancel();
        startGame();
      }
    });
  }

  Future<void> startGame() async {
    // Check if player is stable
    if (!isPlayerStable) {
      await audioService.speak(GameConstants.waitingForStableConnection);
      return;
    }

    // Stop the countdown timer since game is starting
    countdownTimer?.cancel();

    // Stop lobby music when game starts
    await audioService.stopLobbySound();

    // Reset baseline
    baselinePose = null;
    isPlayerMoving = false;

    gameSession.advanceState(); // Move to countdown
    gameSession.advanceState(); // Move to green light
    notifyListeners(); // Visual updates immediately

    await audioService.speak(GameConstants.gameStarted);

    startGameLoop();
    notifyListeners();
  }

  void stopCountdown() {
    countdownTimer?.cancel();
  }

  void startGameLoop() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(
        gameSession.currentPhaseStartTime!,
      );

      switch (gameSession.currentState) {
        case GameState.greenLight:
          if (elapsed >= gameSession.greenLightDuration &&
              !_isTransitioningToRedLight) {
            _isTransitioningToRedLight = true;
            switchToRedLight()
                .then((_) {})
                .catchError((error) {
                  print('🔴 Red light transition error: $error');
                })
                .whenComplete(() {
                  _isTransitioningToRedLight = false;
                });
          }
          break;
        case GameState.redLight:
          if (elapsed >= gameSession.redLightDuration) {
            switchToGreenLight();
          }
          break;
        case GameState.victory:
          timer.cancel();
          // Victory state is handled by _winGame(), no additional action needed
          break;
        case GameState.gameOver:
          timer.cancel();
          endGame();
          break;
        default:
          break;
      }
    });
  }

  Future<void> switchToRedLight() async {
    gameSession.redLightDuration = difficulty.getRedLightDuration();
    gameSession.advanceState(); // Move to red light
    notifyListeners(); // Visual updates immediately

    try {
      await audioService.announceRedLight(GameConstants.redLightMessage);
    } catch (e) {
      // Continue anyway - don't let audio issues block game functionality
    }

    if (isPlayerStable && currentPose != null) {
      baselinePose = currentPose;
      isPlayerMoving = false;
    } else {
      print('⚠️ Cannot set baseline for player - not stable or no pose');
    }
  }

  Future<void> switchToGreenLight() async {
    if (gameSession.isGameOver) {
      gameSession.advanceState(); // Move to game over
      notifyListeners();
    } else {
      gameSession.greenLightDuration = difficulty.getGreenLightDuration();
      gameSession.advanceState(); // Move to green light
      notifyListeners(); // Visual updates immediately
      await audioService.speak(GameConstants.greenLightMessage);
    }
  }

  Future<void> winGame() async {
    gameTimer?.cancel();

    gameSession.currentState = GameState.victory;
    notifyListeners();

    await audioService.announceVictory(
      'Congratulations! You reached the phone and won the game! Victory!',
    );
  }

  Future<void> endGame() async {
    gameTimer?.cancel();

    gameSession.isGameOver = true;
    gameSession.currentState = GameState.gameOver;
    notifyListeners(); // Visual updates immediately

    await audioService.announceGameOver(
      "Game over! I win! Better luck next time!",
    );
  }

  /// Restart the game
  void restartGame() {
    // Reset game session with difficulty-based durations
    gameSession = GameSession(
      greenLightDuration: difficulty.getGreenLightDuration(),
      redLightDuration: difficulty.getRedLightDuration(),
    );

    // Reset detection state
    currentPose = null;
    baselinePose = null;
    stabilityFrames = 0;
    isPlayerDetected = false;
    isPlayerStable = false;
    isPlayerMoving = false;

    // Cancel any existing timer
    gameTimer?.cancel();
    countdownTimer?.cancel();

    // Reset transition guard
    _isTransitioningToRedLight = false;
    _hasReducedCountdownForStable = false;

    // Reset countdown
    countdownSeconds = 20;

    // Play lobby sound and start countdown again
    audioService.playLobbySound();
    startCountdown();
    notifyListeners();
  }

  /// Go back to home screen
  void goHome() {
    gameTimer?.cancel();
    countdownTimer?.cancel();
    audioService.stopLobbySound();
    onGoHome();
  }

  /// Dispose controller resources
  @override
  void dispose() {
    gameTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  /// Check for movement violations during red light (simplified)
  Future<void> checkForMovementViolations() async {
    if (gameSession.currentState != GameState.redLight) {
      return;
    }

    if (gameSession.isGameOver || isPlayerMoving) {
      return;
    }

    if (!isPlayerStable || baselinePose == null || currentPose == null) {
      return;
    }

    // Simple pixel-based movement detection
    final moved = checkSimpleMovement(currentPose!, baselinePose!);

    if (moved) {
      print('🚨 Movement violation detected!');
      isPlayerMoving = true;
      endGame();
    }
  }

  bool checkSimpleMovement(Pose current, Pose baseline) {
    const threshold = 80.0; // pixels

    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    ];

    for (final type in keyLandmarks) {
      final currentLM = current.landmarks[type];
      final baselineLM = baseline.landmarks[type];

      if (currentLM != null &&
          baselineLM != null &&
          currentLM.likelihood > 0.5 &&
          baselineLM.likelihood > 0.5) {
        final distance = math.sqrt(
          math.pow(currentLM.x - baselineLM.x, 2) +
              math.pow(currentLM.y - baselineLM.y, 2),
        );

        if (distance > threshold) {
          print(
            '🚨 Movement at ${type.toString().split('.').last}: ${distance.toStringAsFixed(1)}px',
          );
          return true;
        }
      }
    }

    return false;
  }

  Future<void> handleDetectionAnnouncement() async {
    // Only announce during waiting phase
    if (gameSession.currentState != GameState.waiting) {
      return;
    }

    // Announce when player is first detected
    if (isPlayerDetected && !playerDetectionAnnounced) {
      playerDetectionAnnounced = true;
      await audioService.speak(GameConstants.playerDetectedLobby);
      print('🎤 Announced player detection');
    }

    // Auto-reduce countdown when player is stable (silent, no TTS)
    if (isPlayerStable && countdownSeconds > 10 && !_hasReducedCountdownForStable) {
      _hasReducedCountdownForStable = true;
      countdownSeconds = 10;
      notifyListeners();
    }
  }

  /// Get frame skip value based on game state (adaptive performance)
  int getFrameSkip() {
    if (!isPlayerStable) return 2; // Every 2nd frame during initialization
    if (gameSession.currentState == GameState.redLight)
      return 2; // More frequent during red light
    return 4; // Every 4th frame during green/waiting (save battery)
  }

  /// Update pose detection (simplified for single player)
  Future<void> updatePoseDetection(List<Pose> poses) async {
    // Check if we have pose detected
    if (poses.isEmpty) {
      isPlayerDetected = false;
      currentPose = null;
      stabilityFrames = 0;
      isPlayerStable = false;
      playerDetectionAnnounced = false;
      print('🚫 No pose detected');
      return;
    }

    // Use the first (best) pose
    currentPose = poses.first;
    isPlayerDetected = true;

    // Check pose quality (minimum valid landmarks)
    final validLandmarks = currentPose!.landmarks.values
        .where((l) => l.likelihood > 0.5)
        .length;

    if (validLandmarks >= 5) {
      stabilityFrames++;
    } else {
      stabilityFrames = math.max(0, stabilityFrames - 1);
    }

    isPlayerStable = stabilityFrames >= 4;
    print(
      '👤 Pose detected: $validLandmarks landmarks, stable=$isPlayerStable ($stabilityFrames/4)',
    );

    // Handle detection announcement
    await handleDetectionAnnouncement();
  }

  Future<void> processImage(CameraImage image) async {
    if (isProcessing) return;

    // Adaptive frame skipping for better performance
    frameCount++;
    final frameSkip = getFrameSkip();
    if (frameCount % frameSkip != 0) return;

    isProcessing = true;

    try {
      // Step 1: Run pose detection
      final poses = await poseDetectionService.detectPoses(image);

      // Step 2: Update pose detection state
      await updatePoseDetection(poses);

      // Step 3: Check for movement violations during red light
      if (gameSession.currentState == GameState.redLight) {
        await checkForMovementViolations();
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      isProcessing = false;
    }
  }
}
