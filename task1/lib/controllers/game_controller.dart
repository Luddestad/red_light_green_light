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

  GameController({
    required this.cameraService,
    required this.poseDetectionService,
  });

  Pose? currentPose;

  /// Input image metadata for overlay (from last processed frame).
  Size? get overlayImageSize => poseDetectionService.lastInputImageSize;
  InputImageRotation get overlayRotation =>
      poseDetectionService.lastInputImageRotation ??
      InputImageRotation.rotation0deg;
  CameraLensDirection get overlayLensDirection =>
      cameraService.controller?.description.lensDirection ??
      CameraLensDirection.front;

  Future<void> initializeGame() async {
    // Services are already initialized from StartScreen
    // Just start the camera stream and game-specific setup
    await cameraService.startPreview();
    cameraService.imageStream?.listen(processImage);
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

  Future<void> processImage(CameraImage image) async {
    try {
      final pose = await poseDetectionService.detectFirstPose(image);
      await updatePoseDetection(pose);
    } catch (e) {
      print('Detection error: $e');
    } finally {
      notifyListeners();
    }
  }
}
