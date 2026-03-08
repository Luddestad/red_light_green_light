# Hint 3: Wiring It Together

### TODO 3: Check for movement in `processImage()`

After the pose is updated, check if we have both a current pose and
a baseline. If so, call `checkSimpleMovement()` and store the result.

### Solution

Add this after the `updatePoseDetection` call in `processImage()`:

```dart
if (baselinePose != null && currentPose != null) {
  isMoving = checkSimpleMovement(currentPose!, baselinePose!);
}
```
