import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';
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
  Future<bool> initialize() async {
    try {
      checkCameraPerimissions();

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use front-facing camera (selfie camera)
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () =>
            _cameras.first, // Fallback to first camera if no front camera
      );

      print('Selected camera: ${camera.name}, lens: ${camera.lensDirection}');

      // Initialize camera controller - let ML Kit handle the format
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();

      _imageStreamController = StreamController<CameraImage>.broadcast();

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Camera initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> startPreview() async {
    if (!_isInitialized || _controller == null) {
      return false;
    }

    try {
      await _controller!.startImageStream((CameraImage image) {
        print(
          'Camera image received: ${image.width}x${image.height}, format: ${image.format.raw}',
        );
        _imageStreamController?.add(image);
      });
      return true;
    } catch (e) {
      print('Failed to start camera preview: $e');
      return false;
    }
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    try {
      await _controller?.stopImageStream();
      _imageStreamController?.close();
      _imageStreamController = null;
    } catch (e) {
      print('Failed to stop camera preview: $e');
    }
  }

  Future<bool> checkCameraPerimissions() async {
    final permissionService = PermissionService();
    if (!await permissionService.isCameraPermissionGranted()) {
      final granted = await permissionService.requestCameraPermission();
      if (!granted) {
        throw Exception(AppConstants.cameraPermissionDenied);
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
      await stopPreview();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  Future<bool> isCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      print('Error checking camera availability: $e');
      return false;
    }
  }

  Map<String, dynamic> getCameraInfo() {
    if (!_isInitialized || _controller == null) {
      return {};
    }

    return {
      'name': _controller!.description.name,
      'lensDirection': _controller!.description.lensDirection.toString(),
      'sensorOrientation': _controller!.description.sensorOrientation,
      'isInitialized': _isInitialized,
    };
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (!_isInitialized || _controller == null) return;

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      print('Failed to set flash mode: $e');
    }
  }

  /// Set camera focus mode
  Future<void> setFocusMode(FocusMode mode) async {
    if (!_isInitialized || _controller == null) return;

    try {
      await _controller!.setFocusMode(mode);
    } catch (e) {
      print('Failed to set focus mode: $e');
    }
  }
}
