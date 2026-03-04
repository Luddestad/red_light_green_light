# Part 1 - Hint 3: Stream Controller and Finishing Up

After the controller is initialized, you need to create a broadcast stream so that
other parts of the app (like the game controller) can receive camera frames:

```dart
_imageStreamController = StreamController<CameraImage>.broadcast();
```

Then mark the service as ready:

```dart
_isInitialized = true;
return true;
```
