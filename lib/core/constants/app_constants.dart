/// General application constants
class AppConstants {
  // App Information
  static const String appName = 'Red Light Green Light';
  static const String appVersion = '1.0.0';
  
  // Platform Support
  static const bool enableDesktopSupport = true;
  static const bool enableWebSupport = false;
  
  // Performance Settings
  static const int targetFrameRate = 30;
  static const int maxMemoryUsageMB = 512;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 4.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Error Messages
  static const String cameraPermissionDenied = 'Camera permission is required to play the game';
  static const String microphonePermissionDenied = 'Microphone permission is required for voice announcements';
  static const String cameraInitializationFailed = 'Failed to initialize camera';
  static const String unknownError = 'An unknown error occurred';
}
