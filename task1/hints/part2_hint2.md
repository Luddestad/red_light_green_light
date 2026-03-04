# Part 2 - Hint 2: startPreview() and initializeGame()

### `startPreview()` in camera_service.dart

Use `_controller!.startImageStream()` — it gives you a callback with each `CameraImage`:

```dart
await _controller!.startImageStream((CameraImage image) {
  // Forward the image to the stream controller
});
```

Remember to check `_isInitialized` and `_controller != null` first.

### `initializeGame()` in game_controller.dart

```dart
await cameraService.startPreview();
cameraService.imageStream?.listen(processImage);
```

That's it! The camera service produces frames, and we pipe them into `processImage`.
