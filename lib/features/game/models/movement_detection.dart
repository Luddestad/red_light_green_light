import 'pose_landmark.dart';
import '../../../core/constants/detection_constants.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Represents movement detection result
class MovementDetectionResult {
  final bool hasMovement;
  final List<String> movingPlayerIds;
  final List<MovementDetail> movementDetails;
  final DateTime timestamp;
  final double confidence;

  const MovementDetectionResult({
    required this.hasMovement,
    required this.movingPlayerIds,
    required this.movementDetails,
    required this.timestamp,
    required this.confidence,
  });

  @override
  String toString() {
    return 'MovementDetectionResult(hasMovement: $hasMovement, movingPlayers: $movingPlayerIds, confidence: $confidence)';
  }
}

/// Detailed information about detected movement
class MovementDetail {
  final String playerId;
  final PoseLandmarkType landmarkType;
  final double movementDistance;
  final double threshold;
  final double confidence;

  const MovementDetail({
    required this.playerId,
    required this.landmarkType,
    required this.movementDistance,
    required this.threshold,
    required this.confidence,
  });

  /// Check if movement exceeds threshold
  bool get exceedsThreshold => movementDistance > threshold;

  @override
  String toString() {
    return 'MovementDetail(player: $playerId, landmark: $landmarkType, distance: $movementDistance, threshold: $threshold)';
  }
}

/// Movement detection algorithm implementation
class MovementDetector {
  /// Detect movement between current and reference poses
  static MovementDetectionResult detectMovement({
    required List<PoseData> currentPoses,
    required List<PoseData> referencePoses,
    required Map<String, String> poseToPlayerMap, // Maps pose index to player ID
  }) {
    final movingPlayerIds = <String>[];
    final movementDetails = <MovementDetail>[];
    double totalConfidence = 0.0;
    int validComparisons = 0;

    // For each current pose, find corresponding reference pose and check for movement
    for (int i = 0; i < currentPoses.length; i++) {
      final currentPose = currentPoses[i];
      final playerId = poseToPlayerMap[i.toString()] ?? 'unknown_$i';
      
      // Find closest reference pose
      final closestReference = _findClosestPose(currentPose, referencePoses);
      
      if (closestReference != null) {
        final movementResult = _analyzePoseMovement(currentPose, closestReference, playerId);
        
        if (movementResult.hasMovement) {
          movingPlayerIds.add(playerId);
          movementDetails.addAll(movementResult.movementDetails);
        }
        
        totalConfidence += movementResult.confidence;
        validComparisons++;
      }
    }

    final averageConfidence = validComparisons > 0 ? totalConfidence / validComparisons : 0.0;
    final hasMovement = movingPlayerIds.isNotEmpty;

    return MovementDetectionResult(
      hasMovement: hasMovement,
      movingPlayerIds: movingPlayerIds,
      movementDetails: movementDetails,
      timestamp: DateTime.now(),
      confidence: averageConfidence,
    );
  }

  /// Find the closest reference pose to a current pose
  static PoseData? _findClosestPose(PoseData currentPose, List<PoseData> referencePoses) {
    if (referencePoses.isEmpty) return null;

    PoseData? closest;
    double minDistance = double.infinity;

    for (final referencePose in referencePoses) {
      final distance = _calculatePoseDistance(currentPose, referencePose);
      if (distance < minDistance) {
        minDistance = distance;
        closest = referencePose;
      }
    }

    return closest;
  }

  /// Calculate distance between two poses
  static double _calculatePoseDistance(PoseData pose1, PoseData pose2) {
    double totalDistance = 0.0;
    int validLandmarks = 0;

    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      final landmark1 = pose1.getLandmarkByType(landmarkType);
      final landmark2 = pose2.getLandmarkByType(landmarkType);

      if (landmark1 != null && landmark2 != null && landmark1.isValid && landmark2.isValid) {
        totalDistance += landmark1.distanceTo(landmark2);
        validLandmarks++;
      }
    }

    return validLandmarks > 0 ? totalDistance / validLandmarks : double.infinity;
  }

  /// Analyze movement between two poses
  static _MovementAnalysisResult _analyzePoseMovement(
    PoseData currentPose, 
    PoseData referencePose, 
    String playerId
  ) {
    final movementDetails = <MovementDetail>[];
    bool hasMovement = false;
    double totalConfidence = 0.0;
    int validLandmarks = 0;

    // Check individual landmark movement
    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      final currentLandmark = currentPose.getLandmarkByType(landmarkType);
      final referenceLandmark = referencePose.getLandmarkByType(landmarkType);

      if (currentLandmark != null && referenceLandmark != null && 
          currentLandmark.isValid && referenceLandmark.isValid) {
        
        final distance = currentLandmark.distanceTo(referenceLandmark);
        final threshold = _getMovementThreshold(landmarkType);
        final confidence = (currentLandmark.likelihood + referenceLandmark.likelihood) / 2;

        final detail = MovementDetail(
          playerId: playerId,
          landmarkType: landmarkType,
          movementDistance: distance,
          threshold: threshold,
          confidence: confidence,
        );

        movementDetails.add(detail);

        if (detail.exceedsThreshold) {
          hasMovement = true;
        }

        totalConfidence += confidence;
        validLandmarks++;
      }
    }

    // Check forward movement (using hip landmarks)
    final forwardMovement = _checkForwardMovement(currentPose, referencePose, playerId);
    if (forwardMovement != null) {
      movementDetails.add(forwardMovement);
      if (forwardMovement.exceedsThreshold) {
        hasMovement = true;
      }
      totalConfidence += forwardMovement.confidence;
      validLandmarks++;
    }

    final averageConfidence = validLandmarks > 0 ? totalConfidence / validLandmarks : 0.0;

    return _MovementAnalysisResult(
      hasMovement: hasMovement,
      movementDetails: movementDetails,
      confidence: averageConfidence,
    );
  }

  /// Check for forward movement using hip landmarks
  static MovementDetail? _checkForwardMovement(
    PoseData currentPose, 
    PoseData referencePose, 
    String playerId
  ) {
    final currentHipCenter = _getHipCenter(currentPose);
    final referenceHipCenter = _getHipCenter(referencePose);

    if (currentHipCenter == null || referenceHipCenter == null) {
      return null;
    }

    final forwardDistance = (currentHipCenter.x - referenceHipCenter.x).abs();
    final confidence = (currentHipCenter.likelihood + referenceHipCenter.likelihood) / 2;

    return MovementDetail(
      playerId: playerId,
      landmarkType: PoseLandmarkType.leftHip, // Use hip as landmark type
      movementDistance: forwardDistance,
      threshold: DetectionConstants.forwardMovementThreshold,
      confidence: confidence,
    );
  }

  /// Calculate hip center point
  static PoseLandmarkData? _getHipCenter(PoseData pose) {
    final leftHip = pose.getLandmarkByType(PoseLandmarkType.leftHip);
    final rightHip = pose.getLandmarkByType(PoseLandmarkType.rightHip);

    if (leftHip == null || rightHip == null) return null;

    return PoseLandmarkData(
      type: PoseLandmarkType.leftHip,
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
    );
  }

  /// Get movement threshold for specific landmark type
  static double _getMovementThreshold(PoseLandmarkType landmarkType) {
    switch (landmarkType) {
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
        return DetectionConstants.shoulderMovementThreshold;
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return DetectionConstants.hipMovementThreshold;
      case PoseLandmarkType.nose:
        return DetectionConstants.noseMovementThreshold;
      default:
        return 0.1; // Default movement threshold
    }
  }
}

/// Internal result class for movement analysis
class _MovementAnalysisResult {
  final bool hasMovement;
  final List<MovementDetail> movementDetails;
  final double confidence;

  const _MovementAnalysisResult({
    required this.hasMovement,
    required this.movementDetails,
    required this.confidence,
  });
}
