/// Game-specific constants
class GameConstants {
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
  static const int eliminationDelay =
      1000; // milliseconds before elimination announcement

  // UI Constants
  static const double lightIndicatorSize = 120.0;
  static const double playerCardHeight = 80.0;
  static const double countdownFontSize = 48.0;

  // Game Messages
  static const String getInPositionMessage = 'Get in position!';
  static const String redLightMessage = 'Red light!';
  static const String greenLightMessage = 'Green light!';
  static const String gameStarted = "Game Started! Green light!";
  static const String gameOverMessage =
      'Game Over! I win! Better luck next time.';
  static const String winnerMessage = 'Congratulations! You are the winner!';
  static const String welcomeMessage =
      'Welcome to Red Light Green Light! Get in your position. Game will start in 20 seconds.';
  static const String waitingForStableConnection =
      'Waiting for stable detection. Stand in front of the camera and stay very still for a few seconds.';
  static const String playerDetectedLobby =
      'Player detected! Great, I can see you clearly.';
}
