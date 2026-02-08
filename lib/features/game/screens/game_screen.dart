import 'package:flutter/material.dart';
import 'package:red_light_green_light/features/game/controllers/game_controller.dart';
import '../models/game_state.dart';
import '../widgets/light_indicator_widget.dart';
import '../widgets/movement_overlay_widget.dart';
import '../widgets/game_over_screen.dart';

/// Main game screen for Red Light Green Light (Single Player)
class GameScreen extends StatefulWidget {
  final GameController gameController;

  const GameScreen({super.key, required this.gameController});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void dispose() {
    widget.gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameController,
      builder: (context, child) {
        final controller = widget.gameController;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Camera preview
              if (controller.cameraService.isInitialized)
                Positioned.fill(
                  child:
                      controller.cameraService.getCameraPreview() ??
                      Container(),
                ),

              // Game state indicator (green/red light during gameplay)
              if (controller.gameSession.currentState == GameState.greenLight ||
                  controller.gameSession.currentState == GameState.redLight)
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: LightIndicatorWidget(
                    gameState: controller.gameSession.currentState,
                  ),
                ),

              // Large countdown timer
              if (controller.gameSession.currentState == GameState.waiting &&
                  controller.countdownSeconds > 0)
                Positioned(
                  top: 200,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          controller.countdownSeconds.toString(),
                          style: const TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Get Ready!',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                bottom: 250,
                left: 150,
                child: Row(
                  children: [
                    if (controller.gameSession.currentState ==
                        GameState.waiting)
                      ElevatedButton(
                        onPressed: controller.startGame,
                        child: const Text('Start Now'),
                      ),
                    IconButton(
                      onPressed: controller.goHome,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.gameSession.currentState == GameState.waiting)
                Positioned(
                  bottom: 150,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(
                              controller.isPlayerDetected
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: controller.isPlayerDetected
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isPlayerDetected
                                  ? 'Detected'
                                  : 'Searching',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              controller.isPlayerStable
                                  ? Icons.verified
                                  : Icons.hourglass_empty,
                              color: controller.isPlayerStable
                                  ? Colors.green
                                  : Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isPlayerStable
                                  ? 'Stable'
                                  : 'Stabilizing',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Win button (only show during green light) - MUST be AFTER overlays to be clickable
              if (controller.gameSession.currentState == GameState.greenLight)
                Positioned(
                  bottom: 50, // Moved lower to be accessible
                  left: 50,
                  right: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.winGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10, // Increased elevation to stay on top
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 40,
                          color: Colors.yellow,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'WIN GAME!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Movement detection overlay
              if (controller.gameSession.isDetectingMovement &&
                  controller.currentPose != null)
                Positioned.fill(
                  child: IgnorePointer(
                    // Allow touches to pass through
                    child: MovementOverlayWidget(
                      poses: [controller.currentPose!],
                      cameraSize:
                          controller
                              .cameraService
                              .controller
                              ?.value
                              .previewSize ??
                          Size.zero,
                    ),
                  ),
                ),

              // Victory Screen Overlay
              if (controller.gameSession.currentState == GameState.victory) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade800, Colors.green.shade400],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.yellow,
                            size: 120,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'VICTORY!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(3.0, 3.0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Congratulations!',
                            style: TextStyle(
                              color: Colors.yellow.shade200,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'You reached the phone and won!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Play Again Button
                              ElevatedButton(
                                onPressed: controller.restartGame,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'Play Again',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),

                              // Home Button
                              ElevatedButton(
                                onPressed: controller.goHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.home, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'Home',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Game Over Screen Overlay (for eliminations)
              if (controller.gameSession.currentState ==
                  GameState.gameOver) ...[
                // Actual game over screen
                Positioned.fill(
                  child: GameOverScreen(
                    gameSession: controller.gameSession,
                    onPlayAgain: controller.restartGame,
                    onGoHome: controller.goHome,
                  ),
                ),
              ],

              // Game controls
            ],
          ),
        );
      },
    );
  }
}
