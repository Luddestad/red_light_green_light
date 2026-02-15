import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Computer vision and detection constants
class DetectionConstants {
  // Pose Detection Settings
  static const PoseLandmarkType leftShoulder = PoseLandmarkType.leftShoulder;
  static const PoseLandmarkType rightShoulder = PoseLandmarkType.rightShoulder;
  static const PoseLandmarkType leftHip = PoseLandmarkType.leftHip;
  static const PoseLandmarkType rightHip = PoseLandmarkType.rightHip;
  static const PoseLandmarkType nose = PoseLandmarkType.nose;

  // Monitored landmarks for movement detection
  static const List<PoseLandmarkType> monitoredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.nose,
  ];

  // Movement Detection Thresholds
  static const double shoulderMovementThreshold = 0.08; // 8cm
  static const double hipMovementThreshold = 0.12; // 12cm
  static const double noseMovementThreshold = 0.06; // 6cm

  // Forward Movement Detection
  static const double forwardMovementThreshold = 0.15; // 15cm
}
