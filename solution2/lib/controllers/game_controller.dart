import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:solution2/services/camera_service.dart';
import 'package:solution2/services/pose_detection_service.dart';

class GameController extends ChangeNotifier {
  final CameraService cameraService;
  final PoseDetectionService poseDetectionService;

  /// Max time to wait for pose detection per frame; after this we skip the
  /// result and process the next frame so overlay latency stays bounded.
  static const Duration maxFrameProcessingTime = Duration(milliseconds: 150);

  /// The movement threshold in pixels. If any tracked landmark moves
  /// more than this many pixels from the baseline, we consider it "movement".
  static const double movementThreshold = 80.0;

  /// The key body landmarks we monitor for movement.
  static const List<PoseLandmarkType> keyLandmarks = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
  ];

  GameController({
    required this.cameraService,
    required this.poseDetectionService,
  });

  Pose? currentPose;
  Pose? baselinePose;
  bool isProcessing = false;
  bool isMoving = false;

  /// Input image metadata for overlay (from last processed frame).
  Size? get overlayImageSize => poseDetectionService.lastInputImageSize;
  InputImageRotation get overlayRotation =>
      poseDetectionService.lastInputImageRotation ??
      InputImageRotation.rotation0deg;
  CameraLensDirection get overlayLensDirection =>
      cameraService.controller?.description.lensDirection ??
      CameraLensDirection.front;

  Future<void> initializeGame() async {
    await cameraService.startPreview();
    cameraService.imageStream?.listen(processImage);
  }

  /// Save the current pose as the baseline ("freeze" position).
  void saveBaseline() {
    if (currentPose != null) {
      baselinePose = currentPose;
      isMoving = false;
      print('Baseline saved! Stand still...');
      notifyListeners();
    }
  }

  /// Clear the baseline (stop detecting movement).
  void clearBaseline() {
    baselinePose = null;
    isMoving = false;
    notifyListeners();
  }

  /// Update pose detection (single player)
  Future<void> updatePoseDetection(Pose? pose) async {
    if (pose == null) {
      currentPose = null;
      return;
    }

    currentPose = pose;
  }

  /// TODO 1: Get a landmark from a pose and check if it's reliable.
  ///
  /// The ML model outputs 33 body landmarks (nose, shoulders, elbows, etc).
  /// They're stored in a Map<PoseLandmarkType, PoseLandmark>.
  ///
  /// Each PoseLandmark has:
  ///   - x, y  — pixel position in the camera image
  ///   - z     — depth estimate
  ///   - likelihood — confidence score from 0.0 to 1.0
  ///
  /// A landmark with likelihood > 0.5 means the model is reasonably
  /// confident it found that body part.
  ///
  /// Steps:
  /// 1. Look up the landmark in pose.landmarks[type]
  /// 2. If it exists AND its likelihood > 0.5, return it
  /// 3. Otherwise return null
  ///
  /// See hints/hint1.md if you get stuck!
  ///
  /// Get a landmark from a pose if it's reliable (likelihood > 0.5).
  PoseLandmark? getValidLandmark(Pose pose, PoseLandmarkType type) {
    final landmark = pose.landmarks[type];
    if (landmark != null && landmark.likelihood > 0.5) {
      return landmark;
    }
    return null;
  }

  /// TODO 2: Detect if the player moved by comparing two poses.
  ///
  /// For each landmark type in [keyLandmarks]:
  /// 1. Use getValidLandmark() to get it from both poses
  /// 2. If both are valid, calculate the 2D pixel distance:
  ///    sqrt((x2-x1)² + (y2-y1)²)
  /// 3. If the distance exceeds movementThreshold, return true
  ///
  /// Return false if no landmark exceeded the threshold.
  ///
  /// Docs:
  /// - dart:math sqrt/pow: https://api.dart.dev/stable/dart-math/sqrt.html
  ///
  /// See hints/hint2.md if you get stuck!
  ///
  /// Check if someone moved by comparing current pose to baseline.
  ///
  /// For each key landmark: get it from both poses, calculate pixel
  /// distance, and flag movement if it exceeds the threshold.
  bool checkSimpleMovement(Pose current, Pose baseline) {
    for (final type in keyLandmarks) {
      final currentLM = getValidLandmark(current, type);
      final baselineLM = getValidLandmark(baseline, type);

      if (currentLM != null && baselineLM != null) {
        final distance = math.sqrt(
          math.pow(currentLM.x - baselineLM.x, 2) +
              math.pow(currentLM.y - baselineLM.y, 2),
        );

        if (distance > movementThreshold) {
          print(
            'Movement at ${type.toString().split('.').last}: ${distance.toStringAsFixed(1)}px',
          );
          return true;
        }
      }
    }

    return false;
  }

  Future<void> processImage(CameraImage image) async {
    if (isProcessing) return;

    isProcessing = true;
    try {
      final pose = await poseDetectionService
          .detectPose(image)
          .timeout(maxFrameProcessingTime, onTimeout: () => null);

      if (pose != null) {
        await updatePoseDetection(pose);
      }

      // TODO 3: If we have a baseline, check for movement.
      // Call checkSimpleMovement() with currentPose and baselinePose,
      // and store the result in isMoving.
      //
      // See hints/hint3.md if you get stuck!
      // Check for movement if we have a baseline
      if (baselinePose != null && currentPose != null) {
        isMoving = checkSimpleMovement(currentPose!, baselinePose!);
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
