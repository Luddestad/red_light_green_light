import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _LogoPhase { green, yellow, red }

class AnimatedTrafficLightLogo extends StatefulWidget {
  final double height;
  final Duration durationGreenRed;
  final Duration durationYellow;

  const AnimatedTrafficLightLogo({
    super.key,
    this.height = 120,
    this.durationGreenRed = const Duration(milliseconds: 1500),
    this.durationYellow = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedTrafficLightLogo> createState() =>
      _AnimatedTrafficLightLogoState();
}

class _AnimatedTrafficLightLogoState extends State<AnimatedTrafficLightLogo> {
  static const String _assetRed = 'assets/images/icons/Logo_red.svg';
  static const String _assetGreen = 'assets/images/icons/Logo_green.svg';
  static const String _assetYellow = 'assets/images/icons/Logo_yellow.svg';

  Timer? _timer;
  _LogoPhase _phase = _LogoPhase.red;

  @override
  void initState() {
    super.initState();
    _scheduleNext(widget.durationGreenRed);
  }

  void _scheduleNext(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, _onTick);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {
      switch (_phase) {
        case _LogoPhase.red:
          _phase = _LogoPhase.yellow;
          _scheduleNext(widget.durationYellow);
          break;
        case _LogoPhase.yellow:
          _phase = _LogoPhase.green;
          _scheduleNext(widget.durationGreenRed);
          break;
        case _LogoPhase.green:
          _phase = _LogoPhase.red;
          _scheduleNext(widget.durationGreenRed);
          break;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = switch (_phase) {
      _LogoPhase.green => _assetGreen,
      _LogoPhase.yellow => _assetYellow,
      _LogoPhase.red => _assetRed,
    };
    return SvgPicture.asset(asset, height: widget.height, fit: BoxFit.contain);
  }
}
