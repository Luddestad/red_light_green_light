import 'package:flutter/material.dart';

/// Game state enumeration and management
enum GameState {
  waiting,     // Waiting for players to get in position
  countdown,   // 30-second countdown before game starts
  greenLight,  // Players can move
  redLight,    // Players must freeze
  victory,     // Player reached the phone and won
  gameOver,    // Game completed (all players eliminated)
}

/// Position-based player tracking
class PlayerPosition {
  final int positionIndex;  // 0, 1, 2, 3 for positions left to right
  final String positionName; // "Position 1", "Position 2", etc.
  final List<double> baselinePose; // Reference pose landmarks when game starts
  bool isEliminated;
  int eliminationRound;
  DateTime? eliminationTime;

  PlayerPosition({
    required this.positionIndex,
    required this.positionName,
    required this.baselinePose,
    this.isEliminated = false,
    this.eliminationRound = 0,
    this.eliminationTime,
  });

  PlayerPosition copyWith({
    bool? isEliminated,
    int? eliminationRound,
    DateTime? eliminationTime,
  }) {
    return PlayerPosition(
      positionIndex: positionIndex,
      positionName: positionName,
      baselinePose: baselinePose,
      isEliminated: isEliminated ?? this.isEliminated,
      eliminationRound: eliminationRound ?? this.eliminationRound,
      eliminationTime: eliminationTime ?? this.eliminationTime,
    );
  }
}

/// Main game session management
class GameSession {
  GameState currentState;
  List<PlayerPosition> playerPositions;
  List<PlayerPosition> eliminatedPlayers;
  int currentRound;
  DateTime lastStateChange;
  bool isDetectingMovement;
  int? winnerPosition;
  
  // Game timing
  Duration greenLightDuration;
  Duration redLightDuration;
  DateTime? currentPhaseStartTime;

  GameSession({
    this.currentState = GameState.waiting,
    List<PlayerPosition>? playerPositions,
    List<PlayerPosition>? eliminatedPlayers,
    this.currentRound = 1,
    DateTime? lastStateChange,
    this.isDetectingMovement = false,
    this.winnerPosition,
    this.greenLightDuration = const Duration(seconds: 5),
    this.redLightDuration = const Duration(seconds: 3),
    this.currentPhaseStartTime,
  }) : playerPositions = playerPositions ?? [],
       eliminatedPlayers = eliminatedPlayers ?? [],
       lastStateChange = lastStateChange ?? DateTime.now();

  /// Get active (non-eliminated) players
  List<PlayerPosition> get activePlayers => 
      playerPositions.where((p) => !p.isEliminated).toList();

  /// Check if game is over 
  bool get isGameOver {
    // Single player: game over only if player is eliminated
    if (playerPositions.length == 1) {
      return activePlayers.isEmpty;
    }
    // Multi-player: game over when 0 or 1 players left
    return activePlayers.length <= 1;
  }

  /// Get winner position if game is over
  PlayerPosition? get winner {
    if (!isGameOver) return null;
    
    // Single player: no winner if eliminated, otherwise winner is the player
    if (playerPositions.length == 1) {
      return activePlayers.isNotEmpty ? activePlayers.first : null;
    }
    // Multi-player: winner is the last remaining player
    return activePlayers.isNotEmpty ? activePlayers.first : null;
  }
  
  /// Set winner by PlayerPosition
  set winner(PlayerPosition? player) {
    winnerPosition = player?.positionIndex;
  }

  /// Eliminate a player at specific position
  void eliminatePlayer(int positionIndex) {
    final playerIndex = playerPositions.indexWhere(
      (p) => p.positionIndex == positionIndex && !p.isEliminated
    );
    
    if (playerIndex != -1) {
      playerPositions[playerIndex] = playerPositions[playerIndex].copyWith(
        isEliminated: true,
        eliminationRound: currentRound,
        eliminationTime: DateTime.now(),
      );
      eliminatedPlayers.add(playerPositions[playerIndex]);
    }
  }

  /// Initialize player positions (up to 4 players)
  void initializePositions(int playerCount) {
    playerPositions.clear();
    eliminatedPlayers.clear();
    
    for (int i = 0; i < playerCount && i < 4; i++) {
      playerPositions.add(PlayerPosition(
        positionIndex: i,
        positionName: 'Position ${i + 1}',
        baselinePose: [], // Will be set when game starts
      ));
    }
  }

  /// Set baseline poses for all positions
  void setBaselinePoses(List<List<double>> poses) {
    for (int i = 0; i < poses.length && i < playerPositions.length; i++) {
      final currentPlayer = playerPositions[i];
      playerPositions[i] = PlayerPosition(
        positionIndex: currentPlayer.positionIndex,
        positionName: currentPlayer.positionName,
        baselinePose: poses[i],
        isEliminated: currentPlayer.isEliminated,
        eliminationRound: currentPlayer.eliminationRound,
        eliminationTime: currentPlayer.eliminationTime,
      );
    }
  }

  /// Advance to next game state
  void advanceState() {
    switch (currentState) {
      case GameState.waiting:
        currentState = GameState.countdown;
        break;
      case GameState.countdown:
        currentState = GameState.greenLight;
        break;
      case GameState.greenLight:
        currentState = GameState.redLight;
        isDetectingMovement = true;
        break;
      case GameState.redLight:
        if (isGameOver) {
          currentState = GameState.gameOver;
          isDetectingMovement = false;
        } else {
          currentState = GameState.greenLight;
          currentRound++;
          isDetectingMovement = false;
        }
        break;
      case GameState.victory:
        // Victory state is final, no more state changes
        break;
      case GameState.gameOver:
        // Game is over, no state change
        break;
    }
    
    lastStateChange = DateTime.now();
    currentPhaseStartTime = DateTime.now();
  }

  /// Get current state display text
  String get stateDisplayText {
    switch (currentState) {
      case GameState.waiting:
        return 'Get in Position!';
      case GameState.countdown:
        return 'Game Starting...';
      case GameState.greenLight:
        return 'GREEN LIGHT - GO!';
      case GameState.redLight:
        return 'RED LIGHT - FREEZE!';
      case GameState.victory:
        return winner != null ? '${winner!.positionName} Wins!' : 'Victory!';
      case GameState.gameOver:
        return winner != null ? '${winner!.positionName} Wins!' : 'Game Over';
    }
  }

  /// Get current state color
  Color get stateColor {
    switch (currentState) {
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

  @override
  String toString() {
    return 'GameSession(state: $currentState, round: $currentRound, '
           'activePlayers: ${activePlayers.length}, '
           'eliminatedPlayers: ${eliminatedPlayers.length})';
  }
}
