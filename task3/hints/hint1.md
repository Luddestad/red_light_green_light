# Hint 1: Stability Tracking

A single frame of pose data isn't reliable. The model might briefly detect
a ghost pose, or lose track for one frame. We need *consecutive* good frames
before we trust that a real player is standing there.

### TODO 1: `updatePoseDetection()`

**When pose is null** — the model didn't find anyone:
```dart
if (pose == null) {
  isPlayerDetected = false;
  currentPose = null;
  stabilityFrames = 0;
  isPlayerStable = false;
  playerDetectionAnnounced = false;
  return;
}
```

**When pose is not null** — someone was detected:
1. Store the pose and mark detected
2. Count valid landmarks (likelihood > 0.5)
3. Increment or decrement the stability counter

```dart
currentPose = pose;
isPlayerDetected = true;

final validLandmarks = currentPose!.landmarks.values
    .where((l) => l.likelihood > 0.5)
    .length;

if (validLandmarks >= 5) {
  stabilityFrames++;
} else {
  stabilityFrames = math.max(0, stabilityFrames - 1);
}
```

4. Check if we've reached the stability threshold:
```dart
isPlayerStable = stabilityFrames >= settings.stabilityFramesRequired;
```

5. Handle announcements (this triggers lobby audio feedback):
```dart
await handleDetectionAnnouncement();
```

### Solution

```dart
Future<void> updatePoseDetection(Pose? pose) async {
  if (pose == null) {
    isPlayerDetected = false;
    currentPose = null;
    stabilityFrames = 0;
    isPlayerStable = false;
    playerDetectionAnnounced = false;
    return;
  }

  currentPose = pose;
  isPlayerDetected = true;

  final validLandmarks = currentPose!.landmarks.values
      .where((l) => l.likelihood > 0.5)
      .length;

  if (validLandmarks >= 5) {
    stabilityFrames++;
  } else {
    stabilityFrames = math.max(0, stabilityFrames - 1);
  }

  isPlayerStable = stabilityFrames >= settings.stabilityFramesRequired;

  await handleDetectionAnnouncement();
}
```
