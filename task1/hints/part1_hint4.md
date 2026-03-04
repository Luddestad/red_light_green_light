# Part 1 - Hint 4: Full Solution

```dart
Future<bool> initialize() async {
  try {
    await checkCameraPermissions();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    _imageStreamController = StreamController<CameraImage>.broadcast();

    _isInitialized = true;
    return true;
  } catch (e) {
    print('Camera initialization failed: $e');
    _isInitialized = false;
    return false;
  }
}
```
