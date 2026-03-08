# Hint 2: Movement Detection

Now that you can get a reliable landmark, use it to detect movement.

### TODO 2: `checkSimpleMovement`

The idea: loop through key body parts, get the same landmark from both
the current pose and the baseline, and check if it moved too far.

**Step 1 — The loop structure:**

```dart
bool checkSimpleMovement(Pose current, Pose baseline) {
  for (final type in keyLandmarks) {
    final currentLM = getValidLandmark(current, type);
    final baselineLM = getValidLandmark(baseline, type);

    if (currentLM != null && baselineLM != null) {
      // Calculate distance and compare to movementThreshold...
    }
  }

  return false;
}
```

**Step 2 — The distance formula:**

2D Euclidean distance: `sqrt((x2-x1)² + (y2-y1)²)`

In Dart: `math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2))`

### Solution

```dart
bool checkSimpleMovement(Pose current, Pose baseline) {
  for (final type in keyLandmarks) {
    final currentLM = getValidLandmark(current, type);
    final baselineLM = getValidLandmark(baseline, type);

    if (currentLM != null && baselineLM != null) {
      final distance = math.sqrt(
        math.pow(currentLM.x - baselineLM.x, 2) +
            math.pow(currentLM.y - baselineLM.y, 2),
      );

      if (distance > movementThreshold) {
        print(
          'Movement at ${type.toString().split('.').last}: ${distance.toStringAsFixed(1)}px',
        );
        return true;
      }
    }
  }

  return false;
}
```
