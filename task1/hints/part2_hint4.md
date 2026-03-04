# Part 2 - Hint 4: Full Solution

### `camera_service.dart` → `startPreview()`

```dart
Future<bool> startPreview() async {
  if (!_isInitialized || _controller == null) {
    return false;
  }

  try {
    await _controller!.startImageStream((CameraImage image) {
      _imageStreamController?.add(image);
    });
    return true;
  } catch (e) {
    print('Failed to start camera preview: $e');
    return false;
  }
}
```

### `game_controller.dart` → `initializeGame()`

```dart
Future<void> initializeGame() async {
  await cameraService.startPreview();
  cameraService.imageStream?.listen(processImage);
}
```

### `game_controller.dart` → `processImage()`

```dart
Future<void> processImage(CameraImage image) async {
  if (isProcessing) return;

  isProcessing = true;
  try {
    final pose = await poseDetectionService
        .detectFirstPose(image)
        .timeout(maxFrameProcessingTime, onTimeout: () => null);

    if (pose != null) {
      await updatePoseDetection(pose);
    }
  } catch (e) {
    print('Detection error: $e');
  } finally {
    isProcessing = false;
    notifyListeners();
  }
}
```
