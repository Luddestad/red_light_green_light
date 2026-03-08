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
      poseDetectionService.lastInputImageRotation ??
      InputImageRotation.rotation0deg;
  CameraLensDirection get overlayLensDirection =>
      cameraService.controller?.description.lensDirection ??
      CameraLensDirection.front;

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

  /// TODO 1: Track player stability over multiple frames.
  ///
  /// A single frame isn't enough to know if the player is reliably detected.
  /// You need several consecutive "good" frames before considering them stable.
  /// This prevents jitter from causing false detections.
  ///
  /// When pose is null: reset everything (isPlayerDetected, currentPose,
  /// stabilityFrames, isPlayerStable, playerDetectionAnnounced).
  ///
  /// When pose is not null:
  /// 1. Store the pose in currentPose and set isPlayerDetected = true
  /// 2. Count how many landmarks have likelihood > 0.5
  /// 3. If at least 5 are valid: increment stabilityFrames
  ///    Otherwise: decrement stabilityFrames (but don't go below 0)
  /// 4. Set isPlayerStable = true when stabilityFrames reaches
  ///    settings.stabilityFramesRequired
  /// 5. Call handleDetectionAnnouncement() at the end
  ///
  /// Useful: pose.landmarks.values, math.max(), settings.stabilityFramesRequired
  ///
  /// See hints/hint1.md if you get stuck!
  Future<void> updatePoseDetection(Pose? pose) async {
    // YOUR CODE HERE
    throw UnimplementedError('Implement updatePoseDetection');
  }

  /// TODO 2: Announce red light, wait for the player to freeze, then
  /// capture their pose as the baseline.
  ///
  /// Without the grace period, the player would be eliminated while still
  /// reacting to the announcement — that's not fair!
  ///
  /// The state transition and duration randomization are done for you.
  /// You need to implement the announcement + baseline capture:
  ///
  /// 1. Announce red light: audioService.announceRedLight(GameConstants.redLightMessage)
  ///    Wrap in try/catch so audio errors don't break the game.
  /// 2. Wait for the grace period: settings.redLightFreezeGraceMs milliseconds
  ///    Use: await Future.delayed(Duration(milliseconds: ...))
  /// 3. If the player is stable and has a pose (currentPose != null):
  ///    - Save currentPose as baselinePose (their "freeze" position)
  ///    - Set isPlayerMoving = false
  ///
  /// See hints/hint2.md if you get stuck!
  Future<void> switchToRedLight() async {
    baselinePose = null;
    gameSession.redLightDuration = settings.getRandomDurationInRange(
      settings.redLightDurationSecondsMin,
      settings.redLightDurationSecondsMax,
    );
    gameSession.advanceState(); // Move to red light
    notifyListeners(); // Visual updates immediately

    // YOUR CODE HERE
    throw UnimplementedError('Implement switchToRedLight');
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

  /// TODO 3: Check if the player moved during red light.
  ///
  /// This method is called every frame during red light. You need to
  /// decide whether the player has violated the "freeze" rule.
  ///
  /// But you can't just blindly check — there are several conditions
  /// that must ALL be true before checking movement:
  ///
  /// Guard conditions (return early if any fail):
  /// 1. Game must be in GameState.redLight
  /// 2. Game must not already be over (gameSession.isGameOver)
  ///    and player must not already be caught (isPlayerMoving)
  /// 3. Player must be stable (isPlayerStable) and both
  ///    baselinePose and currentPose must exist
  ///
  /// If all guards pass:
  /// - Call checkSimpleMovement(currentPose!, baselinePose!)
  /// - If it returns true: set isPlayerMoving = true and call endGame()
  ///
  /// See hints/hint3.md if you get stuck!
  Future<void> checkForMovementViolations() async {
    // YOUR CODE HERE
    throw UnimplementedError('Implement checkForMovementViolations');
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

  Future<void> processImage(CameraImage image) async {
    if (isProcessing) return;

    isProcessing = true;

    try {
      final pose = await poseDetectionService.detectPose(image);
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
