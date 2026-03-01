import 'dart:async';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:red_light_green_light/core/constants/game_constants.dart';
import 'package:red_light_green_light/core/services/audio_service.dart';
import 'package:red_light_green_light/core/services/camera_service.dart';
import 'package:red_light_green_light/core/services/pose_detection_service.dart';
import 'package:red_light_green_light/features/game/models/detection_settings.dart';
import 'package:red_light_green_light/features/game/models/game_state.dart';
import 'dart:math' as math;

class GameController extends ChangeNotifier {
  final AudioService audioService;
  final CameraService cameraService;
  final PoseDetectionService poseDetectionService;
  final DetectionSettings settings;

  final void Function() onGoHome;

  GameController({
    required this.audioService,
    required this.cameraService,
    required this.poseDetectionService,
    required this.settings,
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
  bool playerDetectionAnnounced = false;

  Timer? countdownTimer;
  Timer? gameTimer;
  bool _isTransitioningToRedLight = false;
  bool _hasReducedCountdownForStable = false;

  /// Input image metadata for overlay (from last processed frame).
  Size? get overlayImageSize => poseDetectionService.lastInputImageSize;
  InputImageRotation get overlayRotation =>
      poseDetectionService.lastInputImageRotation ?? InputImageRotation.rotation0deg;
  CameraLensDirection get overlayLensDirection =>
      cameraService.controller?.description.lensDirection ?? CameraLensDirection.front;

  Future<void> initializeGame() async {
    gameSession = GameSession(
      greenLightDuration: settings.getRandomDurationInRange(
        settings.greenLightDurationSecondsMin,
        settings.greenLightDurationSecondsMax,
      ),
      redLightDuration: settings.getRandomDurationInRange(
        settings.redLightDurationSecondsMin,
        settings.redLightDurationSecondsMax,
      ),
    );

    // Services are already initialized from StartScreen
    // Just start the camera stream and game-specific setup
    await cameraService.startPreview();
    cameraService.imageStream?.listen(processImage);

    unawaited(audioService.playLobbySound());
    unawaited(audioService.speak(GameConstants.welcomeMessage));

    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdownSeconds--;
      notifyListeners();

      if (countdownSeconds <= 4 && countdownSeconds > 0) {
        await audioService.speak(countdownSeconds.toString());
      }

      if (countdownSeconds <= 0) {
        timer.cancel();
        await startGame();
      }
    });
  }

  Future<void> startGame() async {
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
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final elapsed = DateTime.now().difference(
        gameSession.currentPhaseStartTime!,
      );

      switch (gameSession.currentState) {
        case GameState.greenLight:
          if (elapsed >= gameSession.greenLightDuration &&
              !_isTransitioningToRedLight) {
            _isTransitioningToRedLight = true;
            await switchToRedLight()
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
            await switchToGreenLight();
          }
          break;
        case GameState.victory:
          timer.cancel();
          // Victory state is handled by _winGame(), no additional action needed
          break;
        case GameState.gameOver:
          timer.cancel();
          await endGame();
          break;
        default:
          break;
      }
    });
  }

  Future<void> switchToRedLight() async {
    baselinePose = null;
    gameSession.redLightDuration = settings.getRandomDurationInRange(
      settings.redLightDurationSecondsMin,
      settings.redLightDurationSecondsMax,
    );
    gameSession.advanceState(); // Move to red light
    notifyListeners(); // Visual updates immediately

    try {
      await audioService.announceRedLight(GameConstants.redLightMessage);
    } catch (e) {
      // Continue anyway - don't let audio issues block game functionality
    }

    await Future.delayed(
      Duration(milliseconds: settings.redLightFreezeGraceMs),
    );

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
      gameSession.greenLightDuration = settings.getRandomDurationInRange(
        settings.greenLightDurationSecondsMin,
        settings.greenLightDurationSecondsMax,
      );
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
  Future<void> restartGame() async {
    // Reset game session with current settings
    gameSession = GameSession(
      greenLightDuration: settings.getRandomDurationInRange(
        settings.greenLightDurationSecondsMin,
        settings.greenLightDurationSecondsMax,
      ),
      redLightDuration: settings.getRandomDurationInRange(
        settings.redLightDurationSecondsMin,
        settings.redLightDurationSecondsMax,
      ),
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
    unawaited(audioService.playLobbySound());
    startCountdown();
    notifyListeners();
  }

  /// Go back to home screen
  Future<void> goHome() async {
    gameTimer?.cancel();
    countdownTimer?.cancel();
    await audioService.stopLobbySound();
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
      await endGame();
    }
  }

  bool checkSimpleMovement(Pose current, Pose baseline) {
    final threshold = settings.movementThresholdPx;

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
    if (isPlayerStable &&
        countdownSeconds > 10 &&
        !_hasReducedCountdownForStable) {
      _hasReducedCountdownForStable = true;
      countdownSeconds = 10;
      notifyListeners();
    }
  }

  /// Update pose detection (single player)
  Future<void> updatePoseDetection(Pose? pose) async {
    if (pose == null) {
      isPlayerDetected = false;
      currentPose = null;
      stabilityFrames = 0;
      isPlayerStable = false;
      playerDetectionAnnounced = false;
      return;
    }

    currentPose = pose;
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

    isPlayerStable = stabilityFrames >= settings.stabilityFramesRequired;

    // Handle detection announcement
    await handleDetectionAnnouncement();
  }

  Future<void> processImage(CameraImage image) async {
    if (isProcessing) return;

    isProcessing = true;

    try {
      final pose = await poseDetectionService.detectFirstPose(image);
      await updatePoseDetection(pose);

      // Step 3: Check for movement violations during red light
      if (gameSession.currentState == GameState.redLight) {
        await checkForMovementViolations();
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
