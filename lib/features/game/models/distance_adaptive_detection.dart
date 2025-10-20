import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Distance-adaptive detection for Red Light Green Light
/// Adapts movement thresholds based on player distance from camera
class DistanceAdaptiveDetection {
  
  /// Estimate player distance from camera based on pose/face size
  static double estimatePlayerDistance({Face? face, Pose? pose}) {
    if (face != null) {
      return _estimateDistanceFromFace(face);
    } else if (pose != null) {
      return _estimateDistanceFromPose(pose);
    }
    return 1.0; // Default distance if no data
  }

  /// Estimate distance based on face bounding box size
  static double _estimateDistanceFromFace(Face face) {
    // Larger face = closer to camera, smaller face = farther away
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final faceArea = faceWidth * faceHeight;
    
    // Normalize based on expected face size at different distances
    // Close: ~200x200px, Medium: ~100x100px, Far: ~50x50px
    const double closeDistance = 40000.0; // 200x200
    const double mediumDistance = 10000.0; // 100x100
    const double farDistance = 2500.0; // 50x50
    
    if (faceArea >= closeDistance) return 0.3; // Very close
    if (faceArea >= mediumDistance) return 0.6; // Medium distance
    if (faceArea >= farDistance) return 1.0; // Normal distance
    return 1.5; // Far distance
  }

  /// Estimate distance based on pose landmark spread
  static double _estimateDistanceFromPose(Pose pose) {
    // Calculate the spread of the pose (shoulder width, body height)
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    
    double shoulderWidth = 0;
    double bodyHeight = 0;
    
    // Calculate shoulder width
    if (leftShoulder != null && rightShoulder != null && 
        leftShoulder.likelihood > 0.5 && rightShoulder.likelihood > 0.5) {
      shoulderWidth = math.sqrt(
        math.pow(leftShoulder.x - rightShoulder.x, 2) + 
        math.pow(leftShoulder.y - rightShoulder.y, 2)
      );
    }
    
    // Calculate body height (nose to hip)
    if (nose != null && leftHip != null && 
        nose.likelihood > 0.5 && leftHip.likelihood > 0.5) {
      bodyHeight = math.sqrt(
        math.pow(nose.x - leftHip.x, 2) + 
        math.pow(nose.y - leftHip.y, 2)
      );
    }
    
    // Use the larger measurement for distance estimation
    final bodySize = math.max(shoulderWidth, bodyHeight);
    
    // Normalize based on expected body size at different distances
    // Close: ~300px, Medium: ~150px, Far: ~75px
    if (bodySize >= 250) return 0.3; // Very close
    if (bodySize >= 120) return 0.6; // Medium distance  
    if (bodySize >= 60) return 1.0; // Normal distance
    return 1.5; // Far distance
  }

  /// Get distance-adaptive movement threshold
  static double getAdaptiveMovementThreshold({
    required double baseThreshold,
    required double playerDistance,
    required PoseLandmarkType landmarkType,
  }) {
    // Base multipliers for different body parts
    double bodyPartMultiplier = _getBodyPartMultiplier(landmarkType);
    
    // Distance adaptation: closer = higher threshold, farther = lower threshold
    double distanceMultiplier = _getDistanceMultiplier(playerDistance);
    
    // Additional scaling based on landmark confidence degradation at distance
    double confidenceMultiplier = _getConfidenceMultiplier(playerDistance, landmarkType);
    
    final adaptiveThreshold = baseThreshold * bodyPartMultiplier * distanceMultiplier * confidenceMultiplier;
    
    return math.max(adaptiveThreshold, 5.0); // Minimum 5 pixels to avoid noise
  }

  /// Get body part specific multipliers
  static double _getBodyPartMultiplier(PoseLandmarkType landmarkType) {
    switch (landmarkType) {
      case PoseLandmarkType.nose:
        return 0.8; // Head movements should be small
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
        return 1.0; // Shoulders are good reference points
      case PoseLandmarkType.leftElbow:
      case PoseLandmarkType.rightElbow:
        return 1.5; // Elbows can move more
      case PoseLandmarkType.leftWrist:
      case PoseLandmarkType.rightWrist:
        return 2.0; // Wrists are most mobile
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return 0.9; // Hips should be stable
      default:
        return 1.0;
    }
  }

  /// Get distance-based multipliers (OPTIMIZED FOR RED LIGHT GREEN LIGHT)
  static double _getDistanceMultiplier(double playerDistance) {
    // RED LIGHT GREEN LIGHT STRATEGY:
    // Farther players = MUCH lower thresholds (catch sneaky forward movement)
    // Closer players = slightly higher thresholds (allow natural micro-movements)
    
    if (playerDistance <= 0.4) return 1.2; // Very close: slightly forgiving
    if (playerDistance <= 0.7) return 1.0; // Close: standard threshold  
    if (playerDistance <= 1.2) return 0.5; // Far: much more sensitive
    return 0.3; // Very far: extremely sensitive to catch sneaking
  }

  /// Get confidence-based multipliers for different distances (RED LIGHT GREEN LIGHT OPTIMIZED)
  static double _getConfidenceMultiplier(double playerDistance, PoseLandmarkType landmarkType) {
    // RED LIGHT GREEN LIGHT STRATEGY:
    // Accept some pose jitter at far distances but still catch real movement
    // Balance between reliability and game fairness
    
    if (playerDistance >= 1.3) {
      // Very far - allow some jitter but still detect intentional movement
      return 1.3; // Reduced from 2.0 to be stricter
    } else if (playerDistance >= 1.0) {
      // Far - minimal jitter allowance
      return 1.1; // Reduced from 1.5 to be stricter
    } else {
      // Close/medium - pose detection is reliable, use standard sensitivity
      return 1.0;
    }
  }

  /// Calculate relative movement (percentage of body size)
  static double calculateRelativeMovement({
    required double pixelMovement,
    required double playerDistance,
    Face? face,
    Pose? pose,
  }) {
    // Get a reference body size for this player
    double referenceSize = _getReferenceBodySize(face: face, pose: pose);
    
    if (referenceSize <= 0) return 0.0;
    
    // Calculate movement as percentage of body size
    return (pixelMovement / referenceSize) * 100;
  }

  /// Get reference body size for movement normalization
  static double _getReferenceBodySize({Face? face, Pose? pose}) {
    if (face != null) {
      return math.max(face.boundingBox.width, face.boundingBox.height);
    }
    
    if (pose != null) {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      
      if (leftShoulder != null && rightShoulder != null && 
          leftShoulder.likelihood > 0.5 && rightShoulder.likelihood > 0.5) {
        return math.sqrt(
          math.pow(leftShoulder.x - rightShoulder.x, 2) + 
          math.pow(leftShoulder.y - rightShoulder.y, 2)
        );
      }
    }
    
    return 100.0; // Default reference size
  }

  /// Enhanced movement detection with multiple validation methods
  static MovementDetectionResult detectMovementEnhanced({
    required Pose currentPose,
    required Pose baselinePose,
    required String playerName,
    Face? currentFace,
    Face? baselineFace,
  }) {
    // Estimate player distance
    final currentDistance = estimatePlayerDistance(face: currentFace, pose: currentPose);
    final baselineDistance = estimatePlayerDistance(face: baselineFace, pose: baselinePose);
    final avgDistance = (currentDistance + baselineDistance) / 2;
    
    // Method 1: Adaptive pixel-based detection
    final pixelResult = _detectPixelMovement(currentPose, baselinePose, avgDistance, playerName);
    
    // Method 2: Relative movement detection
    final relativeResult = _detectRelativeMovement(
      currentPose, baselinePose, currentFace, baselineFace, avgDistance, playerName
    );
    
    // Method 3: Confidence-weighted detection
    final confidenceResult = _detectConfidenceWeightedMovement(
      currentPose, baselinePose, avgDistance, playerName
    );
    
    // Method 4: Depth movement detection (NEW!)
    final depthResult = _detectDepthMovement(
      currentPose, baselinePose, currentFace, baselineFace, currentDistance, baselineDistance, playerName
    );
    
    // Combine results using majority voting with confidence weighting
    return _combineDetectionResults([pixelResult, relativeResult, confidenceResult, depthResult], playerName);
  }

  /// Pixel-based movement detection with adaptive thresholds
  static MovementDetectionResult _detectPixelMovement(
    Pose currentPose, Pose baselinePose, double distance, String playerName
  ) {
    double totalMovement = 0.0;
    int comparisons = 0;
    final violatingLandmarks = <String>[];
    
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    ];
    
    for (final landmarkType in keyLandmarks) {
      final current = currentPose.landmarks[landmarkType];
      final baseline = baselinePose.landmarks[landmarkType];
      
      if (current != null && baseline != null && 
          current.likelihood > 0.5 && baseline.likelihood > 0.5) {
        
        final pixelDistance = math.sqrt(
          math.pow(current.x - baseline.x, 2) + 
          math.pow(current.y - baseline.y, 2)
        );
        
        final adaptiveThreshold = getAdaptiveMovementThreshold(
          baseThreshold: 80.0, // Base threshold
          playerDistance: distance,
          landmarkType: landmarkType,
        );
        
        totalMovement += pixelDistance;
        comparisons++;
        
        if (pixelDistance > adaptiveThreshold) {
          violatingLandmarks.add('${landmarkType.toString().split('.').last}: ${pixelDistance.toStringAsFixed(1)}px > ${adaptiveThreshold.toStringAsFixed(1)}px');
        }
      }
    }
    
    final avgMovement = comparisons > 0 ? totalMovement / comparisons : 0.0;
    final hasMovement = violatingLandmarks.isNotEmpty;
    
    return MovementDetectionResult(
      hasMovement: hasMovement,
      confidence: comparisons > 0 ? math.min(avgMovement / 100.0, 1.0) : 0.0,
      details: violatingLandmarks,
      method: 'PixelAdaptive',
    );
  }

  /// Relative movement detection (percentage of body size)
  static MovementDetectionResult _detectRelativeMovement(
    Pose currentPose, Pose baselinePose, Face? currentFace, Face? baselineFace, 
    double distance, String playerName
  ) {
    final currentBodySize = _getReferenceBodySize(face: currentFace, pose: currentPose);
    final baselineBodySize = _getReferenceBodySize(face: baselineFace, pose: baselinePose);
    final avgBodySize = (currentBodySize + baselineBodySize) / 2;
    
    if (avgBodySize <= 0) {
      return MovementDetectionResult(hasMovement: false, confidence: 0.0, details: [], method: 'Relative');
    }
    
    double totalRelativeMovement = 0.0;
    int comparisons = 0;
    final violatingLandmarks = <String>[];
    
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    ];
    
    for (final landmarkType in keyLandmarks) {
      final current = currentPose.landmarks[landmarkType];
      final baseline = baselinePose.landmarks[landmarkType];
      
      if (current != null && baseline != null && 
          current.likelihood > 0.5 && baseline.likelihood > 0.5) {
        
        final pixelDistance = math.sqrt(
          math.pow(current.x - baseline.x, 2) + 
          math.pow(current.y - baseline.y, 2)
        );
        
        final relativeMovement = (pixelDistance / avgBodySize) * 100;
        totalRelativeMovement += relativeMovement;
        comparisons++;
        
        // Relative movement threshold: 15% of body size is significant movement
        const double relativeThreshold = 15.0;
        
        if (relativeMovement > relativeThreshold) {
          violatingLandmarks.add('${landmarkType.toString().split('.').last}: ${relativeMovement.toStringAsFixed(1)}% > ${relativeThreshold}%');
        }
      }
    }
    
    final avgRelativeMovement = comparisons > 0 ? totalRelativeMovement / comparisons : 0.0;
    final hasMovement = violatingLandmarks.isNotEmpty;
    
    return MovementDetectionResult(
      hasMovement: hasMovement,
      confidence: math.min(avgRelativeMovement / 50.0, 1.0),
      details: violatingLandmarks,
      method: 'Relative',
    );
  }

  /// Confidence-weighted movement detection
  static MovementDetectionResult _detectConfidenceWeightedMovement(
    Pose currentPose, Pose baselinePose, double distance, String playerName
  ) {
    double weightedMovement = 0.0;
    double totalWeight = 0.0;
    final violatingLandmarks = <String>[];
    
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    ];
    
    for (final landmarkType in keyLandmarks) {
      final current = currentPose.landmarks[landmarkType];
      final baseline = baselinePose.landmarks[landmarkType];
      
      if (current != null && baseline != null && 
          current.likelihood > 0.3 && baseline.likelihood > 0.3) { // Lower confidence threshold
        
        final pixelDistance = math.sqrt(
          math.pow(current.x - baseline.x, 2) + 
          math.pow(current.y - baseline.y, 2)
        );
        
        // Weight by confidence
        final weight = (current.likelihood + baseline.likelihood) / 2;
        weightedMovement += pixelDistance * weight;
        totalWeight += weight;
        
        // Dynamic threshold based on confidence
        final confidenceBasedThreshold = getAdaptiveMovementThreshold(
          baseThreshold: 70.0 / weight, // Lower confidence = higher threshold
          playerDistance: distance,
          landmarkType: landmarkType,
        );
        
        if (pixelDistance > confidenceBasedThreshold) {
          violatingLandmarks.add('${landmarkType.toString().split('.').last}: ${pixelDistance.toStringAsFixed(1)}px (conf: ${weight.toStringAsFixed(2)})');
        }
      }
    }
    
    final avgWeightedMovement = totalWeight > 0 ? weightedMovement / totalWeight : 0.0;
    final hasMovement = violatingLandmarks.isNotEmpty;
    
    return MovementDetectionResult(
      hasMovement: hasMovement,
      confidence: totalWeight > 0 ? math.min(avgWeightedMovement / 100.0, 1.0) : 0.0,
      details: violatingLandmarks,
      method: 'ConfidenceWeighted',
    );
  }

  /// Depth movement detection - detects movement toward/away from camera
  static MovementDetectionResult _detectDepthMovement(
    Pose currentPose, Pose baselinePose, Face? currentFace, Face? baselineFace,
    double currentDistance, double baselineDistance, String playerName
  ) {
    final depthChange = (currentDistance - baselineDistance).abs();
    final violatingDetails = <String>[];
    
    // Calculate scale changes using multiple methods
    double faceScaleChange = 0.0;
    double poseScaleChange = 0.0;
    int validMethods = 0;
    
    // Method 1: Face size change detection
    if (currentFace != null && baselineFace != null) {
      final currentFaceArea = currentFace.boundingBox.width * currentFace.boundingBox.height;
      final baselineFaceArea = baselineFace.boundingBox.width * baselineFace.boundingBox.height;
      
      if (baselineFaceArea > 0) {
        faceScaleChange = (currentFaceArea - baselineFaceArea).abs() / baselineFaceArea;
        validMethods++;
        
        // Distance-adaptive face scale thresholds
        final faceThreshold = _getDistanceAdaptiveFaceThreshold(currentDistance, baselineDistance);
        if (faceScaleChange > faceThreshold) {
          final direction = currentFaceArea > baselineFaceArea ? 'closer' : 'farther';
          violatingDetails.add('Face scale change: ${(faceScaleChange * 100).toStringAsFixed(1)}% ($direction, thresh: ${(faceThreshold * 100).toStringAsFixed(1)}%)');
        }
      }
    }
    
    // Method 2: Pose scale change detection (shoulder width + body height)
    final currentBodySize = _getPoseBodySize(currentPose);
    final baselineBodySize = _getPoseBodySize(baselinePose);
    
    if (baselineBodySize > 0 && currentBodySize > 0) {
      poseScaleChange = (currentBodySize - baselineBodySize).abs() / baselineBodySize;
      validMethods++;
      
      // Distance-adaptive pose scale thresholds  
      final poseThreshold = _getDistanceAdaptivePoseThreshold(currentDistance, baselineDistance);
      if (poseScaleChange > poseThreshold) {
        final direction = currentBodySize > baselineBodySize ? 'closer' : 'farther';
        violatingDetails.add('Pose scale change: ${(poseScaleChange * 100).toStringAsFixed(1)}% ($direction, thresh: ${(poseThreshold * 100).toStringAsFixed(1)}%)');
      }
    }
    
    // Method 3: Distance estimation change - VERY sensitive at far distances
    final distanceThreshold = _getDistanceAdaptiveDistanceThreshold(currentDistance, baselineDistance);
    if (depthChange > distanceThreshold) {
      final direction = currentDistance < baselineDistance ? 'closer' : 'farther';
      violatingDetails.add('Distance change: ${depthChange.toStringAsFixed(2)} units ($direction, thresh: ${distanceThreshold.toStringAsFixed(2)})');
      validMethods++;
    }
    
    // Determine if there's significant depth movement
    final avgScaleChange = validMethods > 0 ? 
        (faceScaleChange + poseScaleChange + (depthChange * 0.5)) / validMethods : 0.0;
    
    // Movement thresholds - ULTRA sensitive to forward movement at far distances
    final avgDistance = (currentDistance + baselineDistance) / 2;
    final closerThreshold = _getCloserMovementThreshold(avgDistance);
    final fartherThreshold = _getFartherMovementThreshold(avgDistance);
    
    final isMovingCloser = (currentDistance < baselineDistance) && (depthChange > closerThreshold);
    final isMovingFarther = (currentDistance > baselineDistance) && (depthChange > fartherThreshold);
    final hasDepthMovement = isMovingCloser || isMovingFarther || violatingDetails.isNotEmpty;
    
    // Log depth movement for debugging
    if (hasDepthMovement || depthChange > 0.1) {
      print('🔍 Depth Detection ($playerName): Current: ${currentDistance.toStringAsFixed(2)}, Baseline: ${baselineDistance.toStringAsFixed(2)}, Change: ${depthChange.toStringAsFixed(2)}');
      if (violatingDetails.isNotEmpty) {
        print('   Violations: ${violatingDetails.join(', ')}');
      }
    }
    
    return MovementDetectionResult(
      hasMovement: hasDepthMovement,
      confidence: math.min(avgScaleChange * 2.0, 1.0), // Scale up confidence for depth detection
      details: violatingDetails,
      method: 'DepthMovement',
    );
  }

  /// Get pose body size for scale comparison
  static double _getPoseBodySize(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    
    double shoulderWidth = 0;
    double bodyHeight = 0;
    
    // Calculate shoulder width
    if (leftShoulder != null && rightShoulder != null && 
        leftShoulder.likelihood > 0.5 && rightShoulder.likelihood > 0.5) {
      shoulderWidth = math.sqrt(
        math.pow(leftShoulder.x - rightShoulder.x, 2) + 
        math.pow(leftShoulder.y - rightShoulder.y, 2)
      );
    }
    
    // Calculate body height (nose to hip)
    if (nose != null && leftHip != null && 
        nose.likelihood > 0.5 && leftHip.likelihood > 0.5) {
      bodyHeight = math.sqrt(
        math.pow(nose.x - leftHip.x, 2) + 
        math.pow(nose.y - leftHip.y, 2)
      );
    }
    
    // Return combined body size measurement
    return shoulderWidth + bodyHeight;
  }

  /// Get distance-adaptive face scale threshold (stricter at far distances)
  static double _getDistanceAdaptiveFaceThreshold(double currentDistance, double baselineDistance) {
    final avgDistance = (currentDistance + baselineDistance) / 2;
    
    // RED LIGHT GREEN LIGHT: Be extremely strict at far distances where sneaking happens
    if (avgDistance >= 1.3) return 0.08; // Very far: 8% face change (extremely sensitive)
    if (avgDistance >= 1.0) return 0.12; // Far: 12% face change (very sensitive)
    if (avgDistance >= 0.7) return 0.18; // Medium: 18% face change (moderately sensitive)
    return 0.25; // Close: 25% face change (standard)
  }

  /// Get distance-adaptive pose scale threshold (stricter at far distances)
  static double _getDistanceAdaptivePoseThreshold(double currentDistance, double baselineDistance) {
    final avgDistance = (currentDistance + baselineDistance) / 2;
    
    // RED LIGHT GREEN LIGHT: Catch subtle forward movement at far distances
    if (avgDistance >= 1.3) return 0.06; // Very far: 6% pose change (extremely sensitive)
    if (avgDistance >= 1.0) return 0.10; // Far: 10% pose change (very sensitive)
    if (avgDistance >= 0.7) return 0.15; // Medium: 15% pose change (moderately sensitive)
    return 0.20; // Close: 20% pose change (standard)
  }

  /// Get distance-adaptive distance threshold (stricter at far distances)
  static double _getDistanceAdaptiveDistanceThreshold(double currentDistance, double baselineDistance) {
    final avgDistance = (currentDistance + baselineDistance) / 2;
    
    // RED LIGHT GREEN LIGHT: Detect even tiny forward steps at far distances
    if (avgDistance >= 1.3) return 0.08; // Very far: 0.08 units (ultra sensitive)
    if (avgDistance >= 1.0) return 0.12; // Far: 0.12 units (very sensitive)  
    if (avgDistance >= 0.7) return 0.20; // Medium: 0.20 units (moderately sensitive)
    return 0.30; // Close: 0.30 units (standard)
  }

  /// Get movement threshold for closer movement (ultra sensitive at far distances)
  static double _getCloserMovementThreshold(double avgDistance) {
    // RED LIGHT GREEN LIGHT: Catch any sneaky forward movement, especially far away
    if (avgDistance >= 1.3) return 0.05; // Very far: detect tiny steps (ultra sensitive)
    if (avgDistance >= 1.0) return 0.08; // Far: very sensitive to forward movement
    if (avgDistance >= 0.7) return 0.12; // Medium: moderately sensitive
    return 0.15; // Close: standard sensitivity
  }

  /// Get movement threshold for farther movement (less sensitive to backing away)
  static double _getFartherMovementThreshold(double avgDistance) {
    // Less concerned about backing away, but still detect it
    if (avgDistance >= 1.3) return 0.15; // Very far: some sensitivity to backing away
    if (avgDistance >= 1.0) return 0.20; // Far: moderate sensitivity
    if (avgDistance >= 0.7) return 0.25; // Medium: less sensitive
    return 0.30; // Close: standard sensitivity
  }

  /// Combine multiple detection results using weighted voting
  static MovementDetectionResult _combineDetectionResults(
    List<MovementDetectionResult> results, String playerName
  ) {
    if (results.isEmpty) {
      return MovementDetectionResult(hasMovement: false, confidence: 0.0, details: [], method: 'Combined');
    }
    
    // Count votes and weight by confidence
    double totalConfidence = 0.0;
    int movementVotes = 0;
    final allDetails = <String>[];
    
    for (final result in results) {
      totalConfidence += result.confidence;
      if (result.hasMovement) {
        movementVotes++;
      }
      allDetails.addAll(result.details.map((d) => '[${result.method}] $d'));
    }
    
    final avgConfidence = totalConfidence / results.length;
    
    // Require majority vote OR high confidence detection
    // With 4 methods: need 2+ votes OR 1 vote with very high confidence
    final hasMovement = (movementVotes >= 2) || (movementVotes >= 1 && avgConfidence > 0.8);
    
    return MovementDetectionResult(
      hasMovement: hasMovement,
      confidence: avgConfidence,
      details: allDetails,
      method: 'Combined(${movementVotes}/${results.length})',
    );
  }
}

/// Result of movement detection
class MovementDetectionResult {
  final bool hasMovement;
  final double confidence;
  final List<String> details;
  final String method;
  
  const MovementDetectionResult({
    required this.hasMovement,
    required this.confidence,
    required this.details,
    required this.method,
  });
}
