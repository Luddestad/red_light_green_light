import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Represents a single body landmark detected by ML Kit.
///
/// ML Kit's pose detection returns 33 landmarks (nose, shoulders, elbows,
/// wrists, hips, knees, ankles, etc.) Each landmark has:
/// - x, y: position in the image (pixels)
/// - z: relative depth estimate
/// - likelihood: confidence score from 0.0 to 1.0
class PoseLandmarkData {
  final PoseLandmarkType type;
  final double x;
  final double y;
  final double z;
  final double likelihood;

  const PoseLandmarkData({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });

  /// Create from Google ML Kit PoseLandmark
  factory PoseLandmarkData.fromPoseLandmark(PoseLandmark landmark) {
    return PoseLandmarkData(
      type: landmark.type,
      x: landmark.x,
      y: landmark.y,
      z: landmark.z,
      likelihood: landmark.likelihood,
    );
  }

  /// TODO 1: Check if this landmark is reliable enough to use.
  ///
  /// The model outputs a "likelihood" between 0.0 and 1.0 — this is
  /// the model's confidence that it correctly identified this body part.
  /// A landmark with likelihood > 0.5 is generally trustworthy.
  ///
  /// Return true if likelihood is greater than 0.5.
  ///
  /// See hints/part1_hint1.md if you get stuck!
  bool get isValid {
    // YOUR CODE HERE
    throw UnimplementedError('Implement isValid');
  }

  /// TODO 2: Calculate the pixel distance between this landmark and another.
  ///
  /// Use the standard 2D distance formula: sqrt((x2-x1)² + (y2-y1)²)
  /// The x and y values are in image pixel coordinates.
  ///
  /// This is how we measure "how far did this body part move?"
  ///
  /// Docs:
  /// - dart:math sqrt: https://api.dart.dev/stable/dart-math/sqrt.html
  ///
  /// See hints/part1_hint1.md if you get stuck!
  double distanceTo(PoseLandmarkData other) {
    // YOUR CODE HERE
    throw UnimplementedError('Implement distanceTo');
  }

  @override
  String toString() {
    return 'PoseLandmarkData(type: $type, x: ${x.toStringAsFixed(1)}, '
        'y: ${y.toStringAsFixed(1)}, likelihood: ${likelihood.toStringAsFixed(2)})';
  }
}

/// Represents a complete pose with all landmarks from one frame.
class PoseData {
  final List<PoseLandmarkData> landmarks;
  final DateTime timestamp;

  const PoseData({required this.landmarks, required this.timestamp});

  /// TODO 3: Create a PoseData from ML Kit's raw Pose object.
  ///
  /// The Pose object has a `landmarks` map: Map<PoseLandmarkType, PoseLandmark>
  /// You need to:
  /// 1. Convert each PoseLandmark to our PoseLandmarkData using the factory above
  /// 2. Store them as a list
  /// 3. Record the current timestamp
  ///
  /// Hint: Use pose.landmarks.values.map(...).toList()
  ///
  /// See hints/part1_hint2.md if you get stuck!
  factory PoseData.fromPose(Pose pose) {
    // YOUR CODE HERE
    throw UnimplementedError('Implement PoseData.fromPose');
  }

  /// TODO 4: Look up a specific landmark by its type.
  ///
  /// For example: getLandmarkByType(PoseLandmarkType.nose)
  /// Return null if not found.
  ///
  /// Hint: Use landmarks.firstWhere() with a try/catch for safety.
  ///
  /// See hints/part1_hint2.md if you get stuck!
  PoseLandmarkData? getLandmarkByType(PoseLandmarkType type) {
    // YOUR CODE HERE
    throw UnimplementedError('Implement getLandmarkByType');
  }

  @override
  String toString() {
    return 'PoseData(landmarks: ${landmarks.length}, timestamp: $timestamp)';
  }
}
