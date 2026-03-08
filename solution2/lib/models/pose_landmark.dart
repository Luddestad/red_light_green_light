import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

/// Represents a single body landmark detected by ML Kit.
///
/// ML Kit's pose detection returns 33 landmarks (nose, shoulders, elbows,
/// wrists, hips, knees, ankles, etc.) Each landmark has:
/// - x, y: position in the image (pixels)
/// - z: relative depth estimate
/// - likelihood: confidence score from 0.0 to 1.0
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

  /// Check if landmark is valid (has sufficient confidence)
  bool get isValid => likelihood > 0.5;

  /// Calculate distance between two landmarks
  double distanceTo(PoseLandmarkData other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() {
    return 'PoseLandmarkData(type: $type, x: ${x.toStringAsFixed(1)}, '
        'y: ${y.toStringAsFixed(1)}, likelihood: ${likelihood.toStringAsFixed(2)})';
  }
}

/// Represents a complete pose with all landmarks from one frame.
class PoseData {
  final List<PoseLandmarkData> landmarks;
  final DateTime timestamp;

  const PoseData({required this.landmarks, required this.timestamp});

  /// Create from Google ML Kit Pose
  factory PoseData.fromPose(Pose pose) {
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
    return 'PoseData(landmarks: ${landmarks.length}, timestamp: $timestamp)';
  }
}
