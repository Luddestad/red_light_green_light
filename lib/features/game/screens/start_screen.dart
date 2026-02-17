import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';
import '../widgets/animated_traffic_light_logo.dart';
import '../controllers/game_controller.dart';
import '../models/detection_settings.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/pose_detection_service.dart';
import '../../../core/services/audio_service.dart';

/// Start screen for selecting player count and starting the game
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Services (singletons - initialized here, available in GameScreen)
  final CameraService _cameraService = CameraService();
  final PoseDetectionService _poseService = PoseDetectionService();
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize services in background while user reads rules
  Future<void> _initializeServices() async {
    await _cameraService.initialize();
    await _poseService.initialize();
    await _audioService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Logo
                  const AnimatedTrafficLightLogo(height: 120),

                  const SizedBox(height: 30),

                  // Game instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'GAME RULES',
                          style: GoogleFonts.getFont('Black Han Sans').copyWith(
                            color: Colors.red,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 15),
                        _RuleRow(
                          icon: SvgPicture.asset(
                            'assets/images/icons/rules_green_light.svg',
                            height: 24,
                            width: 24,
                          ),
                          text: 'Move towards the phone.',
                        ),
                        SizedBox(height: 20),
                        _RuleRow(
                          icon: SvgPicture.asset(
                            'assets/images/icons/rules_red_light.svg',
                            height: 24,
                            width: 24,
                          ),
                          text: 'Stand completely still!',
                        ),
                        SizedBox(height: 20),
                        _RuleRow(
                          icon: Icon(
                            Icons.emoji_events,
                            color: Colors.yellow,
                            size: 24,
                          ),
                          text: 'Reach the phone and click the button to win!',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),

                  SizedBox(
                    width: 375,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 30),
                          const SizedBox(width: 10),
                          const Text(
                            'START GAME',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Add bottom padding for scroll space
                ], // Main Column children
              ), // Column
            ), // Padding
          ), // SingleChildScrollView
        ), // SafeArea
      ), // Container body
    ); // Scaffold
  }

  static Widget _RuleRow({required Widget icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 64, width: 64, child: icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.getFont(
              'Black Han Sans',
            ).copyWith(color: Colors.yellow, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _startGame() async {
    final controller = GameController(
      audioService: _audioService,
      cameraService: _cameraService,
      poseDetectionService: _poseService,
      settings: DetectionSettings.defaultSettings,
      onGoHome: () => Navigator.of(context).pop(),
    );

    await controller.initializeGame();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(gameController: controller),
      ),
    );
  }
}
