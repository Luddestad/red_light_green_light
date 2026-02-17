import 'dart:math' as math;

/// Tunable detection and timing parameters for the game.
/// Adjust these to make detection stricter (lower threshold, higher stability)
/// or more forgiving (higher threshold, lower stability).
class DetectionSettings {
  /// How far a body landmark can move (in pixels) before it counts as "movement"
  /// during red light. Lower = stricter (small twitches trigger elimination).
  /// Higher = more forgiving (only bigger movements count).
  final double movementThresholdPx;

  /// How many consecutive frames you must hold still to be considered "ready"
  /// before starting. Higher = you must freeze longer in the countdown phase.
  /// Lower = you can start sooner after standing still.
  final int stabilityFramesRequired;

  /// Minimum length of the green light phase (seconds). Each green phase picks
  /// a random duration between this and [greenLightDurationSecondsMax].
  final int greenLightDurationSecondsMin;

  /// Maximum length of the green light phase (seconds). Each green phase picks
  /// a random duration between [greenLightDurationSecondsMin] and this.
  final int greenLightDurationSecondsMax;

  /// Minimum length of the red light phase (seconds). Each red phase picks
  /// a random duration between this and [redLightDurationSecondsMax].
  final int redLightDurationSecondsMin;

  /// Maximum length of the red light phase (seconds). Each red phase picks
  /// a random duration between [redLightDurationSecondsMin] and this.
  final int redLightDurationSecondsMax;

  /// Time in milliseconds after "Red light!" is announced before the baseline
  /// pose is captured. During this grace period the player can freeze before
  /// movement detection starts. Suggested range 500–1500.
  final int redLightFreezeGraceMs;

  const DetectionSettings({
    this.movementThresholdPx = 80,
    this.stabilityFramesRequired = 4,
    this.greenLightDurationSecondsMin = 3,
    this.greenLightDurationSecondsMax = 6,
    this.redLightDurationSecondsMin = 2,
    this.redLightDurationSecondsMax = 5,
    this.redLightFreezeGraceMs = 800,
  });

  /// Returns a random duration (in seconds) within [minSeconds] and [maxSeconds]
  /// (inclusive). Use with green or red light min/max from this settings object.
  Duration getRandomDurationInRange(int minSeconds, int maxSeconds) {
    final min = minSeconds;
    final max = maxSeconds;
    final seconds = min + math.Random().nextInt((max - min).clamp(0, 999) + 1);
    return Duration(seconds: seconds);
  }

  DetectionSettings copyWith({
    double? movementThresholdPx,
    int? stabilityFramesRequired,
    int? greenLightDurationSecondsMin,
    int? greenLightDurationSecondsMax,
    int? redLightDurationSecondsMin,
    int? redLightDurationSecondsMax,
    int? redLightFreezeGraceMs,
  }) {
    return DetectionSettings(
      movementThresholdPx: movementThresholdPx ?? this.movementThresholdPx,
      stabilityFramesRequired:
          stabilityFramesRequired ?? this.stabilityFramesRequired,
      greenLightDurationSecondsMin: greenLightDurationSecondsMin ??
          this.greenLightDurationSecondsMin,
      greenLightDurationSecondsMax: greenLightDurationSecondsMax ??
          this.greenLightDurationSecondsMax,
      redLightDurationSecondsMin:
          redLightDurationSecondsMin ?? this.redLightDurationSecondsMin,
      redLightDurationSecondsMax:
          redLightDurationSecondsMax ?? this.redLightDurationSecondsMax,
      redLightFreezeGraceMs:
          redLightFreezeGraceMs ?? this.redLightFreezeGraceMs,
    );
  }

  static const DetectionSettings defaultSettings = DetectionSettings();
}
