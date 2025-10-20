/// Game-specific constants
class GameConstants {
  // Player Limits
  static const int maxPlayers = 4;
  static const int minPlayers = 1;
  
  // Game Timing
  static const int countdownDuration = 30; // seconds
  static const int minLightDuration = 3; // seconds
  static const int maxLightDuration = 8; // seconds
  static const int movementDetectionInterval = 100; // milliseconds
  
  // Movement Detection
  static const double movementThreshold = 0.1; // 10cm in normalized coordinates
  static const double forwardThreshold = 0.15; // 15cm forward movement
  static const double confidenceThreshold = 0.8; // 80% confidence required
  
  // Game States
  static const int maxRounds = 50; // Maximum rounds before game ends
  static const int eliminationDelay = 1000; // milliseconds before elimination announcement
  
  // Win Conditions
  static const int playersToWin = 1; // Last player standing wins
  
  // UI Constants
  static const double lightIndicatorSize = 120.0;
  static const double playerCardHeight = 80.0;
  static const double countdownFontSize = 48.0;
  
  // Game Messages
  static const String getInPositionMessage = 'Get in position!';
  static const String redLightMessage = 'Red light!';
  static const String greenLightMessage = 'Green light!';
  static const String gameOverMessage = 'Game Over!';
  static const String winnerMessage = 'Congratulations! You are the winner!';
}
