/// Game-specific constants
class GameConstants {
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

  // Error messages
  static const String cameraPermissionDenied =
      'Camera permission is required to play the game';
  static const String microphonePermissionDenied =
      'Microphone permission is required for voice announcements';
}
