import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/player_tracker.dart';

/// Widget to visualize pose skeletons for debugging movement detection
class PoseSkeletonWidget extends StatelessWidget {
  final List<PlayerTracker> playerTrackers;
  final Size imageSize;
  final Size canvasSize;

  const PoseSkeletonWidget({
    Key? key,
    required this.playerTrackers,
    required this.imageSize,
    required this.canvasSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PoseSkeletonPainter(
        playerTrackers: playerTrackers,
        imageSize: imageSize,
        canvasSize: canvasSize,
      ),
      child: Container(),
    );
  }
}

class PoseSkeletonPainter extends CustomPainter {
  final List<PlayerTracker> playerTrackers;
  final Size imageSize;
  final Size canvasSize;

  PoseSkeletonPainter({
    required this.playerTrackers,
    required this.imageSize,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;

    for (int i = 0; i < playerTrackers.length; i++) {
      final tracker = playerTrackers[i];
      
      // Draw current pose
      if (tracker.currentPose != null) {
        _drawPose(canvas, tracker.currentPose!, scaleX, scaleY, _getPlayerColor(i), 'Current');
      }
      
      // Draw baseline pose (if exists)
      if (tracker.baselinePose != null) {
        _drawPose(canvas, tracker.baselinePose!, scaleX, scaleY, _getPlayerColor(i).withOpacity(0.5), 'Baseline');
      }
      
      // Draw player info
      if (tracker.isDetected) {
        _drawPlayerInfo(canvas, tracker, i, scaleX, scaleY);
      }
    }
  }

  void _drawPose(Canvas canvas, Pose pose, double scaleX, double scaleY, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw key landmarks
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
    ];

    // Draw landmarks as points
    for (final landmarkType in keyLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null && landmark.likelihood > 0.5) {
        final point = Offset(landmark.x * scaleX, landmark.y * scaleY);
        canvas.drawCircle(point, 6, pointPaint);
        
        // Draw landmark label
        final textPainter = TextPainter(
          text: TextSpan(
            text: landmarkType.toString().split('.').last,
            style: TextStyle(color: color, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(point.dx + 8, point.dy - 4));
      }
    }

    // Draw skeleton connections
    _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint, scaleX, scaleY);
    
    // Connect torso
    _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paint, scaleX, scaleY);
    
    // Connect head to shoulders
    _drawConnection(canvas, pose, PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, paint, scaleX, scaleY);
    _drawConnection(canvas, pose, PoseLandmarkType.nose, PoseLandmarkType.rightShoulder, paint, scaleX, scaleY);
  }

  void _drawConnection(Canvas canvas, Pose pose, PoseLandmarkType start, PoseLandmarkType end, Paint paint, double scaleX, double scaleY) {
    final startLandmark = pose.landmarks[start];
    final endLandmark = pose.landmarks[end];
    
    if (startLandmark != null && endLandmark != null &&
        startLandmark.likelihood > 0.5 && endLandmark.likelihood > 0.5) {
      final startPoint = Offset(startLandmark.x * scaleX, startLandmark.y * scaleY);
      final endPoint = Offset(endLandmark.x * scaleX, endLandmark.y * scaleY);
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawPlayerInfo(Canvas canvas, PlayerTracker tracker, int playerIndex, double scaleX, double scaleY) {
    // Draw player info box
    final info = 'Player ${playerIndex + 1}\n'
                'Detected: ${tracker.isDetected}\n'
                'Stable: ${tracker.isStable}\n'
                'Moving: ${tracker.isMoving}\n'
                'Confidence: ${tracker.confidence.toStringAsFixed(2)}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: info,
        style: TextStyle(
          color: _getPlayerColor(playerIndex),
          fontSize: 12,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position info box at player's position
    double infoX = tracker.positionX * scaleX;
    double infoY = tracker.positionY * scaleY - 80; // Above the player

    // Keep info box within bounds
    infoX = infoX.clamp(0, canvasSize.width - textPainter.width);
    infoY = infoY.clamp(0, canvasSize.height - textPainter.height);

    // Draw background for text
    final bgRect = Rect.fromLTWH(infoX - 4, infoY - 4, textPainter.width + 8, textPainter.height + 8);
    canvas.drawRect(bgRect, Paint()..color = Colors.black54);

    textPainter.paint(canvas, Offset(infoX, infoY));
  }

  Color _getPlayerColor(int playerIndex) {
    switch (playerIndex) {
      case 0: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.yellow;
      case 3: return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(PoseSkeletonPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}
