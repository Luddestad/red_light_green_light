# Part 1 - Hint 1: Camera Initialization Overview

You need to fill in the TODO sections in `initialize()`. The structure is already there — you just need to:

1. Get the available cameras on the device
2. Pick the front-facing one
3. Create the stream controller for sharing camera frames
4. Mark the service as initialized

**Useful classes/functions to look up:**
- `availableCameras()` — returns a `List<CameraDescription>`
- `CameraLensDirection.front`
- `StreamController<CameraImage>.broadcast()`

**Documentation:**
- Camera package overview: https://pub.dev/packages/camera
- `availableCameras()`: https://pub.dev/documentation/camera/latest/camera/availableCameras.html
- `CameraDescription`: https://pub.dev/documentation/camera/latest/camera/CameraDescription-class.html
- `StreamController`: https://api.dart.dev/stable/dart-async/StreamController-class.html
