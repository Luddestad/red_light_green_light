import 'package:flutter/material.dart';
import '../../../shared/widgets/camera_preview_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Test screen for camera functionality
class CameraTestScreen extends StatelessWidget {
  const CameraTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Text(
              'Camera Preview Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.defaultPadding),
            Expanded(
              child: CameraPreviewWidget(
                showControls: true,
              ),
            ),
            SizedBox(height: AppConstants.defaultPadding),
            Text(
              'If you can see the camera preview above, the camera service is working correctly!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
