# Part 2 - Hint 3: processImage()

The key idea: **one frame at a time**. If we're already processing, skip the new frame.

```dart
Future<void> processImage(CameraImage image) async {
  if (isProcessing) return;  // Skip if busy

  isProcessing = true;
  try {
    // Feed the image to the ML model
    final pose = await poseDetectionService.detectPose(image);

    // Update the current pose
    if (pose != null) {
      await updatePoseDetection(pose);
    }
  } catch (e) {
    print('Detection error: $e');
  } finally {
    isProcessing = false;
    notifyListeners();  // Tell the UI to rebuild
  }
}
```

**Bonus challenge:** The ML model can sometimes be slow. Use `.timeout()` to skip
frames that take too long (check `maxFrameProcessingTime`). This keeps the overlay
responsive even under heavy load.
