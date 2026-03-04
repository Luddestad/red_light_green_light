# Part 2 - Hint 1: Overview of the Camera → ML Pipeline

You need to implement **three methods** across two files:

### `camera_service.dart` → `startPreview()`
- Start the camera's image stream
- Forward each frame to `_imageStreamController` so other parts of the app can listen

### `game_controller.dart` → `initializeGame()`
- Start the camera preview (using `cameraService`)
- Listen to the image stream and call `processImage` for each frame

### `game_controller.dart` → `processImage(CameraImage image)`
- Feed the camera frame to the ML model
- Update `currentPose` with the result
- Notify the UI to rebuild

**The data flow is:** Camera → Stream → GameController → PoseDetectionService → UI

**Documentation:**
- `startImageStream()`: https://pub.dev/documentation/camera/latest/camera/CameraController/startImageStream.html
- `Stream.listen()`: https://api.dart.dev/stable/dart-async/Stream/listen.html
- `Future.timeout()`: https://api.dart.dev/stable/dart-async/Future/timeout.html
- Look at `pose_detection_service.dart` to see what methods are available (e.g. `detectFirstPose()`)
