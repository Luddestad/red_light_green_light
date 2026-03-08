import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:solution2/services/camera_service.dart';
import 'package:solution2/services/pose_detection_service.dart';
import 'package:solution2/models/pose_landmark.dart';

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
  PoseData? currentPoseData;
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
      currentPoseData = null;
      return;
    }

    currentPose = pose;
    currentPoseData = PoseData.fromPose(pose);
  }

  /// Check if someone moved by comparing current pose to baseline.
  ///
  /// For each key landmark: get it from both poses, check both are
  /// confident enough (likelihood > 0.5), calculate pixel distance,
  /// and flag movement if it exceeds the threshold.
  bool checkSimpleMovement(Pose current, Pose baseline) {
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
