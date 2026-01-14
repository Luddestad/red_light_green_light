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
│   │   ├── detection_service.dart      # Orchestrates pose detection
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
│       │   ├── player_tracker.dart     # Individual player tracking
│       │   ├── pose_landmark.dart      # Pose data structures
│       │   ├── movement_detection.dart # Movement algorithms
│       │   └── difficulty_settings.dart # Difficulty configurations
│       ├── screens/
│       │   ├── start_screen.dart       # Main menu
│       │   └── game_screen.dart        # Main game loop
│       └── widgets/
│           ├── light_indicator_widget.dart        # Red/green light display
│           ├── enhanced_player_status_widget.dart # Player status UI
│           ├── movement_overlay_widget.dart       # Visual movement feedback
│           ├── pose_skeleton_widget.dart          # Skeleton visualization
│           └── game_over_screen.dart              # End game screen
└── shared/
    └── providers/
        └── app_state_provider.dart     # Global app state
```

### Recent Changes (January 2025)

- **Converted to single-player mode**: Removed all multi-player code and simplified architecture
- **Removed unused dependencies**: tflite_flutter and sqflite removed from pubspec.yaml
- **Optimized frame processing**: Adaptive frame skipping (2x during red light, 4x during green)
- **Simplified GameScreen**: No more playerCount parameter, single PlayerTracker instance
- **Updated GameState model**: Simplified for single player only

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
`PlayerTracker` (lib/features/game/models/player_tracker.dart) handles single player detection:
- **Pose tracking**: Maintains recent pose history for stability
- **Baseline system**: Captures "freeze" pose when red light starts
- **Movement detection**: Compares current pose to baseline using pixel-based thresholds (80 pixels)
- **Stability tracking**: Requires 4 consecutive stable frames before player is "ready"

Single player mode uses a single `PlayerTracker` instance (no arrays or lists).

#### 3. Detection Pipeline
Located in `game_screen.dart:_processImage()`:
1. Camera provides image stream (adaptive: every 2nd/4th frame based on game state)
2. `PoseDetectionService` runs ML Kit pose detection
3. `_updatePlayerTracker()` assigns pose to single player tracker
4. During red light: `_checkForMovementViolations()` checks for movement
5. `PlayerTracker.checkForMovement()` compares current vs baseline poses

**Adaptive Frame Skipping**:
- Initialization: Every 2nd frame (faster detection)
- Red Light: Every 2nd frame (accurate movement detection)
- Green/Waiting: Every 4th frame (battery saving)

#### 4. Movement Detection Algorithm
Simple pixel-based detection (lib/features/game/models/player_tracker.dart:181-246):
- Monitors 5 key landmarks: nose, shoulders, elbows
- Calculates pixel distance between current and baseline positions
- Threshold: 80 pixels of movement
- Requires movement for 3 consecutive frames to eliminate false positives

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
- Single `PlayerTracker` instance (no arrays)
- `GameScreen` has no `playerCount` parameter
- `GameState.isGameOver` returns true only when single player is eliminated
- `GameState.initializePositions()` always creates exactly 1 player
- All UI displays single player status
- Face detection removed (not needed for single player)

## Common Development Patterns

### Adding New Difficulty Settings
Edit `lib/features/game/models/difficulty_settings.dart`:
- Add new `DifficultySettings` with timing parameters
- `unpredictabilityFactor` adds randomness to light durations
- Update `StartScreen` to include new difficulty in UI

### Modifying Movement Sensitivity
Edit `lib/features/game/models/player_tracker.dart:222`:
- Adjust `movementThreshold` constant (currently 80.0 pixels)
- Lower = more sensitive, higher = more forgiving
- Different thresholds per landmark are possible (see commented multi-threshold code)

### Adding New Sound Effects
1. Add audio file to `assets/sounds/`
2. Update `pubspec.yaml` assets section (already includes `assets/sounds/`)
3. Add method to `AudioService` (lib/core/services/audio_service.dart)
4. Call from game screen at appropriate time

### Debugging Detection Issues
Enable logging in `PlayerTracker`:
- Stability frames: Line 157, 163, 171, 173, 177
- Movement detection: Line 225, 229, 232, 242
- Baseline setting: Line 253

Check `game_screen.dart` detection logs:
- System stability: Line 656
- Movement violations: Line 578, 599, 609
- Player assignment: Line 444, 453

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
- `assets/models/` - ML models (if using custom models)
- `assets/sounds/` - Audio files (.wav, .mp3)
- `assets/images/icons/` - Game icons
- `assets/images/backgrounds/` - Background images
- `assets/icon/` - App launcher icon

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
