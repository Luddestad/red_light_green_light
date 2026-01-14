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
  
  // Face Recognition Settings
  // Face recognition removed for single-player mode
  
  // Detection Performance
  static const int detectionFrameRate = 30;
  static const int poseDetectionInterval = 100; // milliseconds
  // faceDetectionInterval removed
  
  // Camera Settings
  static const double cameraAspectRatio = 16 / 9;
  static const int preferredCameraResolution = 720; // 720p
  static const bool enableCameraStabilization = true;
  
  // Movement Detection Thresholds
  static const double shoulderMovementThreshold = 0.08; // 8cm
  static const double hipMovementThreshold = 0.12; // 12cm
  static const double noseMovementThreshold = 0.06; // 6cm
  
  // Forward Movement Detection
  static const double forwardMovementThreshold = 0.15; // 15cm
  static const double forwardMovementConfidence = 0.75;
  
  // Pose Quality
  static const double minimumPoseConfidence = 0.5;
  static const int maxPosesPerFrame = 4; // Maximum 4 players
  
  // Error Handling
  static const int maxDetectionFailures = 5;
  static const Duration detectionTimeout = Duration(seconds: 10);
}
