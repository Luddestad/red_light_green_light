import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility class to generate a traffic light app icon
class IconGenerator {
  /// Generate a traffic light icon as PNG bytes
  static Future<Uint8List> generateTrafficLightIcon({
    int size = 512,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    // Background (rounded rectangle with dark border)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.02;

    // Draw background
    final backgroundRect = RRect.fromRectAndRadius(
      rect.deflate(size * 0.05),
      Radius.circular(size * 0.1),
    );
    canvas.drawRRect(backgroundRect, backgroundPaint);
    canvas.drawRRect(backgroundRect, borderPaint);

    // Traffic light housing
    final housingRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size * 0.5, size * 0.5),
        width: size * 0.35,
        height: size * 0.75,
      ),
      Radius.circular(size * 0.08),
    );
    
    final housingPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(housingRect, housingPaint);

    // Light positions
    final lightRadius = size * 0.08;
    final centerX = size * 0.5;
    final topY = size * 0.28;
    final middleY = size * 0.5;
    final bottomY = size * 0.72;

    // Red light (active)
    final redPaint = Paint()
      ..color = const Color(0xFFFF3030)
      ..style = PaintingStyle.fill;
    final redGlowPaint = Paint()
      ..color = const Color(0xFFFF3030).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, topY), lightRadius * 1.3, redGlowPaint);
    canvas.drawCircle(Offset(centerX, topY), lightRadius, redPaint);

    // Yellow light (dim)
    final yellowPaint = Paint()
      ..color = const Color(0xFF666620)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, middleY), lightRadius, yellowPaint);

    // Green light (active)
    final greenPaint = Paint()
      ..color = const Color(0xFF30FF30)
      ..style = PaintingStyle.fill;
    final greenGlowPaint = Paint()
      ..color = const Color(0xFF30FF30).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, bottomY), lightRadius * 1.3, greenGlowPaint);
    canvas.drawCircle(Offset(centerX, bottomY), lightRadius, greenPaint);

    // Add highlight reflections
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // Red light highlight
    canvas.drawCircle(
      Offset(centerX - lightRadius * 0.3, topY - lightRadius * 0.3),
      lightRadius * 0.25,
      highlightPaint,
    );
    
    // Green light highlight
    canvas.drawCircle(
      Offset(centerX - lightRadius * 0.3, bottomY - lightRadius * 0.3),
      lightRadius * 0.25,
      highlightPaint,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  /// Save the generated icon to assets/icon/traffic_light_icon.png
  static Future<void> generateAndSaveIcon() async {
    final iconBytes = await generateTrafficLightIcon(size: 1024);
    // In a real implementation, you'd save this to the file system
    // For now, we'll use the flutter_launcher_icons package to handle this
    print('Generated traffic light icon: ${iconBytes.length} bytes');
  }
}
