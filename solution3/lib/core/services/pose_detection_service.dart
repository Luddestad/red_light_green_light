import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';

class PoseDetectionService {
  static final PoseDetectionService _instance =
      PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  CameraDescription? _currentCamera;
  Size? _lastInputImageSize;
  InputImageRotation? _lastInputImageRotation;
  bool get isInitialized => _isInitialized;
  Size? get lastInputImageSize => _lastInputImageSize;
  InputImageRotation? get lastInputImageRotation => _lastInputImageRotation;

  Future<bool> initialize({CameraDescription? camera}) async {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );

      _currentCamera = camera;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Pose detection initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<List<Pose>> _detectPoses(CameraImage cameraImage) async {
    if (!_isInitialized || _poseDetector == null) {
      return [];
    }

    try {
      final rotation = _getImageRotation();
      _lastInputImageSize = Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );
      _lastInputImageRotation = rotation;

      final inputImage = _cameraImageToInputImage(cameraImage, rotation);
      final poses = await _poseDetector!.processImage(inputImage);

      return poses;
    } catch (e) {
      print('Pose detection error: $e');
      return [];
    }
  }

  /// Returns the first detected pose, or null if none. Use for single-player.
  Future<Pose?> detectPose(CameraImage cameraImage) async {
    final poses = await _detectPoses(cameraImage);
    return poses.isNotEmpty ? poses.first : null;
  }

  /// Convert CameraImage to InputImage
  InputImage _cameraImageToInputImage(
    CameraImage cameraImage,
    InputImageRotation rotation,
  ) {
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);

    if (format == null) {
      throw Exception(
        'Unsupported camera image format: ${cameraImage.format.raw}',
      );
    }

    final bytes = _concatenatePlanes(cameraImage.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      ),
    );
  }

  /// Concatenate camera image planes into single byte array
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// Get proper image rotation based on camera sensor orientation
  InputImageRotation _getImageRotation() {
    if (_currentCamera == null) {
      return InputImageRotation.rotation0deg;
    }

    final sensorOrientation = _currentCamera!.sensorOrientation;
    final rotationCompensation = Platform.isIOS ? 0 : sensorOrientation;

    return InputImageRotationValue.fromRawValue(rotationCompensation) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> dispose() async {
    try {
      await _poseDetector?.close();
      _poseDetector = null;
      _isInitialized = false;
      _currentCamera = null;
    } catch (e) {
      print('Error disposing pose detector: $e');
    }
  }
}
