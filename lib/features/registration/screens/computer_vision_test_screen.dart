import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../shared/widgets/enhanced_camera_preview_widget.dart';
import '../../../core/services/detection_service.dart';
import '../../../core/constants/app_constants.dart';

/// Test screen for computer vision functionality
class ComputerVisionTestScreen extends StatefulWidget {
  const ComputerVisionTestScreen({super.key});

  @override
  State<ComputerVisionTestScreen> createState() => _ComputerVisionTestScreenState();
}

class _ComputerVisionTestScreenState extends State<ComputerVisionTestScreen> {
  final DetectionService _detectionService = DetectionService();
  DetectionResult? _lastDetectionResult;
  List<String> _detectionLog = [];
  CameraImage? _lastCameraImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Computer Vision Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearLog,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview with detection overlay
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: EnhancedCameraPreviewWidget(
                enableDetection: true,
                showPoseLandmarks: true,
                showFaceBoxes: true,
                showMovementIndicators: true,
                onDetectionResult: _onDetectionResult,
                onCameraImage: (CameraImage image) {
                  _lastCameraImage = image;
                },
                onCameraReady: () {
                  _addToLog('Camera and detection services ready');
                  _addToLog('Using front-facing (selfie) camera');
                  _addToLog('Click the face button to register a face when detected');
                },
              ),
            ),
          ),
          
          // Detection results panel
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(AppConstants.defaultPadding),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics),
                      const SizedBox(width: 8),
                      const Text(
                        'Detection Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_detectionLog.length} entries',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Expanded(
                    child: _detectionLog.isEmpty
                        ? const Center(
                            child: Text(
                              'No detection results yet.\nMove in front of the camera to see pose landmarks and face detection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _detectionLog.length,
                            itemBuilder: (context, index) {
                              final entry = _detectionLog[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  entry,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Test face registration
          FloatingActionButton(
            onPressed: _testFaceRegistration,
            heroTag: 'face_registration',
            child: const Icon(Icons.face),
            tooltip: 'Test face registration',
          ),
          const SizedBox(height: 8),
          
          // Test movement detection
          FloatingActionButton(
            onPressed: _testMovementDetection,
            heroTag: 'movement_detection',
            child: const Icon(Icons.directions_run),
            tooltip: 'Test movement detection',
          ),
          const SizedBox(height: 8),
          
          // Clear detection data
          FloatingActionButton(
            onPressed: _clearDetectionData,
            heroTag: 'clear_data',
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
            tooltip: 'Clear detection data',
          ),
        ],
      ),
    );
  }

  void _onDetectionResult(DetectionResult result) {
    setState(() {
      _lastDetectionResult = result;
    });

    // Add to log
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] Faces: ${result.faces.length}, Poses: ${result.poses.length}, Players: ${result.identifiedPlayers.length}';
    
    _addToLog(logEntry);
    
    // Log detailed information
    if (result.faces.isNotEmpty) {
      _addToLog('  → Face boxes: ${result.faceToPlayerMap.length}');
    }
    
    if (result.poses.isNotEmpty) {
      _addToLog('  → Pose landmarks: ${result.poses.map((p) => p.landmarks.length).join(', ')}');
    }
  }

  void _addToLog(String entry) {
    setState(() {
      _detectionLog.add(entry);
      
      // Keep only last 50 entries
      if (_detectionLog.length > 50) {
        _detectionLog = _detectionLog.skip(_detectionLog.length - 50).toList();
      }
    });
  }

  void _clearLog() {
    setState(() {
      _detectionLog.clear();
    });
  }

  void _testFaceRegistration() async {
    // Register face from current detection
    if (_lastDetectionResult == null || _lastDetectionResult!.faces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No faces detected. Please position your face in the camera.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_lastCameraImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No camera image available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use the first detected face
    final face = _lastDetectionResult!.faces.first;
    final playerId = 'Player_${DateTime.now().millisecondsSinceEpoch}';
    
    final success = await _detectionService.registerPlayerFaceFromDetection(
      playerId, 
      face, 
      _lastCameraImage!
    );
    
    if (success) {
      _addToLog('✓ Registered face for: $playerId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face registered successfully as: $playerId'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _addToLog('✗ Failed to register face');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register face. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testMovementDetection() {
    if (_lastDetectionResult == null || _lastDetectionResult!.poses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No poses detected. Please move in front of the camera.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set current poses as reference
    _detectionService.setReferencePoses(
      _lastDetectionResult!.poses,
      _lastDetectionResult!.poseToPlayerMap,
    );
    
    _addToLog('Set reference poses for movement detection');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reference poses set. Move to test movement detection.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearDetectionData() {
    _detectionService.clearRegisteredFaces();
    setState(() {
      _lastDetectionResult = null;
    });
    _addToLog('Cleared all detection data');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detection data cleared'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
