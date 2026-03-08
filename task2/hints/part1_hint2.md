# Part 1 - Hint 2: isValid, distanceTo, fromPose, getLandmarkByType

### TODO 1: `isValid`
```dart
bool get isValid => likelihood > 0.5;
```

### TODO 2: `distanceTo()`
```dart
double distanceTo(PoseLandmarkData other) {
  final dx = x - other.x;
  final dy = y - other.y;
  return sqrt(dx * dx + dy * dy);
}
```

### TODO 3: `PoseData.fromPose()`
The `Pose` object from ML Kit has a `.landmarks` map. You need to convert each
value to our `PoseLandmarkData` type:

```dart
pose.landmarks.values.map((l) => PoseLandmarkData.fromPoseLandmark(l)).toList()
```

Then wrap it in a `PoseData(landmarks: ..., timestamp: DateTime.now())`.

### TODO 4: `getLandmarkByType()`
Use `firstWhere` to find a landmark by type. Wrap in try/catch to return null
if not found.
