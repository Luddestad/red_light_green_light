import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Widget that overlays pose detection visualization on the camera
class MovementOverlayWidget extends StatelessWidget {
  final List<Pose> poses;
  final Size cameraSize;

  const MovementOverlayWidget({
    super.key,
    required this.poses,
    required this.cameraSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PoseOverlayPainter(
        poses: poses,
        cameraSize: cameraSize,
      ),
    );
  }
}

/// Custom painter for drawing pose landmarks and connections
class PoseOverlayPainter extends CustomPainter {
  final List<Pose> poses;
  final Size cameraSize;

  PoseOverlayPainter({
    required this.poses,
    required this.cameraSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty || cameraSize == Size.zero) return;

    final Paint posePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 3.0;

    final Paint connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Colors for different positions
    final List<Color> playerColors = [
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ];

    for (int i = 0; i < poses.length && i < 4; i++) {
      final pose = poses[i];
      final color = playerColors[i % playerColors.length];
      
      posePaint.color = color;
      connectionPaint.color = color;

      // Draw pose landmarks
      _drawPoseLandmarks(canvas, pose, size, posePaint);
      
      // Draw pose connections
      _drawPoseConnections(canvas, pose, size, connectionPaint);
      
      // Draw position indicator
      _drawPositionIndicator(canvas, pose, size, i + 1, color);
    }
  }

  void _drawPoseLandmarks(Canvas canvas, Pose pose, Size canvasSize, Paint paint) {
    // Key landmarks to draw
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final landmarkType in keyLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null && landmark.likelihood > 0.5) {
        final point = _scalePoint(landmark.x, landmark.y, canvasSize);
        canvas.drawCircle(point, 6, paint);
      }
    }
  }

  void _drawPoseConnections(Canvas canvas, Pose pose, Size canvasSize, Paint paint) {
    // Define connections between landmarks
    final connections = [
      // Head to shoulders
      [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder],
      [PoseLandmarkType.nose, PoseLandmarkType.rightShoulder],
      
      // Shoulder line
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      
      // Arms
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      
      // Legs
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final startLandmark = pose.landmarks[connection[0]];
      final endLandmark = pose.landmarks[connection[1]];
      
      if (startLandmark != null && endLandmark != null &&
          startLandmark.likelihood > 0.5 && endLandmark.likelihood > 0.5) {
        final startPoint = _scalePoint(startLandmark.x, startLandmark.y, canvasSize);
        final endPoint = _scalePoint(endLandmark.x, endLandmark.y, canvasSize);
        
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  void _drawPositionIndicator(Canvas canvas, Pose pose, Size canvasSize, int position, Color color) {
    // Draw position number above the head
    final noseLandmark = pose.landmarks[PoseLandmarkType.nose];
    if (noseLandmark != null && noseLandmark.likelihood > 0.5) {
      final point = _scalePoint(noseLandmark.x, noseLandmark.y, canvasSize);
      
      // Draw circle background
      final backgroundPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(point.dx, point.dy - 30),
        15,
        backgroundPaint,
      );
      
      // Draw position number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$position',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          point.dy - 30 - textPainter.height / 2,
        ),
      );
    }
  }

  Offset _scalePoint(double x, double y, Size canvasSize) {
    if (cameraSize.width == 0 || cameraSize.height == 0) {
      return Offset(x, y);
    }
    
    // Scale from camera coordinates to canvas coordinates
    final scaleX = canvasSize.width / cameraSize.height; // Note: swapped for camera rotation
    final scaleY = canvasSize.height / cameraSize.width;
    
    return Offset(
      x * scaleX,
      y * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
