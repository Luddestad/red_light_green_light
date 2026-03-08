# Hint 1: Understanding the ML Model Output

The ML model detects 33 body landmarks. Each landmark has:
- **x, y** — position in the image (pixels)
- **likelihood** — how confident the model is (0.0 to 1.0)

They're stored in a `Map<PoseLandmarkType, PoseLandmark>`, so you
access them like: `pose.landmarks[PoseLandmarkType.nose]`

### TODO 1: `getValidLandmark`

You need to:
1. Look up the landmark — this might return `null` if the type isn't in the map
2. Check if the model is confident enough (`likelihood > 0.5`)

```dart
PoseLandmark? getValidLandmark(Pose pose, PoseLandmarkType type) {
  final landmark = pose.landmarks[type];
  // Now check if it exists and is confident enough...
}
```

### Solution

```dart
PoseLandmark? getValidLandmark(Pose pose, PoseLandmarkType type) {
  final landmark = pose.landmarks[type];
  if (landmark != null && landmark.likelihood > 0.5) {
    return landmark;
  }
  return null;
}
```
