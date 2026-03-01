import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Dual-circle light indicator for green/red light states during gameplay.
/// Shows two circles side by side; the active one has a siren border animation
class LightIndicatorWidget extends StatefulWidget {
  final GameState gameState;

  const LightIndicatorWidget({super.key, required this.gameState});

  @override
  State<LightIndicatorWidget> createState() => _LightIndicatorWidgetState();
}

class _LightIndicatorWidgetState extends State<LightIndicatorWidget>
    with SingleTickerProviderStateMixin {
  static const double _circleDiameter = 80;
  static const double _borderWidth = 8;
  static const double _gapBetweenCircles = 32;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    unawaited(_animationController.repeat());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGreenActive = widget.gameState == GameState.greenLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black87,
            Colors.grey.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade800, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LightCircle(
                color: Colors.green,
                isActive: isGreenActive,
                animationValue: _animationController.value,
                size: _circleDiameter,
                borderWidth: _borderWidth,
              ),
              const SizedBox(width: _gapBetweenCircles),
              _LightCircle(
                color: Colors.red,
                isActive: !isGreenActive,
                animationValue: _animationController.value,
                size: _circleDiameter,
                borderWidth: _borderWidth,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LightCircle extends StatelessWidget {
  final Color color;
  final bool isActive;
  final double animationValue;
  final double size;
  final double borderWidth;

  const _LightCircle({
    required this.color,
    required this.isActive,
    required this.animationValue,
    required this.size,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final centerBright = isActive
        ? color.withValues(alpha: 1.0)
        : color.withValues(alpha: 0.5);
    final edgeColor = isActive
        ? color.withValues(alpha: 0.7)
        : color.withValues(alpha: 0.3);

    final circle = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.95,
              colors: [
                centerBright,
                edgeColor,
              ],
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        if (isActive)
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _SirenCirclePainter(
                baseColor: color,
                animationValue: animationValue,
                borderWidth: borderWidth,
              ),
            ),
          ),
      ],
    );

    if (isActive) {
      return circle;
    }

    return Opacity(
      opacity: 0.35,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: circle,
      ),
    );
  }
}

class _SirenCirclePainter extends CustomPainter {
  final Color baseColor;
  final double animationValue;
  final double borderWidth;

  _SirenCirclePainter({
    required this.baseColor,
    required this.animationValue,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - borderWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius + borderWidth);

    final dimColor = baseColor.withValues(alpha: 0.25);
    final midColor = Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
    final brightColor = Color.lerp(baseColor, Colors.white, 0.6) ?? baseColor;

    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: [
        dimColor,
        dimColor,
        midColor,
        brightColor,
        brightColor,
        midColor,
        dimColor,
        dimColor,
      ],
      stops: const [0.0, 0.06, 0.14, 0.22, 0.30, 0.38, 0.46, 0.54],
      transform: GradientRotation(animationValue * 2 * math.pi),
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final sharpPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, sharpPaint);
  }

  @override
  bool shouldRepaint(covariant _SirenCirclePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.baseColor != baseColor;
  }
}
