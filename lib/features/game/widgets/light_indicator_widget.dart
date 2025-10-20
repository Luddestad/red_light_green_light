import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Widget that shows the current game state with visual indicator
class LightIndicatorWidget extends StatelessWidget {
  final GameState gameState;
  final int? countdownSeconds;

  const LightIndicatorWidget({
    super.key,
    required this.gameState,
    this.countdownSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getBorderColor(),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBorderColor().withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Light circle indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getLightColor(),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getLightColor().withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _buildLightContent(),
          ),
          const SizedBox(height: 15),
          
          // State text
          Text(
            _getStateText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          // Countdown display
          if (countdownSeconds != null) ...[
            const SizedBox(height: 10),
            Text(
              '$countdownSeconds',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (gameState) {
      case GameState.waiting:
        return Colors.blue.shade800;
      case GameState.countdown:
        return Colors.orange.shade800;
      case GameState.greenLight:
        return Colors.green.shade800;
      case GameState.redLight:
        return Colors.red.shade800;
      case GameState.victory:
        return Colors.green.shade800;
      case GameState.gameOver:
        return Colors.purple.shade800;
    }
  }

  Color _getBorderColor() {
    switch (gameState) {
      case GameState.waiting:
        return Colors.blue;
      case GameState.countdown:
        return Colors.orange;
      case GameState.greenLight:
        return Colors.green;
      case GameState.redLight:
        return Colors.red;
      case GameState.victory:
        return Colors.green;
      case GameState.gameOver:
        return Colors.purple;
    }
  }

  Color _getLightColor() {
    switch (gameState) {
      case GameState.waiting:
        return Colors.blue.shade300;
      case GameState.countdown:
        return Colors.orange.shade300;
      case GameState.greenLight:
        return Colors.green.shade400;
      case GameState.redLight:
        return Colors.red.shade400;
      case GameState.victory:
        return Colors.green.shade400;
      case GameState.gameOver:
        return Colors.purple.shade300;
    }
  }

  Widget _buildLightContent() {
    switch (gameState) {
      case GameState.waiting:
        return const Icon(
          Icons.people,
          color: Colors.white,
          size: 40,
        );
      case GameState.countdown:
        return const Icon(
          Icons.timer,
          color: Colors.white,
          size: 40,
        );
      case GameState.greenLight:
        return const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 50,
        );
      case GameState.redLight:
        return const Icon(
          Icons.stop,
          color: Colors.white,
          size: 40,
        );
      case GameState.victory:
        return const Icon(
          Icons.emoji_events,
          color: Colors.yellow,
          size: 50,
        );
      case GameState.gameOver:
        return const Icon(
          Icons.flag,
          color: Colors.white,
          size: 40,
        );
    }
  }

  String _getStateText() {
    switch (gameState) {
      case GameState.waiting:
        return 'Get in Position!';
      case GameState.countdown:
        return 'Game Starting...';
      case GameState.greenLight:
        return 'GREEN LIGHT\nGO!';
      case GameState.redLight:
        return 'RED LIGHT\nFREEZE!';
      case GameState.victory:
        return 'VICTORY!';
      case GameState.gameOver:
        return 'Game Over!';
    }
  }
}
