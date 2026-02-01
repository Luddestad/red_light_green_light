/// Game state enumeration and management
enum GameState {
  waiting, // Waiting for players to get in position
  countdown, // 30-second countdown before game starts
  greenLight, // Players can move
  redLight, // Players must freeze
  victory, // Player reached the phone and won
  gameOver, // Game completed (all players eliminated)
}

/// Position-based player tracking
class PlayerPosition {
  final List<double> baselinePose; // Reference pose landmarks when game starts
  bool isEliminated;
  int eliminationRound;
  DateTime? eliminationTime;

  PlayerPosition({
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

  /// Check if game is over (single player mode)
  bool get isGameOver {
    // Single player: game over only if player is eliminated
    return activePlayers.isEmpty;
  }

  /// Get winner position if game is over (single player mode)
  PlayerPosition? get winner {
    if (!isGameOver) return null;
    // Single player: no winner if eliminated
    return activePlayers.isNotEmpty ? activePlayers.first : null;
  }

  /// Initialize player position (single player mode)
  void initializePositions() {
    playerPositions.clear();
    eliminatedPlayers.clear();

    // Create single player for single-player mode
    playerPositions.add(
      PlayerPosition(
        baselinePose: [], // Will be set when game starts
      ),
    );
  }

  /// Set baseline poses for all positions
  void setBaselinePoses(List<List<double>> poses) {
    for (int i = 0; i < poses.length && i < playerPositions.length; i++) {
      final currentPlayer = playerPositions[i];
      playerPositions[i] = PlayerPosition(
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

  @override
  String toString() {
    return 'GameSession(state: $currentState, round: $currentRound, '
        'activePlayers: ${activePlayers.length}, '
        'eliminatedPlayers: ${eliminatedPlayers.length})';
  }
}
