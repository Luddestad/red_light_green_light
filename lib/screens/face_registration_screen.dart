import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Face Registration Screen - Register players with their faces
class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  List<Face> _detectedFaces = [];
  final TextEditingController _nameController = TextEditingController();
  
  // Registered players
  final List<RegisteredPlayer> _registeredPlayers = [];
  
  // Throttling variables
  int _frameCount = 0;
  bool _isProcessing = false;
  
  // Face stability variables
  List<Face> _lastDetectedFaces = [];
  int _consecutiveNoFaceCount = 0;
  int _consecutiveFaceCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera with NV21 format for ML Kit compatibility
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Force NV21 format
      );

      await _cameraController!.initialize();

      // Initialize face detector with optimized settings for stability
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false, // Disable to reduce noise
          enableClassification: false,
          enableTracking: true, // Enable tracking for stability
          minFaceSize: 0.15, // Increase minimum size to reduce false positives
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      setState(() => _isInitialized = true);

      // Start processing
      _cameraController!.startImageStream(_processImage);

    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_faceDetector == null || _isProcessing) return;

    // Throttle to every 20th frame for more stability
    _frameCount++;
    if (_frameCount % 20 != 0) return;

    _isProcessing = true;

    try {
      // Create InputImage following official docs approach
      final inputImage = _createInputImageFromCamera(image);
      
      // Detect faces
      final rawFaces = await _faceDetector!.processImage(inputImage);
      
      // Apply stability filtering
      final stabilizedFaces = _applyStabilityFilter(rawFaces);
      
      // Update UI only if faces changed significantly
      if (mounted && _shouldUpdateUI(stabilizedFaces)) {
        setState(() {
          _detectedFaces = stabilizedFaces;
        });
        
        // Debug logging
        if (stabilizedFaces.isNotEmpty) {
          print('✅ Stable face detection: ${stabilizedFaces.length} faces');
        }
      }

    } catch (e) {
      print('Face detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Apply stability filtering to reduce flickering
  List<Face> _applyStabilityFilter(List<Face> rawFaces) {
    // Filter out very small faces (likely false positives)
    final filteredFaces = rawFaces.where((face) {
      final boundingBox = face.boundingBox;
      final faceArea = boundingBox.width * boundingBox.height;
      return faceArea > 5000; // Minimum face area threshold
    }).toList();
    
    // Remove faces that are too close together (likely duplicates)
    final deduplicatedFaces = _removeDuplicateFaces(filteredFaces);
    
    return deduplicatedFaces;
  }
  
  /// Remove duplicate faces that are too close together
  List<Face> _removeDuplicateFaces(List<Face> faces) {
    if (faces.length <= 1) return faces;
    
    final result = <Face>[];
    
    for (final face in faces) {
      bool isDuplicate = false;
      
      for (final existingFace in result) {
        final distance = _calculateFaceDistance(face.boundingBox, existingFace.boundingBox);
        if (distance < 100) { // Minimum distance threshold
          isDuplicate = true;
          break;
        }
      }
      
      if (!isDuplicate) {
        result.add(face);
      }
    }
    
    return result;
  }
  
  /// Calculate distance between two face bounding boxes
  double _calculateFaceDistance(Rect face1, Rect face2) {
    final center1 = face1.center;
    final center2 = face2.center;
    final dx = center1.dx - center2.dx;
    final dy = center1.dy - center2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Check if UI should be updated (reduce unnecessary updates)
  bool _shouldUpdateUI(List<Face> newFaces) {
    // If face count changed significantly, update
    if ((newFaces.length - _detectedFaces.length).abs() > 0) {
      return true;
    }
    
    // If no faces for multiple consecutive frames, update
    if (newFaces.isEmpty) {
      _consecutiveNoFaceCount++;
      return _consecutiveNoFaceCount == 3; // Update after 3 consecutive no-face detections
    } else {
      _consecutiveNoFaceCount = 0;
      _consecutiveFaceCount++;
      return _consecutiveFaceCount == 2; // Update after 2 consecutive face detections
    }
  }

  /// Create InputImage from CameraImage - force NV21 format
  InputImage _createInputImageFromCamera(CameraImage image) {
    final plane = image.planes.first;
    
    // Only log occasionally to reduce spam
    if (_frameCount % 100 == 0) {
      print('Camera format: ${image.format.raw}, size: ${image.width}x${image.height}');
      print('Using NV21 format for ML Kit');
    }
    
    // Force NV21 format regardless of camera format
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21, // Always use NV21
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _registerCurrentFace() async {
    if (_detectedFaces.isEmpty) {
      _showSnackBar('No face detected. Please position your face in view.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a name.');
      return;
    }

    final face = _detectedFaces.first;
    final player = RegisteredPlayer(
      name: _nameController.text.trim(),
      boundingBox: face.boundingBox,
      landmarks: face.landmarks,
      trackingId: face.trackingId,
      registeredAt: DateTime.now(),
    );

    setState(() {
      _registeredPlayers.add(player);
      _nameController.clear();
    });

    _showSnackBar('${player.name} registered successfully!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Registration'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera preview with face overlay
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Camera preview
                _isInitialized && _cameraController != null
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
                
                // Face detection overlay
                if (_isInitialized) _buildFaceOverlay(),
              ],
            ),
          ),
          
          // Registration controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Name input
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Register button
                ElevatedButton.icon(
                  onPressed: _detectedFaces.isNotEmpty ? _registerCurrentFace : null,
                  icon: const Icon(Icons.face),
                  label: Text('Register ${_detectedFaces.length} Face(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Registered players count
                Text(
                  'Registered Players: ${_registeredPlayers.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Registered players list
          if (_registeredPlayers.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _registeredPlayers.length,
                itemBuilder: (context, index) {
                  final player = _registeredPlayers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(player.name[0].toUpperCase()),
                    ),
                    title: Text(player.name),
                    subtitle: Text('Registered at ${player.registeredAt.toString().substring(11, 19)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _registeredPlayers.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _registeredPlayers.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to game screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RedLightGreenLightGame(
                      registeredPlayers: _registeredPlayers,
                    ),
                  ),
                );
              },
              label: const Text('Start Game'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildFaceOverlay() {
    return CustomPaint(
      painter: FaceDetectionPainter(
        faces: _detectedFaces,
        imageSize: _cameraController != null
            ? Size(
                _cameraController!.value.previewSize!.height,
                _cameraController!.value.previewSize!.width,
              )
            : Size.zero,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    _nameController.dispose();
    super.dispose();
  }
}

/// Registered Player Model
class RegisteredPlayer {
  final String name;
  final Rect boundingBox;
  final Map<FaceLandmarkType, FaceLandmark?> landmarks;
  final int? trackingId;
  final DateTime registeredAt;

  RegisteredPlayer({
    required this.name,
    required this.boundingBox,
    required this.landmarks,
    this.trackingId,
    required this.registeredAt,
  });
}

/// Face Detection Painter
class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;

  FaceDetectionPainter({required this.faces, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final Paint landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue;

    for (final Face face in faces) {
      // Draw bounding box
      final Rect boundingBox = _scaleRect(face.boundingBox, size, imageSize);
      canvas.drawRect(boundingBox, paint);

      // Draw landmarks
      for (final FaceLandmark? landmark in face.landmarks.values) {
        if (landmark != null) {
          final Offset point = _scalePoint(landmark.position, size, imageSize);
          canvas.drawCircle(point, 3, landmarkPaint);
        }
      }
    }
  }

  Rect _scaleRect(Rect rect, Size canvasSize, Size imageSize) {
    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  Offset _scalePoint(math.Point<int> point, Size canvasSize, Size imageSize) {
    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;

    return Offset(point.x * scaleX, point.y * scaleY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Placeholder for the game screen
class RedLightGreenLightGame extends StatelessWidget {
  final List<RegisteredPlayer> registeredPlayers;

  const RedLightGreenLightGame({super.key, required this.registeredPlayers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Light Green Light'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Game Starting Soon!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Players: ${registeredPlayers.map((p) => p.name).join(', ')}'),
          ],
        ),
      ),
    );
  }
}
