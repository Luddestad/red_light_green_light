/// Game state enumeration and management
enum GameState {
  waiting, // Waiting for players to get in position
  countdown, //countdown before game starts
  greenLight, // Players can move
  redLight, // Players must freeze
  victory, // Player reached the phone and won
  gameOver, // Game completed (all players eliminated)
}

/// Position-based player tracking
class PlayerPosition {
  final List<double> baselinePose; // Reference pose landmarks when game starts
  bool isEliminated;
  DateTime? eliminationTime;

  PlayerPosition({
    required this.baselinePose,
    this.isEliminated = false,
    this.eliminationTime,
  });

  PlayerPosition copyWith({bool? isEliminated, DateTime? eliminationTime}) {
    return PlayerPosition(
      baselinePose: baselinePose,
      isEliminated: isEliminated ?? this.isEliminated,
      eliminationTime: eliminationTime ?? this.eliminationTime,
    );
  }
}

/// Main game session management
class GameSession {
  GameState currentState;
  DateTime lastStateChange;
  bool isDetectingMovement;
  bool isGameOver;
  // Game timing
  Duration greenLightDuration;
  Duration redLightDuration;
  DateTime? currentPhaseStartTime;

  GameSession({
    this.currentState = GameState.waiting,
    DateTime? lastStateChange,
    this.isDetectingMovement = false,
    this.isGameOver = false,
    this.greenLightDuration = const Duration(seconds: 5),
    this.redLightDuration = const Duration(seconds: 3),
    this.currentPhaseStartTime,
  }) : lastStateChange = lastStateChange ?? DateTime.now();

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
          isDetectingMovement = false;
        }
        break;
      case GameState.victory:
        break;
      case GameState.gameOver:
        break;
    }

    lastStateChange = DateTime.now();
    currentPhaseStartTime = DateTime.now();
  }

  @override
  String toString() {
    return 'GameSession(state: $currentState, isGameOver: $isGameOver)';
  }
}
