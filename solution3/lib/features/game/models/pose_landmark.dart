import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

/// Represents a pose landmark with position and confidence
class PoseLandmarkData {
  final PoseLandmarkType type;
  final double x;
  final double y;
  final double z;
  final double likelihood;

  const PoseLandmarkData({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });

  /// Create from Google ML Kit PoseLandmark
  factory PoseLandmarkData.fromPoseLandmark(PoseLandmark landmark) {
    return PoseLandmarkData(
      type: landmark.type,
      x: landmark.x,
      y: landmark.y,
      z: landmark.z,
      likelihood: landmark.likelihood,
    );
  }

  /// Calculate distance between two landmarks
  double distanceTo(PoseLandmarkData other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Check if landmark is valid (has sufficient confidence)
  bool get isValid => likelihood > 0.5;

  @override
  String toString() {
    return 'PoseLandmarkData(type: $type, x: $x, y: $y, z: $z, likelihood: $likelihood)';
  }
}

/// Represents a complete pose with all landmarks
class PoseData {
  final List<PoseLandmarkData> landmarks;
  final DateTime timestamp;

  const PoseData({required this.landmarks, required this.timestamp});

  /// Create from Google ML Kit Pose
  factory PoseData.fromPose(Pose pose, {String? playerId}) {
    final landmarks = pose.landmarks.values
        .map((landmark) => PoseLandmarkData.fromPoseLandmark(landmark))
        .toList();

    return PoseData(landmarks: landmarks, timestamp: DateTime.now());
  }

  /// Get landmark by type
  PoseLandmarkData? getLandmarkByType(PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((landmark) => landmark.type == type);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'PoseData(landmarks: ${landmarks.length}, timestamp: $timestamp, playerId: ';
  }
}
