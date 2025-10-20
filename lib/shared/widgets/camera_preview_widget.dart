import 'package:flutter/material.dart';
import '../../core/services/camera_service.dart';
import '../../core/constants/app_constants.dart';

/// Widget for displaying camera preview
class CameraPreviewWidget extends StatefulWidget {
  final VoidCallback? onCameraReady;
  final Widget? overlay;
  final bool showControls;
  final double? aspectRatio;

  const CameraPreviewWidget({
    super.key,
    this.onCameraReady,
    this.overlay,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  final CameraService _cameraService = CameraService();
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      final success = await _cameraService.initialize();
      
      if (success) {
        await _cameraService.startPreview();
        widget.onCameraReady?.call();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = AppConstants.cameraInitializationFailed;
        });
      }
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

  @override
  void dispose() {
    _cameraService.dispose();
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
            Text('Initializing camera...'),
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
              _errorMessage ?? AppConstants.unknownError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton(
              onPressed: _initializeCamera,
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

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            child: cameraPreview,
          ),
        ),
        
        // Overlay (for face detection boxes, etc.)
        if (widget.overlay != null)
          Positioned.fill(child: widget.overlay!),
        
        // Camera controls
        if (widget.showControls)
          Positioned(
            bottom: AppConstants.defaultPadding,
            left: AppConstants.defaultPadding,
            right: AppConstants.defaultPadding,
            child: _buildCameraControls(),
          ),
      ],
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
          // Camera info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera Ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Position yourself in the frame',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Retry button
          IconButton(
            onPressed: _initializeCamera,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Retry camera',
          ),
        ],
      ),
    );
  }
}
