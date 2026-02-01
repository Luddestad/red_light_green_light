import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:red_light_green_light/core/constants/game_constants.dart';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/difficulty_settings.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/light_indicator_widget.dart';
import '../widgets/movement_overlay_widget.dart';
import '../widgets/game_over_screen.dart';

/// Main game screen for Red Light Green Light (Single Player)
class GameScreen extends StatefulWidget {
  final DifficultySettings difficulty;

  const GameScreen({
    super.key,
    this.difficulty = const DifficultySettings(
      level: GameDifficulty.hard,
      displayName: 'Hard',
      description: 'Very unpredictable, shorter intervals',
      minGreenLightDuration: 1.5,
      maxGreenLightDuration: 4.0,
      minRedLightDuration: 2.0,
      maxRedLightDuration: 4.0,
      unpredictabilityFactor: 0.5, // High variation
    ),
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Services
  final CameraService _cameraService = CameraService();
  final PoseDetectionService _poseService = PoseDetectionService();
  final AudioService _audioService = AudioService();

  // Game state
  late GameSession _gameSession;
  Timer? _gameTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 20;

  // Detection state
  bool _isProcessing = false;
  int _frameCount = 0;

  // Simple single-player pose tracking
  Pose? _currentPose;
  Pose? _baselinePose;
  int _stabilityFrames = 0;
  bool _isPlayerDetected = false;
  bool _isPlayerStable = false;
  bool _isPlayerMoving = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // Initialize game session with difficulty settings
    _gameSession = GameSession(
      greenLightDuration: widget.difficulty.getGreenLightDuration(),
      redLightDuration: widget.difficulty.getRedLightDuration(),
    );
    // Single-player game: initialize player position
    _gameSession.initializePositions();

    // Initialize services (face detection disabled for single-player)
    await _cameraService.initialize();
    await _poseService.initialize();
    await _audioService.initialize();

    // Start camera
    await _cameraService.startPreview();

    // Start listening to camera images
    _cameraService.imageStream?.listen(_processImage);

    // Start lobby music
    await _audioService.playLobbySound();

    setState(() {});

    // Announce game start (single-player)
    await _audioService.speak(GameConstants.welcomeMessage);

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _startGame();
      } else if (_countdownSeconds == 5) {
        _audioService.speak(GameConstants.fiveSecondsLeft);
      } else if (_countdownSeconds <= 4) {
        _audioService.speak(_countdownSeconds.toString());
      }
    });
  }

  Future<void> _startGame() async {
    // Check if player is stable
    if (!_isPlayerStable) {
      await _audioService.speak(GameConstants.waitingForStableConnection);
      return;
    }

    // Stop the countdown timer since game is starting
    _countdownTimer?.cancel();

    // Stop lobby music when game starts
    await _audioService.stopLobbySound();

    // Reset baseline
    _baselinePose = null;
    _isPlayerMoving = false;

    // Reset detection announcements since game is starting
    _playerDetectionAnnounced = false;

    _gameSession.advanceState(); // Move to countdown
    _gameSession.advanceState(); // Move to green light

    await _audioService.speak(GameConstants.gameStarted);

    _startGameLoop();
    setState(() {});
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(
        _gameSession.currentPhaseStartTime!,
      );

      switch (_gameSession.currentState) {
        case GameState.greenLight:
          if (elapsed >= _gameSession.greenLightDuration) {
            _switchToRedLight().then((_) {}).catchError((error) {
              print('🔴 Red light transition error: $error');
            });
          }
          break;
        case GameState.redLight:
          if (elapsed >= _gameSession.redLightDuration) {
            _switchToGreenLight();
          }
          break;
        case GameState.victory:
          timer.cancel();
          // Victory state is handled by _winGame(), no additional action needed
          break;
        case GameState.gameOver:
          timer.cancel();
          _endGame();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _switchToRedLight() async {
    // Play red light sound and announcement first, THEN start detection
    try {
      await _audioService.announceRedLight(GameConstants.redLightMessage);
    } catch (e) {
      // Continue anyway - don't let audio issues block game functionality
    }
    if (_isPlayerStable && _currentPose != null) {
      _baselinePose = _currentPose;
      _isPlayerMoving = false;
    } else {
      print('⚠️ Cannot set baseline for player - not stable or no pose');
    }

    _gameSession.redLightDuration = widget.difficulty.getRedLightDuration();

    _gameSession.advanceState(); // Move to red light
    setState(() {});
  }

  Future<void> _switchToGreenLight() async {
    if (_gameSession.isGameOver) {
      _gameSession.advanceState(); // Move to game over
    } else {
      // Generate new green light duration based on difficulty
      _gameSession.greenLightDuration = widget.difficulty
          .getGreenLightDuration();

      _gameSession.advanceState(); // Move to green light
      await _audioService.speak(GameConstants.greenLightMessage);
    }
    setState(() {});
  }

  /// Get frame skip value based on game state (adaptive performance)
  int _getFrameSkip() {
    if (!_isPlayerStable) return 2; // Every 2nd frame during initialization
    if (_gameSession.currentState == GameState.redLight)
      return 2; // More frequent during red light
    return 4; // Every 4th frame during green/waiting (save battery)
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;

    // Adaptive frame skipping for better performance
    _frameCount++;
    final frameSkip = _getFrameSkip();
    if (_frameCount % frameSkip != 0) return;

    _isProcessing = true;

    try {
      // Step 1: Run pose detection
      final poses = await _poseService.detectPoses(image);

      // Step 2: Update pose detection state
      await _updatePoseDetection(poses);

      // Step 3: Check for movement violations during red light
      if (_gameSession.currentState == GameState.redLight) {
        await _checkForMovementViolations();
      }

      // Log detection results occasionally
      if (_frameCount % 300 == 0) {
        _logDetectionStatus();
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Track detection announcement to avoid repeating
  bool _playerDetectionAnnounced = false;

  /// Update pose detection (simplified for single player)
  Future<void> _updatePoseDetection(List<Pose> poses) async {
    // Check if we have pose detected
    if (poses.isEmpty) {
      _isPlayerDetected = false;
      _currentPose = null;
      _stabilityFrames = 0;
      _isPlayerStable = false;
      _playerDetectionAnnounced = false;
      print('🚫 No pose detected');
      return;
    }

    // Use the first (best) pose
    _currentPose = poses.first;
    _isPlayerDetected = true;

    // Check pose quality (minimum valid landmarks)
    final validLandmarks = _currentPose!.landmarks.values
        .where((l) => l.likelihood > 0.5)
        .length;

    if (validLandmarks >= 5) {
      _stabilityFrames++;
    } else {
      _stabilityFrames = math.max(0, _stabilityFrames - 1);
    }

    _isPlayerStable = _stabilityFrames >= 4;
    print(
      '👤 Pose detected: ${validLandmarks} landmarks, stable=$_isPlayerStable (${_stabilityFrames}/4)',
    );

    // Handle detection announcement
    await _handleDetectionAnnouncement();
  }

  /// Handle TTS announcement for player detection
  Future<void> _handleDetectionAnnouncement() async {
    // Only announce during waiting phase
    if (_gameSession.currentState != GameState.waiting) {
      return;
    }

    // Announce when player is first detected
    if (_isPlayerDetected && !_playerDetectionAnnounced) {
      _playerDetectionAnnounced = true;
      await _audioService.speak(GameConstants.playerDetectedLobby);
      print('🎤 Announced player detection');
    }

    // Announce when player is stable and ready
    if (_isPlayerStable &&
        _playerDetectionAnnounced &&
        _countdownSeconds > 10) {
      await _audioService.speak(GameConstants.playerStable);
      print('🎤 Announced player ready');

      // Auto-reduce countdown
      _countdownSeconds = 10;
      setState(() {});

      await Future.delayed(const Duration(milliseconds: 500));
      await _audioService.speak(GameConstants.reducedCountdown);

      _playerDetectionAnnounced = false; // Reset
    }
  }

  /// Check for movement violations during red light (simplified)
  Future<void> _checkForMovementViolations() async {
    if (_gameSession.currentState != GameState.redLight) {
      return;
    }

    if (!_isPlayerStable || _baselinePose == null || _currentPose == null) {
      return;
    }

    // Simple pixel-based movement detection
    final moved = _checkSimpleMovement(_currentPose!, _baselinePose!);

    if (moved) {
      print('🚨 Movement violation detected!');
      _isPlayerMoving = true;
      _endGame();
    }
  }

  /// Simple movement detection (80 pixel threshold)
  bool _checkSimpleMovement(Pose current, Pose baseline) {
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

  /// Log current detection status for debugging
  void _logDetectionStatus() {
    print(
      '🎯 Detection: detected=$_isPlayerDetected, stable=$_isPlayerStable, moving=$_isPlayerMoving',
    );
    print('📊 Stability frames: $_stabilityFrames/4');
  }

  Future<void> _winGame() async {
    try {
      _gameTimer?.cancel();

      // Set victory state (different from game over)
      _gameSession.currentState = GameState.victory;
      print('🏆 Game state set to: ${_gameSession.currentState}');

      // Update UI immediately
      setState(() {});
      print('🏆 UI updated - should show game over screen');

      // Play victory sound first, then TTS announcement
      await _audioService.announceVictory(
        'Congratulations! You reached the phone and won the game! Victory!',
      );
      print('🏆 Victory audio completed');
    } catch (e, stackTrace) {
      print('❌ Error in _winGame: $e');
      print('❌ Stack trace: $stackTrace');

      // Still try to show victory screen even if audio fails
      _gameSession.currentState = GameState.victory;
      setState(() {});
    }
  }

  Future<void> _endGame() async {
    _gameTimer?.cancel();

    // Play game over sound and announcement
    await _audioService.announceGameOver(
      "Game over! I win! Better luck next time!",
    );

    // Set to game over state to show the overlay
    _gameSession.currentState = GameState.gameOver;
    setState(() {});
  }

  /// Restart the game
  void _restartGame() {
    // Reset game session
    _gameSession = GameSession();
    _gameSession.initializePositions();

    // Reset detection state
    _currentPose = null;
    _baselinePose = null;
    _stabilityFrames = 0;
    _isPlayerDetected = false;
    _isPlayerStable = false;
    _isPlayerMoving = false;

    // Cancel any existing timer
    _gameTimer?.cancel();
    _countdownTimer?.cancel();

    // Reset countdown
    _countdownSeconds = 20;

    // Start countdown again
    _startCountdown();

    setState(() {});
  }

  /// Go back to home screen
  void _goHome() {
    // Clean up
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _audioService.stopLobbySound();
    // Navigate back
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cameraService.isInitialized)
            Positioned.fill(
              child: _cameraService.getCameraPreview() ?? Container(),
            ),

          // Game state indicator
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: LightIndicatorWidget(
              gameState: _gameSession.currentState,
              countdownSeconds: _gameSession.currentState == GameState.countdown
                  ? _countdownSeconds
                  : null,
            ),
          ),

          // Large countdown timer
          if (_gameSession.currentState == GameState.waiting &&
              _countdownSeconds > 0)
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _countdownSeconds.toString(),
                      style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Get Ready!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 200,
            left: 150,
            child: Row(
              children: [
                if (_gameSession.currentState == GameState.waiting)
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Now'),
                  ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(
                        _isPlayerDetected ? Icons.check_circle : Icons.cancel,
                        color: _isPlayerDetected ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPlayerDetected ? 'Detected' : 'Searching',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(
                        _isPlayerStable
                            ? Icons.verified
                            : Icons.hourglass_empty,
                        color: _isPlayerStable ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPlayerStable ? 'Stable' : 'Stabilizing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Round ${_gameSession.currentRound}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Win button (only show during green light) - MUST be AFTER overlays to be clickable
          if (_gameSession.currentState == GameState.greenLight)
            Positioned(
              bottom: 50, // Moved lower to be accessible
              left: 50,
              right: 50,
              child: ElevatedButton(
                onPressed: () {
                  _winGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10, // Increased elevation to stay on top
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, size: 40, color: Colors.yellow),
                    SizedBox(width: 10),
                    Text(
                      'WIN GAME!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Movement detection overlay
          if (_gameSession.isDetectingMovement && _currentPose != null)
            Positioned.fill(
              child: IgnorePointer(
                // Allow touches to pass through
                child: MovementOverlayWidget(
                  poses: [_currentPose!],
                  cameraSize:
                      _cameraService.controller?.value.previewSize ?? Size.zero,
                ),
              ),
            ),

          // Victory Screen Overlay
          if (_gameSession.currentState == GameState.victory) ...[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade800, Colors.green.shade400],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.yellow, size: 120),
                      const SizedBox(height: 20),
                      Text(
                        'VICTORY!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(3.0, 3.0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Congratulations!',
                        style: TextStyle(
                          color: Colors.yellow.shade200,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You reached the phone and won!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Play Again Button
                          ElevatedButton(
                            onPressed: _restartGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'Play Again',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),

                          // Home Button
                          ElevatedButton(
                            onPressed: _goHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.home, size: 24),
                                SizedBox(width: 10),
                                Text('Home', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Game Over Screen Overlay (for eliminations)
          if (_gameSession.currentState == GameState.gameOver) ...[
            // Actual game over screen
            Positioned.fill(
              child: GameOverScreen(
                gameSession: _gameSession,
                onPlayAgain: _restartGame,
                onGoHome: _goHome,
              ),
            ),
          ],

          // Game controls
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraService.dispose();
    _poseService.dispose();
    super.dispose();
  }
}

/// Game Over Screen
