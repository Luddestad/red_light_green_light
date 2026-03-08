import 'dart:async';

import 'package:flutter/material.dart';
import 'package:task1/controllers/game_controller.dart';
import 'package:task1/services/camera_service.dart';
import 'package:task1/services/pose_detection_service.dart';
import 'package:task1/widgets/movement_overlay_widget.dart';

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
                                // Allow touches to pass through
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
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

            ],
          ),
        );
      },
    ),
    );
  }
}
