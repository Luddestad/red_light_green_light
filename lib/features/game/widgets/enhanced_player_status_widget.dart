import 'package:flutter/material.dart';
import '../models/player_tracker.dart';

/// Enhanced widget that displays the status of all players with distance info
class EnhancedPlayerStatusWidget extends StatelessWidget {
  final List<PlayerTracker> playerTrackers;
  final int currentRound;
  final bool showDetailedInfo;

  const EnhancedPlayerStatusWidget({
    super.key,
    required this.playerTrackers,
    required this.currentRound,
    this.showDetailedInfo = false,
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
          
          // Player trackers
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: playerTrackers.map((tracker) => 
              _buildPlayerCard(tracker)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerTracker tracker) {
    final isActive = tracker.isDetected;
    final color = _getPlayerColor(tracker.playerIndex);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name
          Text(
            tracker.playerName,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Status indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Detection status
              Icon(
                tracker.isDetected ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: tracker.isDetected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              
              // Stability status
              Icon(
                tracker.isStable ? Icons.check_circle : Icons.pending,
                size: 16,
                color: tracker.isStable ? Colors.blue : Colors.orange,
              ),
              
              if (showDetailedInfo) ...[
                const SizedBox(width: 4),
                // Distance indicator
                Icon(
                  _getDistanceIcon(tracker.estimatedDistance),
                  size: 16,
                  color: _getDistanceColor(tracker.estimatedDistance),
                ),
              ],
            ],
          ),
          
          if (showDetailedInfo) ...[
            const SizedBox(height: 4),
            // Distance text
            Text(
              _getDistanceText(tracker.estimatedDistance),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
            // Confidence
            Text(
              'Conf: ${(tracker.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPlayerColor(int index) {
    switch (index) {
      case 0: return Colors.blue;
      case 1: return Colors.green;
      case 2: return Colors.yellow;
      case 3: return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getDistanceIcon(double distance) {
    if (distance <= 0.5) return Icons.zoom_in; // Very close
    if (distance <= 1.0) return Icons.center_focus_strong; // Medium
    return Icons.zoom_out; // Far
  }

  Color _getDistanceColor(double distance) {
    if (distance <= 0.5) return Colors.green; // Close - good detection
    if (distance <= 1.0) return Colors.orange; // Medium - okay detection
    return Colors.red; // Far - challenging detection
  }

  String _getDistanceText(double distance) {
    if (distance <= 0.4) return 'Very Close';
    if (distance <= 0.7) return 'Close';
    if (distance <= 1.2) return 'Medium';
    return 'Far';
  }
}
