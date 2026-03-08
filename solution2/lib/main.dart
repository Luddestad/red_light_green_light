import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:solution2/controllers/game_controller.dart';
import 'package:solution2/services/camera_service.dart';
import 'package:solution2/services/pose_detection_service.dart';
import 'package:solution2/widgets/movement_overlay_widget.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  final CameraService _cameraService = CameraService();
  final PoseDetectionService _poseService = PoseDetectionService();
  GameController? gameController;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeServices());
  }

  Future<void> _initializeServices() async {
    await _cameraService.initialize();
    await _poseService.initialize(
      camera: _cameraService.controller?.description,
    );

    final controller = GameController(
      cameraService: _cameraService,
      poseDetectionService: _poseService,
    );

    await controller.initializeGame();

    setState(() {
      gameController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gc = gameController;
    if (gc == null) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      home: ListenableBuilder(
        listenable: gc,
        builder: (context, child) {
          final controller = gc;
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Camera preview
                if (controller.cameraService.isInitialized)
                  Positioned.fill(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            1.0 /
                            controller
                                .cameraService
                                .controller!
                                .value
                                .aspectRatio,
                        child: Stack(
                          children: [
                            controller.cameraService.getCameraPreview() ??
                                Container(),

                            // Movement detection overlay
                            if (controller.currentPose != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: MovementOverlayWidget(
                                    pose: controller.currentPose,
                                    imageSize:
                                        controller.overlayImageSize ??
                                        controller
                                            .cameraService
                                            .controller
                                            ?.value
                                            .previewSize ??
                                        Size.zero,
                                    rotation: controller.overlayRotation,
                                    cameraLensDirection:
                                        controller.overlayLensDirection,
                                    isMoving: controller.isMoving,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Status panel at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStatusPanel(controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPanel(GameController controller) {
    final poseData = controller.currentPoseData;

    // Count valid landmarks
    final totalLandmarks = poseData?.landmarks.length ?? 0;
    final validLandmarks =
        poseData?.landmarks.where((l) => l.isValid).length ?? 0;

    // Get nose position
    final nose = poseData?.getLandmarkByType(PoseLandmarkType.nose);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Landmark info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  'Landmarks',
                  '$validLandmarks/$totalLandmarks valid',
                  Colors.cyan,
                ),
                _buildInfoChip(
                  'Nose',
                  nose != null
                      ? '(${nose.x.toStringAsFixed(0)}, ${nose.y.toStringAsFixed(0)})'
                      : 'N/A',
                  Colors.orange,
                ),
                _buildMovementStatus(controller),
              ],
            ),
            const SizedBox(height: 12),
            // Baseline buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.currentPose != null
                      ? controller.saveBaseline
                      : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Baseline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: controller.baselinePose != null
                      ? controller.clearBaseline
                      : null,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Baseline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMovementStatus(GameController controller) {
    final hasBaseline = controller.baselinePose != null;
    final isMoving = controller.isMoving;

    final String statusText;
    final Color statusColor;

    if (!hasBaseline) {
      statusText = 'NO BASELINE';
      statusColor = Colors.grey;
    } else if (isMoving) {
      statusText = 'MOVING';
      statusColor = Colors.red;
    } else {
      statusText = 'STILL';
      statusColor = Colors.green;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Movement',
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
