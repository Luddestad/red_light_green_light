import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../widgets/animated_traffic_light_logo.dart';
import '../controllers/game_controller.dart';
import '../models/difficulty_settings.dart';
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

  // Single-player only
  DifficultySettings _selectedDifficulty = DifficultySettings.defaultSettings;

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
      backgroundColor: Colors.black,
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
                    child: const Column(
                      children: [
                        Text(
                          'GAME RULES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '🟢    GREEN LIGHT: Move towards the camera\n'
                          '🔴    RED LIGHT: Freeze completely!\n'
                          '❌    Any movement during red light = ELIMINATION\n'
                          '🏆    Reach the phone to win!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 3,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Difficulty selection
                  Container(
                    padding: const EdgeInsets.all(18),
                    width: 375,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SELECT DIFFICULTY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Difficulty buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DifficultySettings.all
                              .map(
                                (difficulty) =>
                                    _buildDifficultyButton(difficulty),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          _selectedDifficulty.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),

                  // Start game button
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

  // Player count selection removed for single-player mode

  Widget _buildDifficultyButton(DifficultySettings difficulty) {
    final isSelected = _selectedDifficulty.level == difficulty.level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _getDifficultyColor(difficulty.level)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? _getDifficultyColor(difficulty.level)
                : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          difficulty.displayName,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(GameDifficulty level) {
    switch (level) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.medium:
        return Colors.orange;
      case GameDifficulty.hard:
        return Colors.red;
      case GameDifficulty.extreme:
        return Colors.purple;
    }
  }

  Future<void> _startGame() async {
    final controller = GameController(
      audioService: _audioService,
      cameraService: _cameraService,
      poseDetectionService: _poseService,
      difficulty: _selectedDifficulty,
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
