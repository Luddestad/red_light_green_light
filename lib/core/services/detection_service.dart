import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_recognition_service.dart';
import 'pose_detection_service.dart';
import '../../features/game/models/pose_landmark.dart';
import '../../features/game/models/movement_detection.dart';
import '../../features/registration/models/face_encoding_model.dart';

/// Combined detection service for face and pose detection
class DetectionService {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  final FaceRecognitionService _faceService = FaceRecognitionService();
  final PoseDetectionService _poseService = PoseDetectionService();
  
  bool _isInitialized = false;
  StreamController<DetectionResult>? _detectionStreamController;
  
  // Detection state
  List<PoseData> _referencePoses = [];
  Map<String, String> _poseToPlayerMap = {};
  Map<String, String> _faceToPlayerMap = {};
  bool _isDetecting = false;
  int _frameCount = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  Stream<DetectionResult>? get detectionStream => _detectionStreamController?.stream;

  /// Initialize the detection service
  Future<bool> initialize() async {
    try {
      // Initialize both services
      final faceInitialized = await _faceService.initialize();
      final poseInitialized = await _poseService.initialize();
      
      if (!faceInitialized || !poseInitialized) {
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
      // Run face detection only (disable pose detection temporarily)
      final faces = await _faceService.detectFaces(cameraImage);
      final poses = <PoseData>[]; // Disable pose detection for now
      
      // Debug logging
      print('Detection results: ${faces.length} faces, ${poses.length} poses');
      if (faces.isNotEmpty) {
        print('First face bounding box: ${faces.first.boundingBox}');
        print('First face landmarks: ${faces.first.landmarks.length}');
      }

      // Identify players from faces
      await _identifyPlayersFromFaces(faces, cameraImage);

      // Create detection result
      final detectionResult = DetectionResult(
        faces: faces,
        poses: poses,
        faceToPlayerMap: Map.from(_faceToPlayerMap),
        poseToPlayerMap: Map.from(_poseToPlayerMap),
        timestamp: DateTime.now(),
      );

      // Emit result
      _detectionStreamController?.add(detectionResult);

    } catch (e) {
      // Log the error but don't crash the app
      if (e.toString().contains('Unsupported camera image format')) {
        print('Camera format issue: ${e.toString()}');
        // Try to continue with empty results
        final detectionResult = DetectionResult(
          faces: [],
          poses: [],
          faceToPlayerMap: {},
          poseToPlayerMap: {},
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

  /// Identify players from detected faces
  Future<void> _identifyPlayersFromFaces(List<Face> faces, CameraImage cameraImage) async {
    _faceToPlayerMap.clear();

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final playerId = await _faceService.identifyPlayer(face, cameraImage);
      
      if (playerId != null) {
        _faceToPlayerMap[i.toString()] = playerId;
      }
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

  /// Register a player's face encoding
  void registerPlayerFace(String playerId, List<double> faceEncoding) {
    final faceEncodingData = FaceEncodingData(
      encoding: faceEncoding,
      playerId: playerId,
      createdAt: DateTime.now(),
      confidence: 0.8,
    );
    
    _faceService.registerFace(faceEncodingData);
  }

  /// Register a player's face from current detection
  Future<bool> registerPlayerFaceFromDetection(String playerId, Face face, CameraImage cameraImage) async {
    return await _faceService.registerFaceFromDetection(face, cameraImage, playerId);
  }

  /// Remove a player's face encoding
  void removePlayerFace(String playerId) {
    _faceService.removeFace(playerId);
  }

  /// Clear all registered faces
  void clearRegisteredFaces() {
    _faceService.clearRegisteredFaces();
  }

  /// Get detection statistics
  DetectionStats getStats() {
    return DetectionStats(
      faceCount: _faceService.faceCount,
      poseCount: _poseService.poseCount,
      registeredPlayerCount: _faceService.registeredFaces.length,
      isDetecting: _isDetecting,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _detectionStreamController?.close();
      await _faceService.dispose();
      await _poseService.dispose();
      
      _detectionStreamController = null;
      _isInitialized = false;
      _referencePoses.clear();
      _poseToPlayerMap.clear();
      _faceToPlayerMap.clear();
    } catch (e) {
      print('Error disposing detection service: $e');
    }
  }
}

/// Result of detection processing
class DetectionResult {
  final List<Face> faces;
  final List<PoseData> poses;
  final Map<String, String> faceToPlayerMap;
  final Map<String, String> poseToPlayerMap;
  final DateTime timestamp;

  const DetectionResult({
    required this.faces,
    required this.poses,
    required this.faceToPlayerMap,
    required this.poseToPlayerMap,
    required this.timestamp,
  });

  /// Get identified players
  List<String> get identifiedPlayers {
    final players = <String>{};
    players.addAll(faceToPlayerMap.values);
    players.addAll(poseToPlayerMap.values);
    return players.toList();
  }

  @override
  String toString() {
    return 'DetectionResult(faces: ${faces.length}, poses: ${poses.length}, players: ${identifiedPlayers.length})';
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
