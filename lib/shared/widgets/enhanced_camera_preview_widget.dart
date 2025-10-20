import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/detection_service.dart';
import '../../core/constants/app_constants.dart';
import 'detection_overlay_widget.dart';

/// Enhanced camera preview widget with detection overlay
class EnhancedCameraPreviewWidget extends StatefulWidget {
  final VoidCallback? onCameraReady;
  final bool enableDetection;
  final bool showPoseLandmarks;
  final bool showFaceBoxes;
  final bool showMovementIndicators;
  final Function(DetectionResult)? onDetectionResult;
  final Function(CameraImage)? onCameraImage;

  const EnhancedCameraPreviewWidget({
    super.key,
    this.onCameraReady,
    this.enableDetection = true,
    this.showPoseLandmarks = true,
    this.showFaceBoxes = true,
    this.showMovementIndicators = true,
    this.onDetectionResult,
    this.onCameraImage,
  });

  @override
  State<EnhancedCameraPreviewWidget> createState() => _EnhancedCameraPreviewWidgetState();
}

class _EnhancedCameraPreviewWidgetState extends State<EnhancedCameraPreviewWidget> {
  final CameraService _cameraService = CameraService();
  final DetectionService _detectionService = DetectionService();
  
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  DetectionResult? _lastDetectionResult;
  Size _previewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      // Initialize camera service
      final cameraInitialized = await _cameraService.initialize();
      if (!cameraInitialized) {
        throw Exception('Failed to initialize camera');
      }

      // Initialize detection service
      final detectionInitialized = await _detectionService.initialize();
      if (!detectionInitialized) {
        throw Exception('Failed to initialize detection service');
      }

      // Start camera preview
      await _cameraService.startPreview();

      // Listen to camera image stream for detection
      if (widget.enableDetection) {
        _cameraService.imageStream?.listen(_processImageForDetection);
      }

      // Listen to detection results
      _detectionService.detectionStream?.listen(_onDetectionResult);

      widget.onCameraReady?.call();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _processImageForDetection(CameraImage image) {
    if (widget.enableDetection) {
      _detectionService.processImage(image);
      widget.onCameraImage?.call(image);
    }
  }

  void _onDetectionResult(DetectionResult result) {
    setState(() {
      _lastDetectionResult = result;
    });
    
    widget.onDetectionResult?.call(result);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.defaultPadding),
            Text('Initializing camera and detection...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: _initializeServices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final cameraPreview = _cameraService.getCameraPreview();
    if (cameraPreview == null) {
      return const Center(
        child: Text('Camera preview not available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _previewSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            // Camera preview
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                child: cameraPreview,
              ),
            ),
            
            // Detection overlay
            if (widget.enableDetection && _lastDetectionResult != null)
              Positioned.fill(
                child: DetectionOverlayWidget(
                  poses: _lastDetectionResult!.poses,
                  faces: _lastDetectionResult!.faces,
                  poseToPlayerMap: _lastDetectionResult!.poseToPlayerMap,
                  faceToPlayerMap: _lastDetectionResult!.faceToPlayerMap,
                  previewSize: _previewSize,
                  showPoseLandmarks: widget.showPoseLandmarks,
                  showFaceBoxes: widget.showFaceBoxes,
                  showMovementIndicators: widget.showMovementIndicators,
                ),
              ),
            
            // Detection info overlay
            if (widget.enableDetection)
              Positioned(
                top: AppConstants.defaultPadding,
                left: AppConstants.defaultPadding,
                right: AppConstants.defaultPadding,
                child: _buildDetectionInfo(),
              ),
            
            // Camera controls
            Positioned(
              bottom: AppConstants.defaultPadding,
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              child: _buildCameraControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetectionInfo() {
    final stats = _detectionService.getStats();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Status',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faces: ${stats.faceCount} | Poses: ${stats.poseCount}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Players: ${stats.registeredPlayerCount}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (stats.isDetecting)
            const Text(
              'Detecting...',
              style: TextStyle(color: Colors.green),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Detection toggle
          IconButton(
            onPressed: () {
              // Toggle detection
            },
            icon: Icon(
              widget.enableDetection ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            tooltip: widget.enableDetection ? 'Disable detection' : 'Enable detection',
          ),
          
          // Retry button
          IconButton(
            onPressed: _initializeServices,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Retry camera',
          ),
          
          // Stats button
          IconButton(
            onPressed: () {
              _showDetectionStats();
            },
            icon: const Icon(Icons.info, color: Colors.white),
            tooltip: 'Detection stats',
          ),
        ],
      ),
    );
  }

  void _showDetectionStats() {
    final stats = _detectionService.getStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detection Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faces Detected: ${stats.faceCount}'),
            Text('Poses Detected: ${stats.poseCount}'),
            Text('Registered Players: ${stats.registeredPlayerCount}'),
            Text('Detection Active: ${stats.isDetecting ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
