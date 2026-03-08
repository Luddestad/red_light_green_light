import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:task2/services/camera_service.dart';
import 'package:task2/services/pose_detection_service.dart';
import 'package:task2/models/pose_landmark.dart';

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

  /// TODO 1: Implement movement detection.
  ///
  /// Compare the current pose to the baseline pose to determine if
  /// the person has moved. For each landmark in keyLandmarks:
  ///
  /// 1. Get that landmark from both poses using pose.landmarks[type]
  /// 2. Check that both exist and are confident (likelihood > 0.5)
  /// 3. Calculate the 2D pixel distance between them:
  ///    sqrt((x2-x1)² + (y2-y1)²)
  /// 4. If the distance exceeds movementThreshold, return true
  ///
  /// Return false if no landmark exceeded the threshold.
  ///
  /// Docs:
  /// - Pose.landmarks is a Map<PoseLandmarkType, PoseLandmark>
  /// - Each PoseLandmark has: x, y, z, likelihood
  /// - dart:math sqrt/pow: https://api.dart.dev/stable/dart-math/sqrt.html
  ///
  /// See hints/part2_hint1.md if you get stuck!
  bool checkSimpleMovement(Pose current, Pose baseline) {
    // YOUR CODE HERE
    throw UnimplementedError('Implement checkSimpleMovement');
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

      // TODO 2: If we have a baseline, check for movement.
      // Call checkSimpleMovement() with currentPose and baselinePose,
      // and store the result in isMoving.
      //
      // See hints/part2_hint2.md if you get stuck!
    } catch (e) {
      print('Detection error: $e');
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
