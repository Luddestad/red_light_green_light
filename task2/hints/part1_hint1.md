# Part 1 - Hint 1: Understanding the ML Model Output

The ML model detects 33 body landmarks. Each landmark has:
- **x, y** — position in the image (pixels)
- **likelihood** — how confident the model is (0.0 to 1.0)

You need to implement 4 things in `lib/models/pose_landmark.dart`:

### TODO 1: `isValid`
The model isn't always sure about every landmark. A `likelihood` above 0.5 means
the model is at least 50% confident — that's our threshold for "trustworthy."

### TODO 2: `distanceTo()`
To measure how far a body part moved, use the 2D Euclidean distance formula:
`sqrt((x2-x1)² + (y2-y1)²)`

**Documentation:**
- `PoseLandmark` class: https://pub.dev/documentation/google_mlkit_pose_detection/latest/
- `dart:math` sqrt: https://api.dart.dev/stable/dart-math/sqrt.html
