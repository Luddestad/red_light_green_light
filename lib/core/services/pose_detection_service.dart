import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import '../constants/detection_constants.dart';
import '../../features/game/models/pose_landmark.dart';

/// Service for pose detection and tracking
class PoseDetectionService {
  static final PoseDetectionService _instance = PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  List<PoseData> _recentPoses = [];
  final int _maxRecentPoses = 10;

  // Getters
  bool get isInitialized => _isInitialized;
  List<PoseData> get recentPoses => List.unmodifiable(_recentPoses);

  /// Initialize the pose detection service
  Future<bool> initialize() async {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Pose detection initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Detect poses in camera image
  Future<List<Pose>> detectPoses(CameraImage cameraImage) async {
    if (!_isInitialized || _poseDetector == null) {
      return [];
    }

    try {
      // Convert CameraImage to InputImage
      final inputImage = _cameraImageToInputImage(cameraImage);
      
      // Detect poses
      final poses = await _poseDetector!.processImage(inputImage);
      
      // For game usage, just return the raw poses
      return poses;
    } catch (e) {
      print('Pose detection error: $e');
      return [];
    }
  }

  /// Update recent poses list for movement tracking
  void _updateRecentPoses(List<PoseData> newPoses) {
    _recentPoses.addAll(newPoses);
    
    // Keep only recent poses (last 10)
    if (_recentPoses.length > _maxRecentPoses) {
      _recentPoses = _recentPoses.skip(_recentPoses.length - _maxRecentPoses).toList();
    }
  }

  /// Detect movement between current and reference poses
  bool detectMovement(List<PoseData> currentPoses, List<PoseData> referencePoses) {
    if (currentPoses.isEmpty || referencePoses.isEmpty) {
      return false;
    }

    // For each current pose, find the closest reference pose and check for movement
    for (final currentPose in currentPoses) {
      final closestReference = _findClosestPose(currentPose, referencePoses);
      if (closestReference != null && _hasSignificantMovement(currentPose, closestReference)) {
        return true;
      }
    }

    return false;
  }

  /// Find the closest reference pose to a current pose
  PoseData? _findClosestPose(PoseData currentPose, List<PoseData> referencePoses) {
    if (referencePoses.isEmpty) return null;

    PoseData? closest;
    double minDistance = double.infinity;

    for (final referencePose in referencePoses) {
      final distance = _calculatePoseDistance(currentPose, referencePose);
      if (distance < minDistance) {
        minDistance = distance;
        closest = referencePose;
      }
    }

    return closest;
  }

  /// Calculate distance between two poses
  double _calculatePoseDistance(PoseData pose1, PoseData pose2) {
    double totalDistance = 0.0;
    int validLandmarks = 0;

    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      final landmark1 = pose1.getLandmarkByType(landmarkType);
      final landmark2 = pose2.getLandmarkByType(landmarkType);

      if (landmark1 != null && landmark2 != null && landmark1.isValid && landmark2.isValid) {
        totalDistance += landmark1.distanceTo(landmark2);
        validLandmarks++;
      }
    }

    return validLandmarks > 0 ? totalDistance / validLandmarks : double.infinity;
  }

  /// Check if there's significant movement between two poses
  bool _hasSignificantMovement(PoseData currentPose, PoseData referencePose) {
    // Check individual landmark movement
    for (final landmarkType in DetectionConstants.monitoredLandmarks) {
      final currentLandmark = currentPose.getLandmarkByType(landmarkType);
      final referenceLandmark = referencePose.getLandmarkByType(landmarkType);

      if (currentLandmark != null && referenceLandmark != null) {
        final distance = currentLandmark.distanceTo(referenceLandmark);
        
        // Check against specific thresholds for different landmarks
        double threshold = _getMovementThreshold(landmarkType);
        
        if (distance > threshold) {
          return true;
        }
      }
    }

    // Check forward movement (using hip landmarks)
    final currentHipCenter = _getHipCenter(currentPose);
    final referenceHipCenter = _getHipCenter(referencePose);

    if (currentHipCenter != null && referenceHipCenter != null) {
      final forwardDistance = (currentHipCenter.x - referenceHipCenter.x).abs();
      if (forwardDistance > DetectionConstants.forwardMovementThreshold) {
        return true;
      }
    }

    return false;
  }

  /// Get movement threshold for specific landmark type
  double _getMovementThreshold(PoseLandmarkType landmarkType) {
    switch (landmarkType) {
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
        return DetectionConstants.shoulderMovementThreshold;
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return DetectionConstants.hipMovementThreshold;
      case PoseLandmarkType.nose:
        return DetectionConstants.noseMovementThreshold;
      default:
        return 0.1; // Default movement threshold
    }
  }

  /// Calculate hip center point
  PoseLandmarkData? _getHipCenter(PoseData pose) {
    final leftHip = pose.getLandmarkByType(PoseLandmarkType.leftHip);
    final rightHip = pose.getLandmarkByType(PoseLandmarkType.rightHip);

    if (leftHip == null || rightHip == null) return null;

    return PoseLandmarkData(
      type: PoseLandmarkType.leftHip, // Use leftHip as center type
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
    );
  }

  /// Convert CameraImage to InputImage - correct YUV420 handling
  InputImage _cameraImageToInputImage(CameraImage cameraImage) {
    final camera = cameraImage;
    final format = InputImageFormatValue.fromRawValue(camera.format.raw);
    
    if (format == null) {
      throw Exception('Unsupported camera image format: ${camera.format.raw}');
    }

    if (camera.planes.length == 1) {
      // Single plane format (BGRA8888, etc.)
      final plane = camera.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(camera.width.toDouble(), camera.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(0) ?? InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else if (camera.planes.length == 3) {
      // YUV420 format - combine all planes correctly
      final yPlane = camera.planes[0];
      final uPlane = camera.planes[1];
      final vPlane = camera.planes[2];
      
      // Calculate total size for YUV420
      final ySize = yPlane.bytes.length;
      final uSize = uPlane.bytes.length;
      final vSize = vPlane.bytes.length;
      final totalSize = ySize + uSize + vSize;
      
      // Create combined byte array
      final yuvBytes = Uint8List(totalSize);
      yuvBytes.setRange(0, ySize, yPlane.bytes);
      yuvBytes.setRange(ySize, ySize + uSize, uPlane.bytes);
      yuvBytes.setRange(ySize + uSize, totalSize, vPlane.bytes);
      
      return InputImage.fromBytes(
        bytes: yuvBytes,
        metadata: InputImageMetadata(
          size: Size(camera.width.toDouble(), camera.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(0) ?? InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: yPlane.bytesPerRow,
        ),
      );
    } else {
      throw Exception('Unsupported camera image format with ${camera.planes.length} planes');
    }
  }

  /// Clear recent poses
  void clearRecentPoses() {
    _recentPoses.clear();
  }

  /// Get pose count
  int get poseCount => _recentPoses.length;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _poseDetector?.close();
      _poseDetector = null;
      _isInitialized = false;
      _recentPoses.clear();
    } catch (e) {
      print('Error disposing pose detector: $e');
    }
  }
}
