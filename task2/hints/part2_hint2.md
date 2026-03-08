# Part 2 - Hint 2: checkSimpleMovement Structure

### TODO 1: The for-loop structure

```dart
bool checkSimpleMovement(Pose current, Pose baseline) {
  for (final type in keyLandmarks) {
    final currentLM = current.landmarks[type];
    final baselineLM = baseline.landmarks[type];

    if (currentLM != null && baselineLM != null &&
        currentLM.likelihood > 0.5 && baselineLM.likelihood > 0.5) {
      // Calculate distance between currentLM and baselineLM
      // If distance > movementThreshold, return true
    }
  }

  return false;
}
```

### TODO 2: The wiring

```dart
if (baselinePose != null && currentPose != null) {
  isMoving = checkSimpleMovement(currentPose!, baselinePose!);
}
```
