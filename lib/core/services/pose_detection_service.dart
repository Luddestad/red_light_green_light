import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import '../constants/detection_constants.dart';
import '../../features/game/models/pose_landmark.dart';

class PoseDetectionService {
  static final PoseDetectionService _instance =
      PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  List<PoseData> _recentPoses = [];
  CameraDescription? _currentCamera;
  Size? _lastInputImageSize;
  InputImageRotation? _lastInputImageRotation;
  bool get isInitialized => _isInitialized;
  List<PoseData> get recentPoses => List.unmodifiable(_recentPoses);
  int get poseCount => _recentPoses.length;
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

  Future<List<Pose>> detectPoses(CameraImage cameraImage) async {
    if (!_isInitialized || _poseDetector == null) {
      return [];
    }

    try {
      final rotation = _getImageRotation();
      _lastInputImageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
      _lastInputImageRotation = rotation;

      final inputImage = _cameraImageToInputImage(cameraImage, rotation);
      final poses = await _poseDetector!.processImage(inputImage);

      // Store lightweight recent pose list for stats
      _recentPoses = poses.map((p) => PoseData.fromPose(p)).toList();

      return poses;
    } catch (e) {
      print('Pose detection error: $e');
      return [];
    }
  }

  /// Returns the first detected pose, or null if none. Use for single-player.
  Future<Pose?> detectFirstPose(CameraImage cameraImage) async {
    final poses = await detectPoses(cameraImage);
    return poses.isNotEmpty ? poses.first : null;
  }

  /// Detect movement between current and reference poses
  bool detectMovement(
    List<PoseData> currentPoses,
    List<PoseData> referencePoses,
  ) {
    if (currentPoses.isEmpty || referencePoses.isEmpty) {
      return false;
    }

    // Check if any current pose has moved significantly from reference poses
    return currentPoses.any((currentPose) {
      final closestReference = _findClosestPose(currentPose, referencePoses);
      return closestReference != null &&
          _hasSignificantMovement(currentPose, closestReference);
    });
  }

  /// Find the closest reference pose to a current pose
  PoseData? _findClosestPose(
    PoseData currentPose,
    List<PoseData> referencePoses,
  ) {
    if (referencePoses.isEmpty) return null;

    return referencePoses.reduce((closest, reference) {
      final currentDistance = _calculatePoseDistance(currentPose, reference);
      final closestDistance = _calculatePoseDistance(currentPose, closest);
      return currentDistance < closestDistance ? reference : closest;
    });
  }

  /// Calculate distance between two poses
  double _calculatePoseDistance(PoseData pose1, PoseData pose2) {
    double totalDistance = 0.0;
    int validLandmarks = 0;

    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      final landmark1 = pose1.getLandmarkByType(landmarkType);
      final landmark2 = pose2.getLandmarkByType(landmarkType);

      if (landmark1?.isValid == true && landmark2?.isValid == true) {
        totalDistance += landmark1!.distanceTo(landmark2!);
        validLandmarks++;
      }
    }

    return validLandmarks > 0
        ? totalDistance / validLandmarks
        : double.infinity;
  }

  /// Check if there's significant movement between two poses
  bool _hasSignificantMovement(PoseData currentPose, PoseData referencePose) {
    // Check individual landmark movement
    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      if (_landmarkMovedSignificantly(
        currentPose,
        referencePose,
        landmarkType,
      )) {
        return true;
      }
    }

    // Check forward movement using hip centers
    return _hasSignificantForwardMovement(currentPose, referencePose);
  }

  /// Check if a specific landmark moved significantly
  bool _landmarkMovedSignificantly(
    PoseData currentPose,
    PoseData referencePose,
    PoseLandmarkType landmarkType,
  ) {
    final currentLandmark = currentPose.getLandmarkByType(landmarkType);
    final referenceLandmark = referencePose.getLandmarkByType(landmarkType);

    if (currentLandmark == null || referenceLandmark == null) {
      return false;
    }

    final distance = currentLandmark.distanceTo(referenceLandmark);
    final threshold = _getMovementThreshold(landmarkType);

    return distance > threshold;
  }

  /// Check for significant forward movement
  bool _hasSignificantForwardMovement(
    PoseData currentPose,
    PoseData referencePose,
  ) {
    final currentHipCenter = _getHipCenter(currentPose);
    final referenceHipCenter = _getHipCenter(referencePose);

    if (currentHipCenter == null || referenceHipCenter == null) {
      return false;
    }

    final forwardDistance = (currentHipCenter.x - referenceHipCenter.x).abs();
    return forwardDistance > DetectionConstants.forwardMovementThreshold;
  }

  /// Get movement threshold for specific landmark type
  double _getMovementThreshold(PoseLandmarkType landmarkType) {
    return switch (landmarkType) {
      PoseLandmarkType.leftShoulder || PoseLandmarkType.rightShoulder =>
        DetectionConstants.shoulderMovementThreshold,

      PoseLandmarkType.leftHip ||
      PoseLandmarkType.rightHip => DetectionConstants.hipMovementThreshold,

      PoseLandmarkType.nose => DetectionConstants.noseMovementThreshold,

      _ => 0.1, // Default movement threshold
    };
  }

  /// Calculate hip center point
  PoseLandmarkData? _getHipCenter(PoseData pose) {
    final leftHip = pose.getLandmarkByType(PoseLandmarkType.leftHip);
    final rightHip = pose.getLandmarkByType(PoseLandmarkType.rightHip);

    if (leftHip == null || rightHip == null) return null;

    return PoseLandmarkData(
      type: PoseLandmarkType.leftHip,
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
    );
  }

  /// Convert CameraImage to InputImage
  InputImage _cameraImageToInputImage(CameraImage cameraImage, InputImageRotation rotation) {
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

  void clearRecentPoses() {
    _recentPoses.clear();
  }

  Future<void> dispose() async {
    try {
      await _poseDetector?.close();
      _poseDetector = null;
      _isInitialized = false;
      _recentPoses.clear();
      _currentCamera = null;
    } catch (e) {
      print('Error disposing pose detector: $e');
    }
  }
}
