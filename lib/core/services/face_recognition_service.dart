import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import '../../core/constants/detection_constants.dart';
import '../../features/registration/models/face_encoding_model.dart';

/// Service for face detection and recognition
class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  FaceDetector? _faceDetector;
  List<FaceEncodingData> _registeredFaces = [];
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  List<FaceEncodingData> get registeredFaces => List.unmodifiable(_registeredFaces);

  /// Initialize the face detection service
  Future<bool> initialize() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
          minFaceSize: 0.1,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Face detection initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Detect faces in camera image
  Future<List<Face>> detectFaces(CameraImage cameraImage) async {
    if (!_isInitialized || _faceDetector == null) {
      return [];
    }

    try {
      // Convert CameraImage to InputImage
      final inputImage = _cameraImageToInputImage(cameraImage);
      print('Processing face detection for image: ${cameraImage.width}x${cameraImage.height}, format: ${cameraImage.format.raw}');
      
      // Detect faces
      final faces = await _faceDetector!.processImage(inputImage);
      print('Raw face detection found ${faces.length} faces');
      
      // Return all detected faces without filtering
      print('Returning ${faces.length} faces for processing');
      return faces;
    } catch (e) {
      print('Face detection error: $e');
      return [];
    }
  }

  /// Register a face encoding for a player
  void registerFace(FaceEncodingData faceEncoding) {
    _registeredFaces.add(faceEncoding);
  }

  /// Register a face from a detected face and camera image
  Future<bool> registerFaceFromDetection(Face face, CameraImage cameraImage, String playerId) async {
    try {
      final faceEncoding = await _generateFaceEncoding(face, cameraImage);
      if (faceEncoding == null) {
        return false;
      }

      // Set the player ID
      final registeredFace = FaceEncodingData(
        encoding: faceEncoding.encoding,
        playerId: playerId,
        createdAt: faceEncoding.createdAt,
        confidence: faceEncoding.confidence,
      );

      _registeredFaces.add(registeredFace);
      print('Registered face for player: $playerId');
      return true;
    } catch (e) {
      print('Face registration error: $e');
      return false;
    }
  }

  /// Remove face encoding for a player
  void removeFace(String playerId) {
    _registeredFaces.removeWhere((face) => face.playerId == playerId);
  }

  /// Identify player from face detection
  Future<String?> identifyPlayer(Face face, CameraImage cameraImage) async {
    if (_registeredFaces.isEmpty) return null;

    try {
      // Generate face encoding for the detected face
      final faceEncoding = await _generateFaceEncoding(face, cameraImage);
      if (faceEncoding == null) return null;

      // Find best match
      FaceEncodingData? bestMatch;
      double bestSimilarity = 0.0;

      for (final registeredFace in _registeredFaces) {
        final similarity = faceEncoding.similarityTo(registeredFace);
        if (similarity > bestSimilarity && similarity >= DetectionConstants.faceRecognitionThreshold) {
          bestSimilarity = similarity;
          bestMatch = registeredFace;
        }
      }

      return bestMatch?.playerId;
    } catch (e) {
      print('Face identification error: $e');
      return null;
    }
  }

  /// Generate face encoding from detected face
  Future<FaceEncodingData?> _generateFaceEncoding(Face face, CameraImage cameraImage) async {
    try {
      // Create a more robust face encoding based on face features
      final boundingBox = face.boundingBox;
      final encoding = <double>[
        // Normalized position and size
        boundingBox.left / cameraImage.width,
        boundingBox.top / cameraImage.height,
        boundingBox.width / cameraImage.width,
        boundingBox.height / cameraImage.height,
        
        // Face angles (normalized)
        (face.headEulerAngleY ?? 0.0) / 90.0, // Normalize to -1 to 1
        (face.headEulerAngleZ ?? 0.0) / 90.0, // Normalize to -1 to 1
        
        // Face landmarks if available
        (face.landmarks[FaceLandmarkType.leftEye]?.position.x ?? 0.0).toDouble(),
        (face.landmarks[FaceLandmarkType.leftEye]?.position.y ?? 0.0).toDouble(),
        (face.landmarks[FaceLandmarkType.rightEye]?.position.x ?? 0.0).toDouble(),
        (face.landmarks[FaceLandmarkType.rightEye]?.position.y ?? 0.0).toDouble(),
        (face.landmarks[FaceLandmarkType.noseBase]?.position.x ?? 0.0).toDouble(),
        (face.landmarks[FaceLandmarkType.noseBase]?.position.y ?? 0.0).toDouble(),
        
        // Additional features
        face.boundingBox.width / face.boundingBox.height, // Aspect ratio
        face.headEulerAngleX ?? 0.0, // Additional angle
      ];

      return FaceEncodingData(
        encoding: encoding,
        playerId: '', // Will be set when registering
        createdAt: DateTime.now(),
        confidence: 0.9, // Higher confidence for better matching
      );
    } catch (e) {
      print('Face encoding generation error: $e');
      return null;
    }
  }

  /// Convert CameraImage to InputImage - force NV21 format
  InputImage _cameraImageToInputImage(CameraImage cameraImage) {
    final plane = cameraImage.planes.first;
    
    print('Camera format: ${cameraImage.format.raw}, size: ${cameraImage.width}x${cameraImage.height}');
    print('Converting to NV21 format for ML Kit');
    
    // Force NV21 format - ML Kit's most compatible format
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21, // Always use NV21
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Clear all registered faces
  void clearRegisteredFaces() {
    _registeredFaces.clear();
  }

  /// Get face count
  int get faceCount => _registeredFaces.length;

  /// Check if player is registered
  bool isPlayerRegistered(String playerId) {
    return _registeredFaces.any((face) => face.playerId == playerId);
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _faceDetector?.close();
      _faceDetector = null;
      _isInitialized = false;
    } catch (e) {
      print('Error disposing face detector: $e');
    }
  }

  /// Convert YUV420 to NV21 bytes
  Uint8List _convertYUV420ToNV21(
    Uint8List yBytes,
    Uint8List uBytes,
    Uint8List vBytes,
    int width,
    int height,
    int yRowStride,
    int uRowStride,
    int vRowStride,
  ) {
    // NV21 format: Y plane followed by interleaved VU plane
    final nv21Bytes = Uint8List(width * height + (width * height ~/ 2));
    
    // Copy Y plane
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final nv21Index = y * width + x;
        nv21Bytes[nv21Index] = yBytes[yIndex];
      }
    }
    
    // Copy UV plane (interleaved as VU in NV21)
    final uvOffset = width * height;
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uIndex = y * uRowStride + x;
        final vIndex = y * vRowStride + x;
        final nv21Index = uvOffset + (y * width + x * 2);
        
        nv21Bytes[nv21Index] = vBytes[vIndex];     // V first
        nv21Bytes[nv21Index + 1] = uBytes[uIndex];  // U second
      }
    }
    
    return nv21Bytes;
  }
}
