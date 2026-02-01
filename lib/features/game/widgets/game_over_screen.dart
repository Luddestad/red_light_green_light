import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Game over screen widget
class GameOverScreen extends StatelessWidget {
  final GameSession gameSession;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onGoHome;

  const GameOverScreen({
    super.key,
    required this.gameSession,
    this.onPlayAgain,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final winner = gameSession.winner;
    final bool playerWon = winner != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: playerWon
              ? [Colors.green.shade700, Colors.green.shade900]
              : [Colors.red.shade700, Colors.red.shade900],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game Over Icon
            Icon(
              playerWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 120,
              color: Colors.white,
            ),

            const SizedBox(height: 30),

            // Game Over Title
            Text(
              'GAME OVER',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(3.0, 3.0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Winner/Loser Message
            Text(
              playerWon ? 'CONGRATULATIONS!' : 'I WIN!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: playerWon ? Colors.yellow : Colors.white,
                shadows: const [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Detailed Message
            Text(
              playerWon
                  ? 'You reached the phone and won!'
                  : 'Better luck next time!',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Game Stats
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play Again Button
                ElevatedButton(
                  onPressed: onPlayAgain ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Home Button
                ElevatedButton(
                  onPressed: onGoHome ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
