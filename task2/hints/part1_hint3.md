# Part 1 - Hint 3: Near-Complete Solution

### TODO 3: `PoseData.fromPose()`
```dart
factory PoseData.fromPose(Pose pose) {
  final landmarks = pose.landmarks.values
      .map((landmark) => PoseLandmarkData.fromPoseLandmark(landmark))
      .toList();

  return PoseData(landmarks: landmarks, timestamp: DateTime.now());
}
```

### TODO 4: `getLandmarkByType()`
```dart
PoseLandmarkData? getLandmarkByType(PoseLandmarkType type) {
  try {
    return landmarks.firstWhere((landmark) => landmark.type == type);
  } catch (e) {
    return null;
  }
}
```
