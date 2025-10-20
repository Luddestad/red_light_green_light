import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/player_tracker.dart';
import '../models/difficulty_settings.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/light_indicator_widget.dart';
import '../widgets/enhanced_player_status_widget.dart';
import '../widgets/movement_overlay_widget.dart';
import '../widgets/game_over_screen.dart';

/// Main game screen for Red Light Green Light
class GameScreen extends StatefulWidget {
  final int playerCount;
  final DifficultySettings difficulty;

  const GameScreen({
    super.key,
    this.playerCount = 2,
    this.difficulty = const DifficultySettings(
      level: GameDifficulty.easy,
      displayName: 'Easy',
      description: 'Default difficulty',
      minGreenLightDuration: 3.0,
      maxGreenLightDuration: 6.0,
      minRedLightDuration: 3.0,
      maxRedLightDuration: 5.0,
      unpredictabilityFactor: 0.1,
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
  List<Pose> _currentPoses = [];
  bool _isProcessing = false;
  int _frameCount = 0;
  
  // Robust multi-player detection system
  List<PlayerTracker> _playerTrackers = [];
  bool _systemInitialized = false;
  int _detectionStabilityFrames = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _initializePlayerTrackers();
  }

  /// Initialize player trackers for multi-player detection
  void _initializePlayerTrackers() {
    _playerTrackers.clear();
    // Single-player mode: only one tracker is needed
    _playerTrackers.add(PlayerTracker(
      playerIndex: 0,
      playerName: 'Player 1',
    ));
    print('🎯 Initialized ${_playerTrackers.length} player trackers');
  }

  Future<void> _initializeGame() async {
    // Initialize game session with difficulty settings
    _gameSession = GameSession(
      greenLightDuration: widget.difficulty.getGreenLightDuration(),
      redLightDuration: widget.difficulty.getRedLightDuration(),
    );
  // Single-player game: initialize a single player position
  _gameSession.initializePositions(1);

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
    await _audioService.speak(
      'Welcome to Red Light Green Light! Get in your position. Game will start in 20 seconds.'
    );

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
        _audioService.speak('5 seconds until game starts! Get ready!');
      } else if (_countdownSeconds <= 4) {
        _audioService.speak(_countdownSeconds.toString());
      }
    });
  }

  Future<void> _startGame() async {
    // Check if detection system is stable and players are detected
  final detectedPlayers = _playerTrackers.where((t) => t.isDetected).length;
  final stablePlayers = _playerTrackers.where((t) => t.isStable).length;
    
    // IMPROVED: Game can start with stable players (not just detected)
    bool canStart;
    // Single-player: need at least 1 stable player
    canStart = (stablePlayers >= 1);
    
    if (!canStart) {
      print('⚠️ Detection not ready: ${detectedPlayers}/${widget.playerCount} detected, ${stablePlayers} stable, system: $_systemInitialized');
      await _audioService.speak('Waiting for at least one stable player. Stand in front of the camera and stay very still for a few seconds.');
      return;
    }

    // Single-player: no multi-player warnings

    print('✅ Game starting with ${detectedPlayers} detected players (${stablePlayers} stable)');

    // Stop the countdown timer since game is starting
    _countdownTimer?.cancel();
    print('⏱️ Countdown timer stopped - game starting');

    // Stop lobby music when game starts
    await _audioService.stopLobbySound();

    // Reset baseline for the single tracker
    for (final tracker in _playerTrackers) {
      tracker.resetBaseline();
    }

    // Reset detection announcements since game is starting
    _announcedPlayers.clear();
    _allPlayersAnnouncementMade = false;

    _gameSession.advanceState(); // Move to countdown
    _gameSession.advanceState(); // Move to green light

  await _audioService.speak('Game started! Green light!');
    
    _startGameLoop();
    setState(() {});
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_gameSession.currentPhaseStartTime!);
      
      switch (_gameSession.currentState) {
        case GameState.greenLight:
          print('🟢 Green light active - elapsed: ${elapsed.inSeconds}s/${_gameSession.greenLightDuration.inSeconds}s');
          if (elapsed >= _gameSession.greenLightDuration) {
            print('🟢 → 🔴 Switching to red light');
            _switchToRedLight().then((_) {
              print('🔴 Red light transition completed');
            }).catchError((error) {
              print('🔴 Red light transition error: $error');
            });
          }
          break;
        case GameState.redLight:
          print('🔴 Red light active - elapsed: ${elapsed.inSeconds}s/${_gameSession.redLightDuration.inSeconds}s');
          if (elapsed >= _gameSession.redLightDuration) {
            print('🔴 → 🟢 Switching to green light');
            _switchToGreenLight();
          }
          break;
        case GameState.victory:
          print('🏆 Victory state detected - celebration time!');
          timer.cancel();
          // Victory state is handled by _winGame(), no additional action needed
          break;
        case GameState.gameOver:
          print('🏁 Game over state detected - ending game');
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
      print('🔴 Attempting red light announcement...');
      await _audioService.announceRedLight('Red light! Freeze!');
      print('🔴 Red light announcement completed successfully');
    } catch (e) {
      print('🔴 Red light announcement failed: $e');
      // Continue anyway - don't let audio issues block game functionality
    }
    
    // Set baseline poses for all stable players at the moment red light starts
    print('🔴 Setting baselines for red light...');
    for (final tracker in _playerTrackers) {
      print('   ${tracker.playerName}: stable=${tracker.isStable}, hasPose=${tracker.currentPose != null}');
      if (tracker.isStable && tracker.currentPose != null) {
        tracker.setBaseline(tracker.currentPose!);
        print('📍 Set red light baseline for ${tracker.playerName}');
      } else {
        print('⚠️ Cannot set baseline for ${tracker.playerName} - missing requirements');
      }
    }
    
    // Generate new red light duration based on difficulty
    _gameSession.redLightDuration = widget.difficulty.getRedLightDuration();
    print('🔴 Red light duration: ${_gameSession.redLightDuration.inMilliseconds}ms');
    
    // Only start movement detection after the announcement is complete
    _gameSession.advanceState(); // Move to red light
    setState(() {});
  }

  Future<void> _switchToGreenLight() async {
    if (_gameSession.isGameOver) {
      _gameSession.advanceState(); // Move to game over
    } else {
      // Generate new green light duration based on difficulty
      _gameSession.greenLightDuration = widget.difficulty.getGreenLightDuration();
      print('🟢 Green light duration: ${_gameSession.greenLightDuration.inMilliseconds}ms');
      
      _gameSession.advanceState(); // Move to green light
      await _audioService.speak('Green light! Go!');
    }
    setState(() {});
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;

    // Process every 3rd frame for better responsiveness
    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _isProcessing = true;

    try {
  // Step 1: Run pose detection only
  final poses = await _poseService.detectPoses(image);

  // Step 2: Update all player trackers with new detection results
  await _updatePlayerTrackers(const [], poses);

      // Step 3: Check for movement violations during red light
      if (_gameSession.currentState == GameState.redLight) {
        await _checkForMovementViolations();
      }

      // Step 4: Update system stability
      _updateSystemStability();

      // Log detection results occasionally (reduced frequency for performance)
      if (_frameCount % 300 == 0) { // Every ~10 seconds
        _logDetectionStatus();
      }

    } catch (e) {
      print('Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // This method is now replaced by simple motion detection

  // ignore: unused_element
  bool _hasSignificantMovement(List<double> currentPose, List<double> baselinePose) {
    // Handle different length poses by using the minimum length
    final minLength = math.min(currentPose.length, baselinePose.length);
    if (minLength < 2) return false; // Need at least 1 landmark
    
    // Less sensitive movement threshold to allow minor adjustments
    const double movementThreshold = 0.25; // 25cm movement threshold
    
    // Check landmarks up to the minimum length
    for (int i = 0; i < minLength; i += 2) {
      if (i + 1 < minLength) {
        final dx = currentPose[i] - baselinePose[i];
        final dy = currentPose[i + 1] - baselinePose[i + 1];
        final distance = math.sqrt(dx * dx + dy * dy); // Fix: use sqrt instead of abs
        
        // Different thresholds for different body parts
        double threshold = movementThreshold;
        final landmarkIndex = i ~/ 2;
        
        switch (landmarkIndex) {
          case 0: // nose
            threshold = movementThreshold * 1.2; // 30cm for head - allow natural head movement
            break;
          case 1: case 2: // shoulders
            threshold = movementThreshold * 1.5; // 37.5cm for shoulders
            break;
          case 3: case 4: // elbows
            threshold = movementThreshold * 2.5; // 62.5cm for elbows - allow natural arm positioning
            break;
          case 5: case 6: // wrists
            threshold = movementThreshold * 3.0; // 75cm for wrists - only catch deliberate arm movements
            break;
          case 7: case 8: // hips
            threshold = movementThreshold * 1.8; // 45cm for hips - allow natural stance adjustments
            break;
        }
        
        if (distance > threshold) { // Fix: compare distance directly, not threshold squared
          final landmarkName = _getLandmarkName(i ~/ 2);
          print('🚨 Movement detected at $landmarkName: distance=${distance.toStringAsFixed(4)}, threshold=${threshold.toStringAsFixed(4)}');
          print('   Current: (${currentPose[i].toStringAsFixed(3)}, ${currentPose[i + 1].toStringAsFixed(3)})');
          print('   Baseline: (${baselinePose[i].toStringAsFixed(3)}, ${baselinePose[i + 1].toStringAsFixed(3)})');
          return true;
        } else {
          // Occasionally log non-violations for debugging
          if (_frameCount % 150 == 0) { // Every ~10 seconds
            final landmarkName = _getLandmarkName(i ~/ 2);
            print('✅ OK at $landmarkName: distance=${distance.toStringAsFixed(4)}, threshold=${threshold.toStringAsFixed(4)}');
          }
        }
      }
    }
    
    return false;
  }

  String _getLandmarkName(int landmarkIndex) {
    switch (landmarkIndex) {
      case 0: return 'nose';
      case 1: return 'left shoulder';
      case 2: return 'right shoulder';
      case 3: return 'left elbow';
      case 4: return 'right elbow';
      case 5: return 'left wrist';
      case 6: return 'right wrist';
      case 7: return 'left hip';
      case 8: return 'right hip';
      default: return 'unknown';
    }
  }

  // ignore: unused_element
  List<double> _extractPoseLandmarks(Pose pose) {
    final landmarks = <double>[];
    
    // For Red Light Green Light, we need ANY visible landmarks for movement detection
    // Try all major landmarks and add whatever we can detect
    final allLandmarks = [
      // Upper body (most likely when sitting at desk)
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      // Lower body (if visible)
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];
    
    // Add any landmarks that are detected (no minimum requirement)
    for (final landmarkType in allLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null && landmark.x > 0 && landmark.y > 0) {
        landmarks.addAll([landmark.x, landmark.y]);
      }
    }
    
    // Only log occasionally to avoid spam
    if (landmarks.length > 0) {
      print('📍 Extracted ${landmarks.length ~/ 2} landmarks from pose');
    }
    return landmarks;
  }

  /// Track detection announcements to avoid repeating them
  final Set<int> _announcedPlayers = {};
  bool _allPlayersAnnouncementMade = false;

  /// Update all player trackers with new detection results using proper individual assignment
  Future<void> _updatePlayerTrackers(List<dynamic> faces, List<Pose> poses) async {
    // STEP 1: Clear all current assignments
    for (final tracker in _playerTrackers) {
      tracker.clearDetection();
    }
    
    // STEP 2: Only proceed if we have actual people detected
    final actualPeopleCount = math.max(faces.length, poses.length);
    if (actualPeopleCount == 0) {
      print('🚫 No people detected in camera');
      _resetDetectionAnnouncements(); // Reset when no one detected
      return;
    }
    
    // STEP 3: Limit detections to actual number of people present
    final maxPlayers = math.min(_playerTrackers.length, actualPeopleCount);
    
    // STEP 4: Create combined detections (face + pose pairs)
  final detections = _createDetectionPairs(poses);
    
    // STEP 5: Sort detections spatially (left to right)
    detections.sort((a, b) => (a['x'] as double).compareTo(b['x'] as double));
    
    // STEP 6: Assign detections to trackers - ONLY assign to trackers we have real people for
    for (int i = 0; i < maxPlayers && i < detections.length; i++) {
      final tracker = _playerTrackers[i];
      final detection = detections[i];
      
      tracker.forceAssignment(pose: detection['pose'] as Pose?);
      print('👤 Assigned Pose to ${tracker.playerName} at x=${(detection['x'] as double).toStringAsFixed(1)}');
    }
    
    // STEP 7: Remaining trackers stay unassigned (representing players not present)
    final unassignedCount = _playerTrackers.length - maxPlayers;
    if (unassignedCount > 0) {
      print('⚪ ${unassignedCount} player(s) not detected in camera');
    }
    
    print('🎯 Detection Summary: ${actualPeopleCount} people detected, ${maxPlayers} trackers assigned');
    
    // STEP 8: Handle detection announcements
    await _handleDetectionAnnouncements();
  }

  /// Handle TTS announcements for player detection
  Future<void> _handleDetectionAnnouncements() async {
    // Only announce during waiting phase (before game starts)
    if (_gameSession.currentState != GameState.waiting) {
      print('🔇 Skipping announcements - not in waiting state: ${_gameSession.currentState}');
      return;
    }

    final detectedTrackers = _playerTrackers.where((t) => t.isDetected).toList();
    final stableDetectedTrackers = _playerTrackers.where((t) => t.isDetected && t.isStable).toList();
    
    print('🎤 Detection announcement check: ${detectedTrackers.length} detected, ${stableDetectedTrackers.length} stable');
    
    // Announce individual players as they are detected (don't wait for full stability)
    for (final tracker in detectedTrackers) {
      if (!_announcedPlayers.contains(tracker.playerIndex)) {
        _announcedPlayers.add(tracker.playerIndex);
        
        if (widget.playerCount == 1) {
          await _audioService.speak('Player detected! Great, I can see you clearly.');
        } else {
          await _audioService.speak('${tracker.playerName} detected! Looking good.');
        }
        
        print('🎤 Announced detection of ${tracker.playerName}');
      }
    }
    
    // Check if all expected players are stable (use stable count for "all ready" announcement)
    final detectedCount = detectedTrackers.length;
    final stableCount = stableDetectedTrackers.length;
    final expectedPlayerCount = widget.playerCount;
    
    print('🎤 Ready check: detected=$detectedCount, stable=$stableCount, expected=$expectedPlayerCount, announced=$_allPlayersAnnouncementMade');
    
    // Announce when players are ready (use stable count for auto-reduction)
    if (!_allPlayersAnnouncementMade && stableCount > 0) {
      bool allReady = false;
      String readyMessage = '';
      
      if (widget.playerCount == 1 && stableCount >= 1) {
        allReady = true;
        readyMessage = 'Perfect! I can see you clearly and you are stable. Ready to play - stand still and wait for the countdown!';
      } else if (widget.playerCount > 1) {
        if (stableCount >= expectedPlayerCount) {
          // All expected players stable
          allReady = true;
          readyMessage = 'Excellent! All $expectedPlayerCount players detected and stable. Ready to play - everyone stand still and wait for the countdown!';
        } else if (stableCount >= math.max(1, (expectedPlayerCount * 0.7).round())) {
          // Sufficient stable players for game to start
          allReady = true;
          readyMessage = 'Good! $stableCount players detected and stable. The game can start - everyone stand still and wait for the countdown!';
        }
      }
      
      if (allReady) {
        _allPlayersAnnouncementMade = true;
        await _audioService.speak(readyMessage);
        print('🎤 Announced all players ready: $readyMessage');
        
        // Auto-reduce countdown if all players detected and timer is above 10 seconds
        if (_countdownSeconds > 10) {
          final oldCountdown = _countdownSeconds;
          print('⏰ All players ready! Reducing countdown from $oldCountdown to 10 seconds');
          _countdownSeconds = 10;
          setState(() {}); // Update UI to show new countdown
          
          // Let players know about the countdown reduction
          await Future.delayed(const Duration(milliseconds: 500)); // Brief pause after ready message
          await _audioService.speak('Great! Since everyone is ready, the countdown has been reduced to 10 seconds!');
        }
      }
    }
  }

  /// Reset detection announcements when players are no longer detected
  void _resetDetectionAnnouncements() {
    final currentDetectedCount = _playerTrackers.where((t) => t.isDetected).length;
    
    // If no players detected, reset all announcements
    if (currentDetectedCount == 0) {
      _announcedPlayers.clear();
      _allPlayersAnnouncementMade = false;
      print('🔄 Reset detection announcements - no players detected');
    } else {
      // Remove announcements for players no longer detected
      final currentDetectedIndices = _playerTrackers
          .where((t) => t.isDetected)
          .map((t) => t.playerIndex)
          .toSet();
      
      _announcedPlayers.retainWhere((index) => currentDetectedIndices.contains(index));
      
      // Reset all-ready announcement if we lost players
      if (currentDetectedCount < _announcedPlayers.length) {
        _allPlayersAnnouncementMade = false;
      }
    }
  }
  
  /// Create detection pairs by combining faces and poses spatially
  List<Map<String, dynamic>> _createDetectionPairs(List<Pose> poses) {
    final detections = poses.map((pose) => {
      'pose': pose,
      'x': _getPoseCenter(pose).dx,
    }).toList();

    return detections;
  }

  // Old conflict resolution method removed - now handled in _updatePlayerTrackers

  /// Check for movement violations during red light
  Future<void> _checkForMovementViolations() async {
    if (_gameSession.currentState != GameState.redLight) {
      print('⚠️ Movement check skipped - not in red light state: ${_gameSession.currentState}');
      return;
    }
    
    print('🔍 Checking for movement violations...');
    
    // Debug: Log all tracker states
    print('📊 All tracker states:');
    for (int i = 0; i < _playerTrackers.length; i++) {
      final tracker = _playerTrackers[i];
      print('   ${tracker.playerName}: detected=${tracker.isDetected}, stable=${tracker.isStable}, hasBaseline=${tracker.baselinePose != null}');
    }
    
    // Only check trackers that are actually assigned to real people
    final activeTrackers = _playerTrackers.where((t) => t.isDetected && t.isStable).toList();
    
    if (activeTrackers.isEmpty) {
      print('⚠️ No active stable players to check for violations');
      return;
    }
    
    print('🎯 Checking ${activeTrackers.length} active players for movement');
    
    for (final tracker in activeTrackers) {
      // Only eliminate players who are actually present and moving
      if (tracker.isDetected && tracker.isStable && tracker.checkForMovement()) {
        print('🚨 Movement violation detected for ${tracker.playerName} (actually present and moving)');
        
        // Verify this player position is not already eliminated
        final playerPosition = _gameSession.playerPositions.firstWhere(
          (p) => p.positionIndex == tracker.playerIndex,
          orElse: () => throw Exception('Player position not found'),
        );
        
        if (!playerPosition.isEliminated) {
          await _eliminatePlayer(tracker.playerIndex);
          break; // Only eliminate one player at a time
        } else {
          print('⚠️ Player ${tracker.playerName} already eliminated, skipping');
        }
      }
    }
  }

  /// Update system stability based on actual people present
  void _updateSystemStability() {
    final stableTrackers = _playerTrackers.where((t) => t.isStable).length;
    final detectedTrackers = _playerTrackers.where((t) => t.isDetected).length;
    
    // NEW: Be realistic about system requirements based on actual people present vs expected
    bool systemGood;
    if (widget.playerCount == 1) {
      // Single player: just need 1 person detected
      systemGood = detectedTrackers >= 1;
    } else {
      // Multi-player: Need at least 1 person detected, but don't require all expected players
      // This allows 2-4 player games to work even if fewer people are actually present
      systemGood = detectedTrackers >= 1 && stableTrackers >= math.min(detectedTrackers, widget.playerCount * 0.5);
    }
    
    if (systemGood) {
      _detectionStabilityFrames++;
    } else {
      // Decay slowly to handle temporary detection drops
      _detectionStabilityFrames = math.max(0, _detectionStabilityFrames - 2);
    }
    
    _systemInitialized = _detectionStabilityFrames >= 30; // ~1 second at 30fps
    
    // Reset announcements if detection becomes unstable
    if (!systemGood) {
      _resetDetectionAnnouncements();
    }
  }

  /// Log current detection status for debugging
  void _logDetectionStatus() {
    final detected = _playerTrackers.where((t) => t.isDetected).length;
    final stable = _playerTrackers.where((t) => t.isStable).length;
    final moving = _playerTrackers.where((t) => t.isMoving).length;
    
    print('🎯 Detection Status: ${detected}/${_playerTrackers.length} detected, ${stable} stable, ${moving} moving');
    print('📊 System initialized: $_systemInitialized (stability frames: $_detectionStabilityFrames)');
    
    for (int i = 0; i < _playerTrackers.length; i++) {
      final tracker = _playerTrackers[i];
      if (tracker.isDetected) {
        print('   Player ${i + 1}: ${tracker.toString()}');
      }
    }
  }

  // Old motion detection methods removed - now using robust PlayerTracker system

  Future<void> _eliminatePlayer(int positionIndex) async {
    print('🔥 _eliminatePlayer called for position $positionIndex');
    
    final position = _gameSession.activePlayers.firstWhere(
      (p) => p.positionIndex == positionIndex
    );
    
    print('🔥 Found player: ${position.positionName}');
    _gameSession.eliminatePlayer(positionIndex);
    
    print('🔥 About to call announceElimination');
    // Play elimination sound and announcement
    await _audioService.announceElimination(
      '${position.positionName} is eliminated! Movement detected during red light!'
    );
    print('🔥 announceElimination completed');

    if (_gameSession.isGameOver) {
      _gameSession.advanceState(); // Move to game over
    }

    setState(() {});
  }

  Future<void> _winGame() async {
    try {
      print('🏆 WIN GAME BUTTON PRESSED!');
      print('🏆 Current game state: ${_gameSession.currentState}');
      print('🏆 Active players: ${_gameSession.activePlayers.length}');
      
      // Cancel the game timer
      _gameTimer?.cancel();
      print('🏆 Game timer cancelled');
      
      // Set the winner (for single player, it's position 0)
      if (_gameSession.activePlayers.isNotEmpty) {
        final winnerPlayer = _gameSession.activePlayers.first;
        _gameSession.winner = winnerPlayer;
        print('🏆 Winner set: ${winnerPlayer.positionName}');
      } else {
        print('🏆 No active players found, but setting winner anyway');
        // For single player, create a winner position manually
        if (_gameSession.playerPositions.isNotEmpty) {
          _gameSession.winner = _gameSession.playerPositions.first;
          print('🏆 Winner set from playerPositions: ${_gameSession.playerPositions.first.positionName}');
        }
      }
      
      // Set victory state (different from game over)
      _gameSession.currentState = GameState.victory;
      print('🏆 Game state set to: ${_gameSession.currentState}');
      
      // Update UI immediately
      setState(() {});
      print('🏆 UI updated - should show game over screen');
      
      // Play victory sound first, then TTS announcement
      await _audioService.announceVictory(
        'Congratulations! You reached the phone and won the game! Victory!'
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
    
    String message;
    if (_gameSession.winner != null) {
      message = 'Game over! ${_gameSession.winner!.positionName} wins! Congratulations!';
    } else {
      message = 'Game over! I win! Better luck next time!';
    }
    
    // Play game over sound and announcement
    await _audioService.announceGameOver(message);
    
    // Set to game over state to show the overlay
    _gameSession.currentState = GameState.gameOver;
    setState(() {});
  }

  /// Restart the game
  void _restartGame() {
    // Reset game session
    _gameSession = GameSession();
    _gameSession.initializePositions(widget.playerCount);
    
    // Reset player trackers
    _initializePlayerTrackers();
    
    // Reset detection system
    _systemInitialized = false;
    _detectionStabilityFrames = 0;
    
    // Cancel any existing timer
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Reset countdown
    _countdownSeconds = 10;
    
    // Start countdown again
    _startCountdown();
    
    setState(() {});
    print('🔄 Game restarted');
  }

  /// Get the center point of a pose
  Offset _getPoseCenter(Pose pose) {
    double sumX = 0;
    double sumY = 0;
    int count = 0;
    
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > 0.5) {
        sumX += landmark.x;
        sumY += landmark.y;
        count++;
      }
    }
    
    return count > 0 ? Offset(sumX / count, sumY / count) : Offset.zero;
  }

  /// Go back to home screen
  void _goHome() {
    // Clean up
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    
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
              countdownSeconds: _gameSession.currentState == GameState.countdown ? _countdownSeconds : null,
            ),
          ),

          // Large countdown timer
          if (_gameSession.currentState == GameState.waiting && _countdownSeconds > 0)
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

          // Player status indicators (moved above win button)
          Positioned(
            bottom: 200, // Moved higher to avoid blocking win button
            left: 20,
            right: 20,
            child: EnhancedPlayerStatusWidget(
              playerTrackers: _playerTrackers,
              currentRound: _gameSession.currentRound,
              showDetailedInfo: true,
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
                  print('🎯 WIN BUTTON TAPPED!');
                  print('🎯 Current game state: ${_gameSession.currentState}');
                  print('🎯 Active players: ${_gameSession.activePlayers.length}');
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
          if (_gameSession.isDetectingMovement)
            Positioned.fill(
              child: IgnorePointer( // Allow touches to pass through
                child: MovementOverlayWidget(
                  poses: _currentPoses,
                  cameraSize: _cameraService.controller?.value.previewSize ?? Size.zero,
                ),
              ),
            ),

          // Pose detection status
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _systemInitialized ? Icons.groups : Icons.person_search,
                        color: _systemInitialized ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Players: ${_playerTrackers.where((t) => t.isDetected).length}/${_playerTrackers.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _systemInitialized ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stable: ${_playerTrackers.where((t) => t.isStable).length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  if (_gameSession.currentState == GameState.redLight)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          color: _playerTrackers.any((t) => t.isMoving) ? Colors.red : Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Moving: ${_playerTrackers.where((t) => t.isMoving).length}',
                          style: const TextStyle(color: Colors.yellow, fontSize: 10),
                        ),
                      ],
                    ),
                  if (_gameSession.currentState == GameState.waiting && !_systemInitialized)
                    const Text(
                      'Stand in front of camera and stay still',
                      style: TextStyle(color: Colors.yellow, fontSize: 10),
                    ),
                ],
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
                      Icon(
                        Icons.emoji_events,
                        color: Colors.yellow,
                        size: 120,
                      ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 24),
                                SizedBox(width: 10),
                                Text('Play Again', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                          
                          // Home Button
                          ElevatedButton(
                            onPressed: _goHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
                if (_gameSession.currentState == GameState.waiting)
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Now'),
                  ),
              ],
            ),
          ),
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
