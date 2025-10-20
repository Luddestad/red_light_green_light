# Red Light, Green Light Game - Application Structure

## Project Overview
A Flutter application that uses computer vision to detect player movement during a Red Light, Green Light game with voice narration and local multiplayer support.

## Platform Support
- **Primary**: iOS & Android
- **Secondary**: Desktop (Windows, macOS, Linux)
- **Target Device**: Google Pixel 10 XL Pro performance level

## Game Specifications
- **Max Players**: 4 players (adjustable based on detection accuracy)
- **Movement Detection**: Large pose changes or substantial forward movement
- **Elimination**: Immediate elimination on violation (no warning system)
- **Game Mode**: Local multiplayer only
- **Connectivity**: Completely offline
- **Voice**: Female English accent TTS

---

## Dependencies Configuration

### pubspec.yaml Dependencies
```yaml
dependencies:
  # Computer Vision & ML
  tflite_flutter: ^0.10.4
  camera: ^0.10.5+5
  google_mlkit_face_detection: ^0.10.0
  google_mlkit_pose_detection: ^0.10.0
  
  # State Management
  provider: ^6.1.1
  
  # Audio & Voice
  flutter_tts: ^3.8.5
  audioplayers: ^5.2.1
  
  # UI & Navigation
  go_router: ^12.1.3
  
  # Local Storage
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  
  # Utilities
  permission_handler: ^11.2.0
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## Complete Folder Structure

```
lib/
├── main.dart                          # Application entry point
├── core/                              # Core application logic
│   ├── constants/                     # Application constants
│   │   ├── app_constants.dart         # General app constants
│   │   ├── game_constants.dart        # Game-specific constants
│   │   ├── detection_constants.dart   # Computer vision constants
│   │   └── audio_constants.dart       # Audio/TTS constants
│   ├── utils/                         # Utility functions
│   │   ├── camera_utils.dart          # Camera-related utilities
│   │   ├── pose_utils.dart            # Pose detection utilities
│   │   ├── audio_utils.dart           # Audio processing utilities
│   │   ├── math_utils.dart            # Mathematical calculations
│   │   └── validation_utils.dart      # Input validation utilities
│   └── services/                      # Core services
│       ├── camera_service.dart        # Camera management
│       ├── pose_detection_service.dart # Pose detection logic
│       ├── face_recognition_service.dart # Face detection & recognition
│       ├── audio_service.dart         # TTS and audio management
│       ├── storage_service.dart       # Local data persistence
│       └── permission_service.dart    # Permission handling
├── features/                          # Feature-based modules
│   ├── registration/                  # Player registration feature
│   │   ├── models/
│   │   │   ├── player_model.dart      # Player data model
│   │   │   └── face_encoding_model.dart # Face encoding data
│   │   ├── screens/
│   │   │   ├── registration_screen.dart # Main registration screen
│   │   │   ├── face_capture_screen.dart # Face capture interface
│   │   │   └── player_list_screen.dart # Registered players list
│   │   ├── providers/
│   │   │   └── registration_provider.dart # Registration state management
│   │   └── widgets/
│   │       ├── player_form_widget.dart # Player input form
│   │       └── face_capture_widget.dart # Face capture interface
│   ├── lobby/                         # Game lobby feature
│   │   ├── models/
│   │   │   ├── lobby_model.dart       # Lobby state model
│   │   │   └── game_session_model.dart # Game session data
│   │   ├── screens/
│   │   │   ├── lobby_screen.dart      # Main lobby interface
│   │   │   └── countdown_screen.dart  # Pre-game countdown
│   │   ├── providers/
│   │   │   └── lobby_provider.dart    # Lobby state management
│   │   └── widgets/
│   │       ├── player_card_widget.dart # Individual player display
│   │       └── countdown_widget.dart  # Countdown timer display
│   ├── game/                          # Main game feature
│   │   ├── models/
│   │   │   ├── game_state.dart        # Game state enumeration
│   │   │   ├── movement_detection.dart # Movement detection logic
│   │   │   ├── pose_landmark.dart     # Pose landmark data
│   │   │   └── game_result.dart       # Game outcome data
│   │   ├── screens/
│   │   │   ├── game_screen.dart       # Main game interface
│   │   │   ├── game_over_screen.dart  # Game completion screen
│   │   │   └── winner_screen.dart     # Winner announcement
│   │   ├── providers/
│   │   │   └── game_provider.dart     # Game state management
│   │   └── widgets/
│   │       ├── light_indicator_widget.dart # Red/green light display
│   │       ├── movement_overlay_widget.dart # Movement detection overlay
│   │       ├── player_status_widget.dart # Player status indicators
│   │       └── game_timer_widget.dart # Game timing display
│   └── settings/                      # Settings feature
│       ├── models/
│       │   └── settings_model.dart    # Settings data model
│       ├── screens/
│       │   ├── settings_screen.dart   # Main settings interface
│       │   └── detection_settings_screen.dart # Detection tuning
│       ├── providers/
│       │   └── settings_provider.dart # Settings state management
│       └── widgets/
│           ├── settings_tile_widget.dart # Settings option display
│           └── slider_setting_widget.dart # Slider-based settings
├── shared/                            # Shared components
│   ├── widgets/                       # Reusable UI components
│   │   ├── camera_preview_widget.dart # Camera preview component
│   │   ├── custom_button_widget.dart  # Custom button component
│   │   ├── loading_widget.dart        # Loading indicator
│   │   ├── error_widget.dart          # Error display component
│   │   └── responsive_layout_widget.dart # Responsive layout helper
│   ├── models/                        # Shared data models
│   │   ├── base_model.dart           # Base model class
│   │   ├── api_response.dart         # API response wrapper
│   │   └── error_model.dart          # Error handling model
│   ├── providers/                     # Shared state providers
│   │   ├── app_state_provider.dart   # Global app state
│   │   └── theme_provider.dart       # Theme management
│   └── extensions/                    # Dart extensions
│       ├── string_extensions.dart     # String utility extensions
│       ├── list_extensions.dart       # List utility extensions
│       └── context_extensions.dart   # BuildContext extensions
└── assets/                            # Application assets
    ├── models/                        # ML models
    │   ├── pose_landmarker.tflite     # Pose detection model
    │   └── face_detector.tflite       # Face detection model
    ├── sounds/                        # Audio files
    │   ├── red_light.mp3             # Red light sound effect
    │   ├── green_light.mp3           # Green light sound effect
    │   ├── elimination.mp3           # Elimination sound effect
    │   ├── countdown.mp3             # Countdown sound effect
    │   └── background_music.mp3       # Background music (optional)
    └── images/                        # Image assets
        ├── icons/                     # App icons
        │   ├── red_light_icon.png     # Red light indicator
        │   ├── green_light_icon.png  # Green light indicator
        │   └── player_icon.png        # Default player icon
        └── backgrounds/               # Background images
            ├── lobby_background.png   # Lobby background
            └── game_background.png    # Game background
```

---

## Key Data Models

### Player Model
```dart
class Player {
  final String id;
  final String name;
  final List<double> faceEncoding;
  final DateTime registeredAt;
  bool isEliminated;
  int eliminationRound;
  
  Player({
    required this.id,
    required this.name,
    required this.faceEncoding,
    required this.registeredAt,
    this.isEliminated = false,
    this.eliminationRound = 0,
  });
}
```

### Game State Model
```dart
enum GameState {
  waiting,
  countdown,
  greenLight,
  redLight,
  gameOver,
}

class GameSession {
  GameState currentState;
  List<Player> players;
  List<Player> eliminatedPlayers;
  int currentRound;
  DateTime lastStateChange;
  bool isDetectingMovement;
  String? winnerId;
}
```

### Movement Detection Model
```dart
class MovementThreshold {
  final double positionThreshold;    // 10cm default
  final double forwardThreshold;     // 15cm default
  final double confidenceThreshold;   // 0.8 default
  
  const MovementThreshold({
    this.positionThreshold = 0.1,
    this.forwardThreshold = 0.15,
    this.confidenceThreshold = 0.8,
  });
}
```

---

## Service Architecture

### Camera Service
- Camera initialization and management
- Permission handling
- Frame capture and processing
- Camera positioning guidance

### Pose Detection Service
- Real-time pose landmark extraction
- Movement detection algorithms
- Player identification through pose mapping
- Performance optimization

### Face Recognition Service
- Face detection using Google ML Kit
- Face encoding generation and storage
- Player identification during gameplay
- Confidence scoring and validation

### Audio Service
- Text-to-Speech configuration (female English voice)
- Voice announcements for game events
- Sound effect playback
- Audio synchronization

### Storage Service
- Player data persistence
- Game settings storage
- Face encoding storage
- Local database management

---

## Navigation Structure

### Route Configuration
```dart
// Main navigation routes
/ -> RegistrationScreen
/lobby -> LobbyScreen
/countdown -> CountdownScreen
/game -> GameScreen
/game-over -> GameOverScreen
/winner -> WinnerScreen
/settings -> SettingsScreen
```

### Screen Flow
1. **Registration** → Player registration and face capture
2. **Lobby** → Player list and game start
3. **Countdown** → 30-second pre-game countdown
4. **Game** → Main gameplay with movement detection
5. **Game Over** → Results and elimination summary
6. **Winner** → Winner announcement
7. **Settings** → Configuration and tuning

---

## Constants Configuration

### Game Constants
```dart
class GameConstants {
  static const int maxPlayers = 4;
  static const int minPlayers = 1;
  static const int countdownDuration = 30; // seconds
  static const int minLightDuration = 3; // seconds
  static const int maxLightDuration = 8; // seconds
  static const double movementThreshold = 0.1; // 10cm
  static const double forwardThreshold = 0.15; // 15cm
}
```

### Detection Constants
```dart
class DetectionConstants {
  static const List<PoseLandmarkType> monitoredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.nose,
  ];
  static const double faceRecognitionThreshold = 0.8;
  static const int detectionFrameRate = 30;
}
```

### Audio Constants
```dart
class AudioConstants {
  static const String voiceLanguage = 'en-US';
  static const String voiceGender = 'female';
  static const double speechRate = 0.8;
  static const double speechPitch = 1.0;
}
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Project setup and dependencies
- [ ] Basic camera integration
- [ ] Player registration system
- [ ] Core service architecture

### Phase 2: Computer Vision (Week 2)
- [ ] Face detection and recognition
- [ ] Pose detection implementation
- [ ] Movement detection algorithm
- [ ] Player identification system

### Phase 3: Game Logic (Week 3)
- [ ] Game state management
- [ ] Lobby system implementation
- [ ] Basic game flow
- [ ] Movement violation detection

### Phase 4: Audio & Polish (Week 4)
- [ ] TTS integration and configuration
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Testing and debugging

---

## Testing Strategy

### Unit Tests
- Movement detection algorithms
- Face recognition accuracy
- Game state transitions
- Audio service functionality

### Integration Tests
- Camera service integration
- Multi-player scenarios
- Performance under load
- Cross-platform compatibility

### User Testing
- Movement detection accuracy with real users
- Face recognition reliability
- Game flow and user experience
- Audio clarity and timing

---

## Performance Considerations

### Optimization Targets
- **Frame Rate**: 30 FPS for smooth detection
- **Detection Frequency**: Check movement every 100ms during red light
- **Memory Management**: Clear old pose data regularly
- **Battery Optimization**: Pause detection during green light

### Resource Management
- Camera frame processing optimization
- Pose detection performance tuning
- Memory usage monitoring
- Battery usage optimization

---

This structure provides a comprehensive foundation for implementing the Red Light, Green Light game with clear separation of concerns, maintainable code organization, and scalable architecture.
