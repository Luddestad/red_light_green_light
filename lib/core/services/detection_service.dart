import 'dart:async';
import 'package:camera/camera.dart';
import 'pose_detection_service.dart';
import '../../features/game/models/pose_landmark.dart';
import '../../features/game/models/movement_detection.dart';
// Face registration removed; registration model not required

/// Combined detection service for face and pose detection
class DetectionService {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  // Face detection removed — pose detection only for single-player mode
  final PoseDetectionService _poseService = PoseDetectionService();
  
  bool _isInitialized = false;
  StreamController<DetectionResult>? _detectionStreamController;
  
  // Detection state
  List<PoseData> _referencePoses = [];
  Map<String, String> _poseToPlayerMap = {};
  bool _isDetecting = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  Stream<DetectionResult>? get detectionStream => _detectionStreamController?.stream;

  /// Initialize the detection service
  Future<bool> initialize() async {
    try {
  // Initialize pose service for single-player mode.
  final poseInitialized = await _poseService.initialize();

      if (!poseInitialized) {
        return false;
      }

      // Initialize detection stream
      _detectionStreamController = StreamController<DetectionResult>.broadcast();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Detection service initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start detection on camera image
  Future<void> processImage(CameraImage cameraImage) async {
    if (!_isInitialized || _isDetecting) return;

    _isDetecting = true;

    try {
      // Run pose detection only for single-player simplicity
      final mlPoses = await _poseService.detectPoses(cameraImage);

      // Convert ML Kit Pose to our PoseData model
      final poses = mlPoses.map((p) => PoseData.fromPose(p)).toList();

      // Debug logging
      print('Detection results: ${poses.length} poses (faces disabled)');

      // Create detection result (pose-only)
      final detectionResult = DetectionResult(
        poses: poses,
        poseToPlayerMap: Map.from(_poseToPlayerMap),
        timestamp: DateTime.now(),
      );

      // Emit result
      _detectionStreamController?.add(detectionResult);

    } catch (e) {
      // Log the error but don't crash the app
      if (e.toString().contains('Unsupported camera image format')) {
        print('Camera format issue: ${e.toString()}');
        // Try to continue with empty results (pose-only)
        final detectionResult = DetectionResult(
          poses: const [],
          poseToPlayerMap: const {},
          timestamp: DateTime.now(),
        );
        _detectionStreamController?.add(detectionResult);
      } else {
        print('Detection processing error: $e');
      }
    } finally {
      _isDetecting = false;
    }
  }



  /// Set reference poses for movement detection
  void setReferencePoses(List<PoseData> referencePoses, Map<String, String> poseToPlayerMap) {
    _referencePoses = List.from(referencePoses);
    _poseToPlayerMap = Map.from(poseToPlayerMap);
  }

  /// Detect movement in current poses
  MovementDetectionResult? detectMovement(List<PoseData> currentPoses) {
    if (_referencePoses.isEmpty || currentPoses.isEmpty) {
      return null;
    }

    return MovementDetector.detectMovement(
      currentPoses: currentPoses,
      referencePoses: _referencePoses,
      poseToPlayerMap: _poseToPlayerMap,
    );
  }

  // Face registration removed in single-player mode

  /// Get detection statistics
  DetectionStats getStats() {
    return DetectionStats(
      faceCount: 0,
      poseCount: _poseService.poseCount,
      registeredPlayerCount: 0,
      isDetecting: _isDetecting,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
  await _detectionStreamController?.close();
  await _poseService.dispose();

  _detectionStreamController = null;
  _isInitialized = false;
  _referencePoses.clear();
  _poseToPlayerMap.clear();
    } catch (e) {
      print('Error disposing detection service: $e');
    }
  }
}

/// Result of detection processing
class DetectionResult {
  final List<PoseData> poses;
  final Map<String, String> poseToPlayerMap;
  final DateTime timestamp;

  const DetectionResult({
    required this.poses,
    required this.poseToPlayerMap,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'DetectionResult(poses: ${poses.length})';
  }
}

/// Detection service statistics
class DetectionStats {
  final int faceCount;
  final int poseCount;
  final int registeredPlayerCount;
  final bool isDetecting;

  const DetectionStats({
    required this.faceCount,
    required this.poseCount,
    required this.registeredPlayerCount,
    required this.isDetecting,
  });

  @override
  String toString() {
    return 'DetectionStats(faces: $faceCount, poses: $poseCount, players: $registeredPlayerCount, detecting: $isDetecting)';
  }
}
