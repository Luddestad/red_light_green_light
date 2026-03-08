# Hint 2: Baseline Capture with Grace Period

When the game switches to red light, the player needs time to react and
freeze. If we capture the baseline immediately, we'd compare against their
*mid-movement* pose — and they'd be eliminated instantly. That's not fair!

The grace period (400ms by default) gives the player time to hear "Red light!"
and stop moving before we save their freeze position.

### TODO 2: `switchToRedLight()`

The state transition is already done for you. You need to add:

**Step 1 — Announce red light (with error handling):**
```dart
try {
  await audioService.announceRedLight(GameConstants.redLightMessage);
} catch (e) {
  // Continue anyway - don't let audio issues break the game
}
```

**Step 2 — Wait for the player to freeze:**
```dart
await Future.delayed(
  Duration(milliseconds: settings.redLightFreezeGraceMs),
);
```

**Step 3 — Capture the baseline if the player is ready:**
```dart
if (isPlayerStable && currentPose != null) {
  baselinePose = currentPose;
  isPlayerMoving = false;
}
```

### Solution

Add this after the `notifyListeners()` call (replacing the throw):

```dart
try {
  await audioService.announceRedLight(GameConstants.redLightMessage);
} catch (e) {
  // Continue anyway
}

await Future.delayed(
  Duration(milliseconds: settings.redLightFreezeGraceMs),
);

if (isPlayerStable && currentPose != null) {
  baselinePose = currentPose;
  isPlayerMoving = false;
}
```
