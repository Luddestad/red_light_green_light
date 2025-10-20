import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Widget that displays the status of all player positions
class PlayerStatusWidget extends StatelessWidget {
  final List<PlayerPosition> playerPositions;
  final int currentRound;

  const PlayerStatusWidget({
    super.key,
    required this.playerPositions,
    required this.currentRound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Round indicator
          Text(
            'Round $currentRound',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Player positions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: playerPositions.map((position) => 
              _buildPlayerCard(position)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerPosition position) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: position.isEliminated 
            ? Colors.red.withOpacity(0.3)
            : Colors.green.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: position.isEliminated ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Position indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: position.isEliminated 
                  ? Colors.red.shade300
                  : Colors.green.shade300,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${position.positionIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          // Status text
          Text(
            position.isEliminated ? 'OUT' : 'IN',
            style: TextStyle(
              color: position.isEliminated ? Colors.red : Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Elimination round
          if (position.isEliminated)
            Text(
              'R${position.eliminationRound}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
