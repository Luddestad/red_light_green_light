import 'dart:math' as math;

/// Difficulty levels for the Red Light Green Light game
enum GameDifficulty {
  easy,
  medium,
  hard,
  extreme,
}

/// Difficulty settings that control game timing and unpredictability
class DifficultySettings {
  final GameDifficulty level;
  final String displayName;
  final String description;
  
  // Timing ranges (in seconds)
  final double minGreenLightDuration;
  final double maxGreenLightDuration;
  final double minRedLightDuration;
  final double maxRedLightDuration;
  
  // Unpredictability factor (0.0 = predictable, 1.0 = very random)
  final double unpredictabilityFactor;
  
  const DifficultySettings({
    required this.level,
    required this.displayName,
    required this.description,
    required this.minGreenLightDuration,
    required this.maxGreenLightDuration,
    required this.minRedLightDuration,
    required this.maxRedLightDuration,
    required this.unpredictabilityFactor,
  });

  /// Get timing for green light phase
  Duration getGreenLightDuration() {
    final random = math.Random();
    final baseDuration = minGreenLightDuration + 
        random.nextDouble() * (maxGreenLightDuration - minGreenLightDuration);
    
    // Apply unpredictability - can make it shorter or longer
    final variation = (random.nextDouble() - 0.5) * unpredictabilityFactor * baseDuration;
    final finalDuration = math.max(1.0, baseDuration + variation);
    
    return Duration(milliseconds: (finalDuration * 1000).round());
  }

  /// Get timing for red light phase
  Duration getRedLightDuration() {
    final random = math.Random();
    final baseDuration = minRedLightDuration + 
        random.nextDouble() * (maxRedLightDuration - minRedLightDuration);
    
    // Apply unpredictability - can make it shorter or longer
    final variation = (random.nextDouble() - 0.5) * unpredictabilityFactor * baseDuration;
    final finalDuration = math.max(1.0, baseDuration + variation);
    
    return Duration(milliseconds: (finalDuration * 1000).round());
  }

  /// Predefined difficulty settings
  static const List<DifficultySettings> all = [
    DifficultySettings(
      level: GameDifficulty.easy,
      displayName: 'Easy',
      description: 'Predictable timing, longer intervals',
      minGreenLightDuration: 3.0,
      maxGreenLightDuration: 6.0,
      minRedLightDuration: 3.0,
      maxRedLightDuration: 5.0,
      unpredictabilityFactor: 0.1, // Very predictable
    ),
    DifficultySettings(
      level: GameDifficulty.medium,
      displayName: 'Medium',
      description: 'Moderate unpredictability',
      minGreenLightDuration: 2.5,
      maxGreenLightDuration: 5.0,
      minRedLightDuration: 2.5,
      maxRedLightDuration: 4.5,
      unpredictabilityFactor: 0.3, // Some variation
    ),
    DifficultySettings(
      level: GameDifficulty.hard,
      displayName: 'Hard',
      description: 'Very unpredictable, shorter intervals',
      minGreenLightDuration: 1.5,
      maxGreenLightDuration: 4.0,
      minRedLightDuration: 2.0,
      maxRedLightDuration: 4.0,
      unpredictabilityFactor: 0.5, // High variation
    ),
    DifficultySettings(
      level: GameDifficulty.extreme,
      displayName: 'Extreme',
      description: 'Insanely fast and unpredictable intervals',
      minGreenLightDuration: 0.5,  // Much shorter - as fast as 0.5 seconds!
      maxGreenLightDuration: 2.0,  // Reduced from 3.0 to 2.0
      minRedLightDuration: 0.8,    // Much shorter - as fast as 0.8 seconds!
      maxRedLightDuration: 2.5,    // Reduced from 3.5 to 2.5
      unpredictabilityFactor: 0.95, // Nearly maximum chaos!
    ),
  ];

  /// Get difficulty settings by level
  static DifficultySettings byLevel(GameDifficulty level) {
    return all.firstWhere((settings) => settings.level == level);
  }

  /// Default difficulty
  static DifficultySettings get defaultSettings => all[0]; // Easy
}
