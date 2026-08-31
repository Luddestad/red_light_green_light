import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'permission_service.dart';

/// Service for managing camera functionality
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  StreamController<CameraImage>? _imageStreamController;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription> get cameras => _cameras;
  Stream<CameraImage>? get imageStream => _imageStreamController?.stream;

  /// Initialize camera service
  ///
  /// TODO: Implement the missing parts below. You need to:
  /// 1. Get the list of available cameras on the device
  /// 2. Select the front-facing (selfie) camera from that list
  /// 3. Create a broadcast StreamController for the image stream
  /// 4. Mark the service as initialized
  ///
  /// Return true on success, false on failure.
  ///
  /// Docs:
  /// - Camera package: https://pub.dev/packages/camera
  /// - StreamController: https://api.dart.dev/stable/dart-async/StreamController-class.html
  ///
  /// See hints/part1_hint1.md if you get stuck!
  Future<bool> initialize() async {
    try {
      await checkCameraPermissions();

      // TODO: Get available cameras using availableCameras()
      // and store them in _cameras

      // TODO: Select the front-facing camera

      // The camera controller is created for you — it handles
      // resolution, image format, and platform differences.
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      // TODO: Create a broadcast StreamController<CameraImage>
      // and assign it to _imageStreamController

      // TODO: Mark the service as initialized
    } catch (e) {
      print('Camera initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// TODO: Implement this method. You need to:
  /// 1. Check that the camera is initialized
  /// 2. Start the image stream on the controller
  /// 3. Forward each frame to _imageStreamController
  ///
  /// Return true on success, false on failure.
  ///
  /// Docs:
  /// - startImageStream: https://pub.dev/documentation/camera/latest/camera/CameraController/startImageStream.html
  ///
  /// See hints/part2_hint1.md if you get stuck!
  Future<bool> startPreview() async {
    // YOUR CODE HERE
    throw UnimplementedError('Implement startPreview()');
  }

  Future<bool> checkCameraPermissions() async {
    final permissionService = PermissionService();
    if (!await permissionService.isCameraPermissionGranted()) {
      final granted = await permissionService.requestCameraPermission();
      if (!granted) {
        throw Exception('Camera permission is required to play the game');
      }
      return granted;
    }
    return false;
  }

  /// Get camera preview widget
  Widget? getCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    return CameraPreview(_controller!);
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }
}
