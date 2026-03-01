# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application implementing "Red Light Green Light" - a computer vision-based game that uses real-time pose detection to detect player movement. Players must freeze when the game says "red light" or be eliminated. The app uses Google ML Kit for pose detection and includes audio/TTS feedback.

**Single-player mode only** - fully cleaned up and optimized for single player gameplay.

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build app bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### App Icon Generation
```bash
# Generate launcher icons
flutter pub run flutter_launcher_icons
```

## Architecture Overview

### Directory Structure
```
lib/
├── core/                      # Core services and constants
│   ├── services/
│   │   ├── audio_service.dart          # TTS and sound effects
│   │   ├── camera_service.dart         # Camera initialization & streaming
│   │   ├── pose_detection_service.dart # ML Kit pose detection
│   │   └── permission_service.dart     # Camera permissions
│   └── constants/
│       ├── game_constants.dart         # Game timing & rules
│       ├── audio_constants.dart        # Sound file paths
│       ├── detection_constants.dart    # Movement thresholds
│       └── app_constants.dart          # General app config
├── features/
│   └── game/
│       ├── models/
│       │   ├── game_state.dart         # Game state machine & session
│       │   ├── pose_landmark.dart      # Pose data structures
│       │   └── difficulty_settings.dart # Difficulty configurations
│       ├── screens/
│       │   ├── start_screen.dart       # Main menu
│       │   └── game_screen.dart        # Main game loop (includes player tracking)
│       └── widgets/
│           ├── light_indicator_widget.dart   # Red/green light display
│           ├── movement_overlay_widget.dart  # Pose skeleton visualization
│           └── game_over_screen.dart         # End game screen
└── main.dart                  # App entry point
```

### Recent Changes (February 2026)

- **Workshop cleanup**: Removed unused files (detection_service.dart, movement_detection.dart, app_state_provider.dart)
- **Removed unused dependencies**: go_router, shared_preferences, path_provider, provider
- **Simplified for workshop**: Inline player tracking in game_screen.dart, no separate PlayerTracker class
- **Fixed audio constants**: Corrected file paths to match actual .wav files
- **Optimized frame processing**: Adaptive frame skipping (2x during red light, 4x during green)

### Key Architectural Patterns

#### 1. Game State Management
The game uses a state machine defined in `GameState` enum:
- `waiting` → `countdown` → `greenLight` ⇄ `redLight` → `gameOver`/`victory`

`GameSession` in `game_state.dart` manages:
- Current game state
- Player positions (position-based, not identity-based)
- Elimination tracking
- Round progression
- Dynamic timing based on difficulty

#### 2. Player Tracking System
Player tracking is implemented inline in `game_screen.dart` (lines 54-60):
- **Pose tracking**: `_currentPose` and `_baselinePose` variables
- **Baseline system**: Captures "freeze" pose when red light starts
- **Movement detection**: `_checkSimpleMovement()` compares current pose to baseline using pixel-based thresholds (80 pixels)
- **Stability tracking**: `_stabilityFrames` counter requires 4 consecutive stable frames before player is "ready"

#### 3. Detection Pipeline
Located in `game_screen.dart:_processImage()`:
1. Camera provides image stream (adaptive: every 2nd/4th frame based on game state)
2. `PoseDetectionService` runs ML Kit pose detection
3. `_updatePoseDetection()` updates the current pose and stability tracking
4. During red light: `_checkForMovementViolations()` checks for movement
5. `_checkSimpleMovement()` compares current vs baseline poses

**Adaptive Frame Skipping**:
- Initialization: Every 2nd frame (faster detection)
- Red Light: Every 2nd frame (accurate movement detection)
- Green/Waiting: Every 4th frame (battery saving)

#### 4. Movement Detection Algorithm
Simple pixel-based detection in `game_screen.dart:_checkSimpleMovement()` (lines 346-380):
- Monitors 5 key landmarks: nose, shoulders, elbows
- Calculates pixel distance between current and baseline positions
- Threshold: 80 pixels of movement
- Immediate elimination on detection (simplified for workshop)

#### 5. Audio System
`AudioService` (lib/core/services/audio_service.dart) provides:
- **TTS**: Female voice for announcements
- **Sound effects**: Red light, elimination, victory, game over
- **Background music**: Lobby music (looping)
- **Timing coordination**: Plays sound effect → delay → TTS announcement

### Critical Game Loop Timing

Located in `game_screen.dart:_startGameLoop()`:
- Timer checks every 1 second
- Green light duration: randomized per difficulty (3-6s for easy)
- Red light duration: randomized per difficulty (3-5s for easy)
- **Important**: Baseline pose is captured AFTER "Red light!" announcement completes
- Movement detection only starts after baseline is set

### Single Player Architecture

Fully converted to single-player mode:
- Pose tracking variables inline in `GameScreen` (`_currentPose`, `_baselinePose`, `_stabilityFrames`)
- `GameState.isGameOver` returns true only when single player is eliminated
- `GameState.initializePositions()` creates single player
- All UI displays single player status
- Face detection removed (not needed for single player)

## Common Development Patterns

### Adding New Difficulty Settings
Edit `lib/features/game/models/difficulty_settings.dart`:
- Add new `DifficultySettings` with timing parameters
- `unpredictabilityFactor` adds randomness to light durations
- Update `StartScreen` to include new difficulty in UI

### Modifying Movement Sensitivity
Edit `lib/features/game/screens/game_screen.dart:_checkSimpleMovement()`:
- Adjust `threshold` constant (currently 80.0 pixels)
- Lower = more sensitive, higher = more forgiving

### Adding New Sound Effects
1. Add audio file to `assets/sounds/`
2. Update `pubspec.yaml` assets section (already includes `assets/sounds/`)
3. Add method to `AudioService` (lib/core/services/audio_service.dart)
4. Call from game screen at appropriate time

### Debugging Detection Issues
Check `game_screen.dart` detection logs:
- Pose detection status: `_updatePoseDetection()` logs landmark count and stability
- Movement violations: `_checkForMovementViolations()` and `_checkSimpleMovement()` log detected movement
- Baseline setting: `_switchToRedLight()` logs baseline capture

## Platform-Specific Notes

### Android
- Minimum SDK: Check `android/app/build.gradle`
- Camera permission required in `AndroidManifest.xml`
- ML Kit models download on first run (requires internet)

### iOS
- Camera usage description required in `Info.plist`
- ML Kit bundled with app (larger app size)

### Assets
Required asset directories:
- `assets/sounds/` - Audio files (.wav): red_light, eliminated, game_over, victory, lobby
- `assets/icon/` - App launcher icon (traffic_light_icon.png)

## Important Considerations

### Performance
- Camera processing throttled to every 3rd frame (game_screen.dart:266)
- Pose detection is computationally expensive
- Audio operations are async and may block game flow if not handled properly

### Game Balance
- Movement threshold (80px) is tuned for typical webcam distance
- Closer to camera = more pixels of movement for same physical motion
- Stability requirement (4 frames) balances responsiveness vs false positives

### Baseline Timing Critical
The baseline pose MUST be captured after the "Red light!" audio completes:
- `_switchToRedLight()` in game_screen.dart:215-245
- Audio plays first, then baseline is set
- This prevents capturing mid-speech movement

### State Transition Safety
Always check current state before actions:
- Movement detection only during `GameState.redLight`
- Player announcements only during `GameState.waiting`
- Game start requires stable player detection
