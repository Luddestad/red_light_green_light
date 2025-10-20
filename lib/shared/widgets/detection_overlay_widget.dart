import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../features/game/models/pose_landmark.dart';

/// Widget for overlaying detection results on camera preview
class DetectionOverlayWidget extends StatelessWidget {
  final List<PoseData> poses;
  final Map<String, String> poseToPlayerMap;
  final Size previewSize;
  final bool showPoseLandmarks;
  final bool showMovementIndicators;

  const DetectionOverlayWidget({
    super.key,
    required this.poses,
    required this.poseToPlayerMap,
    required this.previewSize,
    this.showPoseLandmarks = true,
    this.showMovementIndicators = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: DetectionOverlayPainter(
          poses: poses,
          poseToPlayerMap: poseToPlayerMap,
          previewSize: previewSize,
          showPoseLandmarks: showPoseLandmarks,
          showMovementIndicators: showMovementIndicators,
        ),
      size: Size.infinite,
    );
  }
}

/// Custom painter for detection overlay
class DetectionOverlayPainter extends CustomPainter {
  final List<PoseData> poses;
  final Map<String, String> poseToPlayerMap;
  final Size previewSize;
  final bool showPoseLandmarks;
  final bool showMovementIndicators;

  DetectionOverlayPainter({
    required this.poses,
    required this.poseToPlayerMap,
    required this.previewSize,
    required this.showPoseLandmarks,
    required this.showMovementIndicators,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showPoseLandmarks) {
      _drawPoseLandmarks(canvas, size);
    }

    if (showMovementIndicators) {
      _drawMovementIndicators(canvas, size);
    }
  }

  /// Draw pose landmarks and connections
  void _drawPoseLandmarks(Canvas canvas, Size size) {
    for (int i = 0; i < poses.length; i++) {
      final pose = poses[i];
      final playerId = poseToPlayerMap[i.toString()] ?? 'unknown_$i';
      final color = _getPlayerColor(playerId);

      // Draw landmarks
      for (final landmark in pose.landmarks) {
        if (landmark.isValid) {
          final point = _scalePoint(landmark.x, landmark.y, size);
          _drawLandmark(canvas, point, color, landmark.likelihood);
        }
      }

      // Draw connections between landmarks
      _drawPoseConnections(canvas, pose, size, color);
    }
  }

  /// Draw face detection boxes
  // Face boxes removed in single-player mode

  /// Draw movement indicators
  void _drawMovementIndicators(Canvas canvas, Size size) {
    // This would be implemented based on movement detection results
    // For now, we'll show a simple indicator
  }

  /// Draw individual landmark
  void _drawLandmark(Canvas canvas, Offset point, Color color, double confidence) {
    final paint = Paint()
      ..color = color.withOpacity(confidence)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 4.0, paint);

    // Draw confidence ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(point, 8.0, ringPaint);
  }

  /// Draw pose connections
  void _drawPoseConnections(Canvas canvas, PoseData pose, Size size, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2.0;

    // Define connections between landmarks
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder],
      [PoseLandmarkType.nose, PoseLandmarkType.rightShoulder],
    ];

    for (final connection in connections) {
      final landmark1 = pose.getLandmarkByType(connection[0]);
      final landmark2 = pose.getLandmarkByType(connection[1]);

      if (landmark1 != null && landmark2 != null && 
          landmark1.isValid && landmark2.isValid) {
        final point1 = _scalePoint(landmark1.x, landmark1.y, size);
        final point2 = _scalePoint(landmark2.x, landmark2.y, size);
        
        canvas.drawLine(point1, point2, paint);
      }
    }
  }

  // Face box drawing removed in single-player mode

  /// Scale point from normalized coordinates to screen coordinates
  Offset _scalePoint(double x, double y, Size size) {
    return Offset(
      x * size.width,
      y * size.height,
    );
  }

  /// Scale rectangle from normalized coordinates to screen coordinates


  /// Get color for player
  Color _getPlayerColor(String playerId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final hash = playerId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter oldDelegate) {
    return poses != oldDelegate.poses || poseToPlayerMap != oldDelegate.poseToPlayerMap;
  }
}
