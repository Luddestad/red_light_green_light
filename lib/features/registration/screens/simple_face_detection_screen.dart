import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Simple face detection screen - minimal implementation
class SimpleFaceDetectionScreen extends StatefulWidget {
  const SimpleFaceDetectionScreen({super.key});

  @override
  State<SimpleFaceDetectionScreen> createState() => _SimpleFaceDetectionScreenState();
}

class _SimpleFaceDetectionScreenState extends State<SimpleFaceDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  int _faceCount = 0;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _status = 'No cameras available');
        return;
      }

      // Use front-facing camera
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      print('Using camera: ${frontCamera.name}, lens: ${frontCamera.lensDirection}');

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Use medium resolution
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Initialize face detector
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

      setState(() {
        _isInitialized = true;
        _status = 'Camera ready - Point at a face';
      });

      // Start image stream
      _cameraController!.startImageStream(_processCameraImage);

    } catch (e) {
      print('Camera initialization error: $e');
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_faceDetector == null) return;

    try {
      // Convert camera image to InputImage using the official method
      final inputImage = _cameraImageToInputImage(image);
      
      // Detect faces
      final faces = await _faceDetector!.processImage(inputImage);
      
      // Update UI with face count
      if (mounted) {
        setState(() {
          _faceCount = faces.length;
          _status = 'Detected ${faces.length} face(s)';
        });
      }

      // Log face detection results
      if (faces.isNotEmpty) {
        print('✅ Detected ${faces.length} faces');
        for (int i = 0; i < faces.length; i++) {
          final face = faces[i];
          print('Face $i: ${face.boundingBox}');
        }
      }

    } catch (e) {
      print('Face detection error: $e');
      if (mounted) {
        setState(() => _status = 'Detection error: $e');
      }
    }
  }

  /// Convert CameraImage to InputImage - simple approach without WriteBuffer
  InputImage _cameraImageToInputImage(CameraImage image) {
    // For YUV420 format, combine all planes into a single byte array
    final List<int> allBytes = [];
    
    for (final Plane plane in image.planes) {
      allBytes.addAll(plane.bytes);
    }
    
    final bytes = Uint8List.fromList(allBytes);

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(
      Platform.isAndroid ? 0 : 0, // Camera rotation
    ) ?? InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(
      image.format.raw,
    ) ?? InputImageFormat.yuv420;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Face Detection'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: _isInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          
          // Status and face count
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faces detected: $_faceCount',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}
