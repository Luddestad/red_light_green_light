# Part 2 - Hint 3: Near-Complete Solution

### TODO 1: `checkSimpleMovement`

```dart
bool checkSimpleMovement(Pose current, Pose baseline) {
  for (final type in keyLandmarks) {
    final currentLM = current.landmarks[type];
    final baselineLM = baseline.landmarks[type];

    if (currentLM != null &&
        baselineLM != null &&
        currentLM.likelihood > 0.5 &&
        baselineLM.likelihood > 0.5) {
      final distance = math.sqrt(
        math.pow(currentLM.x - baselineLM.x, 2) +
            math.pow(currentLM.y - baselineLM.y, 2),
      );

      if (distance > movementThreshold) {
        return true;
      }
    }
  }

  return false;
}
```

### TODO 2: Add this after the `updatePoseDetection` call in `processImage()`

```dart
if (baselinePose != null && currentPose != null) {
  isMoving = checkSimpleMovement(currentPose!, baselinePose!);
}
```
