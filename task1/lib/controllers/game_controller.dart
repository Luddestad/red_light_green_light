import 'dart:async';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:task1/services/camera_service.dart';
import 'package:task1/services/pose_detection_service.dart';

class GameController extends ChangeNotifier {
  final CameraService cameraService;
  final PoseDetectionService poseDetectionService;

  /// Max time to wait for pose detection per frame; after this we skip the
  /// result and process the next frame so overlay latency stays bounded.
  /// The native ML call may still run in the background; we just stop waiting.
  static const Duration maxFrameProcessingTime = Duration(milliseconds: 150);

  GameController({
    required this.cameraService,
    required this.poseDetectionService,
  });

  Pose? currentPose;
  bool isProcessing = false;

  /// Input image metadata for overlay (from last processed frame).
  Size? get overlayImageSize => poseDetectionService.lastInputImageSize;
  InputImageRotation get overlayRotation =>
      poseDetectionService.lastInputImageRotation ??
      InputImageRotation.rotation0deg;
  CameraLensDirection get overlayLensDirection =>
      cameraService.controller?.description.lensDirection ??
      CameraLensDirection.front;

  /// TODO: Implement this method. You need to:
  /// 1. Start the camera preview
  /// 2. Listen to the camera image stream and process each frame
  ///
  /// See hints/part2_hint1.md if you get stuck!
  Future<void> initializeGame() async {
    // YOUR CODE HERE
  }

  /// Dispose controller resources
  @override
  void dispose() {
    super.dispose();
  }

  /// Update pose detection (single player)
  Future<void> updatePoseDetection(Pose? pose) async {
    if (pose == null) {
      currentPose = null;
      return;
    }

    currentPose = pose;
  }

  /// TODO: Implement this method. You need to:
  /// 1. Guard against processing multiple frames at once (use isProcessing)
  /// 2. Feed the CameraImage to the pose detection service
  /// 3. Update the current pose with the result
  /// 4. Call notifyListeners() so the UI updates
  ///
  /// Tip: use .timeout() to skip slow frames and keep the overlay responsive.
  /// See hints/part2_hint2.md if you get stuck!
  Future<void> processImage(CameraImage image) async {
    // YOUR CODE HERE
  }
}
