# Part 2 - Hint 1: Movement Detection Overview

You need to implement 2 things in `lib/controllers/game_controller.dart`:

### TODO 1: `checkSimpleMovement(Pose current, Pose baseline)`
The algorithm:
1. Loop through each landmark type in `keyLandmarks` (nose, shoulders, elbows)
2. Get that landmark from both `current.landmarks[type]` and `baseline.landmarks[type]`
3. Check both exist and both have `likelihood > 0.5`
4. Calculate the 2D pixel distance: `sqrt((x2-x1)² + (y2-y1)²)`
5. If the distance exceeds `movementThreshold` (80 pixels), return `true`
6. If no landmark exceeded the threshold, return `false`

### TODO 2: Wire it into `processImage()`
After updating the pose, check if we have a baseline. If so, call
`checkSimpleMovement()` and store the result in `isMoving`.

**Documentation:**
- `Pose.landmarks`: `Map<PoseLandmarkType, PoseLandmark>` — access with `pose.landmarks[type]`
- `PoseLandmark`: has `.x`, `.y`, `.z`, `.likelihood` properties
- `dart:math`: `math.sqrt()`, `math.pow()`
