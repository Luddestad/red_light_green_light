# Part 1 - Hint 2: Getting and Selecting Cameras

To get the list of cameras:

```dart
_cameras = await availableCameras();
if (_cameras.isEmpty) {
  throw Exception('No cameras available');
}
```

To pick the front camera, use `firstWhere` on the list:

```dart
final camera = _cameras.firstWhere(
  (camera) => camera.lensDirection == CameraLensDirection.front,
  orElse: () => _cameras.first, // Fallback if no front camera
);
```

This `camera` variable is then used by the `CameraController` below it.
