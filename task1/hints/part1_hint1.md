# Part 1 - Hint 1: Camera Initialization Overview

You need to fill in the TODO sections in `initialize()`. The structure is already there — you just need to:

1. Get the available cameras on the device
2. Pick the front-facing one
3. Create the stream controller for sharing camera frames
4. Mark the service as initialized

**Useful classes/functions to look up:**
- `availableCameras()` (from the `camera` package) — returns a `List<CameraDescription>`
- `CameraLensDirection.front`
- `StreamController<CameraImage>.broadcast()`
