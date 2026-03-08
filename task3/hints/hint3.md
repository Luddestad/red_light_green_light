# Hint 3: Movement Violation Checking

This method is called every frame during red light. Before comparing poses,
you need to check several guard conditions — otherwise you'd crash or
get false positives.

### TODO 3: `checkForMovementViolations()`

**Guard conditions (return early if any fail):**

```dart
// Must be in red light phase
if (gameSession.currentState != GameState.redLight) return;

// Don't double-eliminate
if (gameSession.isGameOver || isPlayerMoving) return;

// Need valid data to compare
if (!isPlayerStable || baselinePose == null || currentPose == null) return;
```

**Movement check:**
```dart
final moved = checkSimpleMovement(currentPose!, baselinePose!);

if (moved) {
  isPlayerMoving = true;
  await endGame();
}
```

### Solution

```dart
Future<void> checkForMovementViolations() async {
  if (gameSession.currentState != GameState.redLight) {
    return;
  }

  if (gameSession.isGameOver || isPlayerMoving) {
    return;
  }

  if (!isPlayerStable || baselinePose == null || currentPose == null) {
    return;
  }

  final moved = checkSimpleMovement(currentPose!, baselinePose!);

  if (moved) {
    isPlayerMoving = true;
    await endGame();
  }
}
```
