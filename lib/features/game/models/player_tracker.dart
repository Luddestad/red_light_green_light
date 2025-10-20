import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'distance_adaptive_detection.dart';

/// Robust player tracking system for Red Light Green Light
class PlayerTracker {
  final int playerIndex;
  final String playerName;
  
  // Face tracking
  Face? _currentFace;
  Face? _baselineFace;
  List<Face> _recentFaces = [];
  
  // Pose tracking
  Pose? _currentPose;
  Pose? _baselinePose;
  List<Pose> _recentPoses = [];
  
  // Distance tracking
  double _estimatedDistance = 1.0;
  
  // Position tracking
  double _averageX = 0.0;
  double _averageY = 0.0;
  double _confidenceScore = 0.0;
  
  // Movement detection
  bool _isMoving = false;
  int _movementFrames = 0;
  
  // Stability tracking
  int _stableFrames = 0;
  int _requiredStableFrames = 4; // Reduced from 6 to 4 for even faster stability
  bool _isStable = false;

  PlayerTracker({
    required this.playerIndex,
    required this.playerName,
  });

  /// Update player tracking with new detection results
  void updateDetection({
    List<Face>? faces,
    List<Pose>? poses,
  }) {
    _updateFaceTracking(faces);
    _updatePoseTracking(poses);
    _updatePositionEstimate();
    _updateStability();
  }

  /// Update face tracking
  void _updateFaceTracking(List<Face>? faces) {
    if (faces == null || faces.isEmpty) {
      _currentFace = null;
      return;
    }

    // Find the best matching face based on position continuity
    Face? bestMatch;
    double bestScore = double.infinity;

    for (final face in faces) {
      // Score based on distance from expected position and face size
      double score = _scoreFaceMatch(face);
      if (score < bestScore) {
        bestScore = score;
        bestMatch = face;
      }
    }

    if (bestMatch != null) {
      _currentFace = bestMatch;
      _recentFaces.add(bestMatch);
      
      // Keep only recent faces
      if (_recentFaces.length > 10) {
        _recentFaces.removeAt(0);
      }
    }
  }

  /// Update pose tracking
  void _updatePoseTracking(List<Pose>? poses) {
    if (poses == null || poses.isEmpty) {
      _currentPose = null;
      return;
    }

    // Find the best matching pose
    Pose? bestMatch;
    double bestScore = double.infinity;

    for (final pose in poses) {
      double score = _scorePoseMatch(pose);
      if (score < bestScore) {
        bestScore = score;
        bestMatch = pose;
      }
    }

    if (bestMatch != null) {
      _currentPose = bestMatch;
      _recentPoses.add(bestMatch);
      
      // Keep only recent poses
      if (_recentPoses.length > 10) {
        _recentPoses.removeAt(0);
      }
      
      // Baseline is now set explicitly when red light starts
      // (removed automatic baseline setting to prevent drift)
    }
  }

  /// Score how well a face matches this player's expected position
  double _scoreFaceMatch(Face face) {
    if (_recentFaces.isEmpty) {
      // For initial detection, prefer faces in reasonable positions
      final center = face.boundingBox.center;
      return math.sqrt(math.pow(center.dx - 640, 2) + math.pow(center.dy - 360, 2)); // Distance from center
    }

    // Score based on continuity with recent faces
    final recentFace = _recentFaces.last;
    final currentCenter = face.boundingBox.center;
    final recentCenter = recentFace.boundingBox.center;
    
    final distance = math.sqrt(
      math.pow(currentCenter.dx - recentCenter.dx, 2) + 
      math.pow(currentCenter.dy - recentCenter.dy, 2)
    );
    
    // Also consider face size consistency
    final sizeRatio = face.boundingBox.width / recentFace.boundingBox.width;
    final sizePenalty = math.max(sizeRatio, 1.0 / sizeRatio) - 1.0;
    
    return distance + (sizePenalty * 100);
  }

  /// Score how well a pose matches this player's expected position
  double _scorePoseMatch(Pose pose) {
    if (_recentPoses.isEmpty) {
      // For initial detection, use pose confidence and completeness
      final validLandmarks = pose.landmarks.values.where((l) => l.likelihood > 0.5).length;
      return 1.0 / (validLandmarks + 1); // Prefer poses with more valid landmarks
    }

    final recentPose = _recentPoses.last;
    double totalDistance = 0.0;
    int comparisons = 0;

    // Compare key landmarks
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];

    for (final landmarkType in keyLandmarks) {
      final current = pose.landmarks[landmarkType];
      final recent = recentPose.landmarks[landmarkType];
      
      if (current != null && recent != null && current.likelihood > 0.5 && recent.likelihood > 0.5) {
        final distance = math.sqrt(
          math.pow(current.x - recent.x, 2) + 
          math.pow(current.y - recent.y, 2)
        );
        totalDistance += distance;
        comparisons++;
      }
    }

    return comparisons > 0 ? totalDistance / comparisons : double.infinity;
  }

  /// Update position estimate based on face and pose data
  void _updatePositionEstimate() {
    double x = 0.0;
    double y = 0.0;
    double confidence = 0.0;
    int sources = 0;

    // Use face position if available
    if (_currentFace != null) {
      final faceCenter = _currentFace!.boundingBox.center;
      x += faceCenter.dx;
      y += faceCenter.dy;
      confidence += 0.8; // Face detection is quite reliable
      sources++;
    }

    // Use pose position if available
    if (_currentPose != null) {
      final nose = _currentPose!.landmarks[PoseLandmarkType.nose];
      if (nose != null && nose.likelihood > 0.5) {
        x += nose.x;
        y += nose.y;
        confidence += 0.6; // Pose detection is somewhat reliable
        sources++;
      }
    }

    if (sources > 0) {
      _averageX = x / sources;
      _averageY = y / sources;
      _confidenceScore = confidence / sources;
      print('📊 $playerName: Position updated - sources: $sources, confidence: ${_confidenceScore.toStringAsFixed(2)}');
    } else {
      _confidenceScore = 0.0;
      print('📊 $playerName: No valid position sources');
    }
  }

  /// Update stability tracking
  void _updateStability() {
    // Check if player detection is stable
    bool hasValidDetection = (_currentFace != null) || 
                           (_currentPose != null && _getPoseValidLandmarks(_currentPose!) >= 1); // Reduced from 3 to 1

    if (hasValidDetection) { // Simplified: just check for valid detection, ignore confidence for now
      _stableFrames++;
      print('🔄 $playerName: Stability +1 → ${_stableFrames}/${_requiredStableFrames} (confidence: ${_confidenceScore.toStringAsFixed(2)})');
    } else {
      // Be more lenient - only decrease stability slowly to handle temporary detection drops
      final oldFrames = _stableFrames;
      _stableFrames = math.max(0, _stableFrames - 1);
      if (oldFrames != _stableFrames) {
        print('🔄 $playerName: Stability -1 → ${_stableFrames}/${_requiredStableFrames} (hasValid: $hasValidDetection, confidence: ${_confidenceScore.toStringAsFixed(2)})');
      }
    }

    final wasStable = _isStable;
    _isStable = _stableFrames >= _requiredStableFrames;
    
    if (_isStable && !wasStable) {
      print('✅ $playerName: NOW STABLE! (${_stableFrames}/${_requiredStableFrames} frames)');
    } else if (!_isStable && wasStable) {
      print('❌ $playerName: LOST STABILITY (${_stableFrames}/${_requiredStableFrames} frames)');
    }
    
    // Debug: Log current state each time
    print('🔍 $playerName: Stability state check - _isStable: $_isStable, frames: ${_stableFrames}/${_requiredStableFrames}');
  }

  /// Check for movement compared to baseline using distance-adaptive detection
  bool checkForMovement() {
    print('🔍 $playerName: Movement check - stable:$_isStable, baseline:${_baselinePose != null}, current:${_currentPose != null}');
    if (!_isStable || _baselinePose == null || _currentPose == null) {
      print('⚠️ $playerName: Movement check skipped - stable:$_isStable, baseline:${_baselinePose != null}, current:${_currentPose != null}');
      return false;
    }

    // Simple movement detection: check key landmarks for significant pixel movement
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    ];

    double maxMovement = 0.0;
    String movingLandmark = '';
    int validComparisons = 0;

    for (final landmarkType in keyLandmarks) {
      final current = _currentPose!.landmarks[landmarkType];
      final baseline = _baselinePose!.landmarks[landmarkType];

      if (current != null && baseline != null && 
          current.likelihood > 0.5 && baseline.likelihood > 0.5) {
        
        final pixelDistance = math.sqrt(
          math.pow(current.x - baseline.x, 2) + 
          math.pow(current.y - baseline.y, 2)
        );

        if (pixelDistance > maxMovement) {
          maxMovement = pixelDistance;
          movingLandmark = landmarkType.toString().split('.').last;
        }
        validComparisons++;
      }
    }

    // Simple threshold: 80 pixels movement
    const movementThreshold = 80.0;
    final hasMovement = maxMovement > movementThreshold;

    print('🔍 $playerName: Simple movement check - max: ${maxMovement.toStringAsFixed(1)}px (${movingLandmark}), threshold: ${movementThreshold}px, valid: $validComparisons');

    if (hasMovement) {
      _movementFrames++;
      print('⚡ $playerName: Movement detected (frame ${_movementFrames}/3) - ${maxMovement.toStringAsFixed(1)}px at $movingLandmark');
    } else {
      if (_movementFrames > 0) {
        print('✅ $playerName: Movement stopped - resetting counter (was ${_movementFrames})');
      }
      _movementFrames = 0;
    }

    // Require movement for 3 frames to reduce false positives
    final wasMoving = _isMoving;
    _isMoving = _movementFrames >= 3;

    if (_isMoving && !wasMoving) {
      print('🚨 $playerName: FINAL MOVEMENT DETECTED - ${maxMovement.toStringAsFixed(1)}px at $movingLandmark');
    }

    return _isMoving;
  }

  /// Set baseline pose explicitly (called when red light starts)
  void setBaseline(Pose pose) {
    _baselinePose = pose;
    _baselineFace = _currentFace; // Capture current face as baseline too
    _movementFrames = 0;
    _isMoving = false;
    print('📍 Baseline set for $playerName with ${_getPoseValidLandmarks(pose)} valid landmarks');
  }

  /// Reset baseline pose (called when green light starts)
  void resetBaseline() {
    _baselinePose = null;
    _baselineFace = null;
    _movementFrames = 0;
    _isMoving = false;
    print('🔄 Baseline reset for $playerName');
  }

  /// Get number of valid landmarks in a pose
  int _getPoseValidLandmarks(Pose pose) {
    return pose.landmarks.values.where((l) => l.likelihood > 0.5).length;
  }

  // Getters
  bool get isDetected => (_currentFace != null) || (_currentPose != null);
  bool get isStable => _isStable;
  bool get isMoving => _isMoving;
  double get confidence => _confidenceScore;
  double get positionX => _averageX;
  double get positionY => _averageY;
  double get estimatedDistance => _estimatedDistance;
  Face? get currentFace => _currentFace;
  Pose? get currentPose => _currentPose;
  Pose? get baselinePose => _baselinePose;
  
  /// Force assignment of specific detections (for spatial conflict resolution)
  void forceAssignment({Face? face, Pose? pose}) {
    _currentFace = face;
    _currentPose = pose;
    
    // Add to recent history for proper tracking
    if (face != null) {
      _recentFaces.add(face);
      if (_recentFaces.length > 5) _recentFaces.removeAt(0);
    }
    if (pose != null) {
      _recentPoses.add(pose);
      if (_recentPoses.length > 5) _recentPoses.removeAt(0);
    }
    
    // When we have a reliable spatial assignment, boost stability
    if (face != null || pose != null) {
      _stableFrames = math.max(_stableFrames, 4); // Jump to 4/6 frames when spatially assigned
    }
    
    _updatePositionEstimate();
    _updateStability();
  }

  /// Clear all current detections
  void clearDetection() {
    _currentFace = null;
    _currentPose = null;
    _confidenceScore = 0.0;
    // Don't reset stability immediately to avoid flicker
    _stableFrames = math.max(0, _stableFrames - 2);
  }

  @override
  String toString() {
    return 'PlayerTracker($playerName: detected=${isDetected}, stable=${isStable}, moving=${isMoving}, confidence=${confidence.toStringAsFixed(2)})';
  }
}
