# Gamified Quran Learning Home Screen - Implementation Guide

## Overview

A production-ready Flutter gamified Quran learning app with a Duolingo/Candy Crush-style progression map. The app features a modern Islamic minimal UI with green, gold, white, and dark navy colors, smooth animations, and comprehensive Firebase integration.

## Architecture

### Clean Architecture Pattern
```
lib/features/gamification/
├── domain/
│   └── models/
│       └── gamification_models.dart          # Core domain models
├── data/
│   └── gamification_repository.dart          # Firebase & Firestore integration
├── application/
│   ├── gamification_controller.dart          # Riverpod StateNotifier
│   └── providers/
│       └── gamification_providers.dart       # Riverpod providers
└── presentation/
    ├── pages/
    │   └── gamification_home_page.dart       # Main progression map UI
    ├── widgets/
    │   ├── gamification_header.dart          # User profile & stats header
    │   ├── level_node_widget.dart            # Individual level nodes
    │   └── level_node_painter.dart           # Custom painters for paths
    └── theme/
        └── gamification_colors.dart          # Color palette & theme
```

## Core Components

### 1. Domain Models (`gamification_models.dart`)

**GameLevel** - Individual level with:
- Type: Surah, Tajweed, Review, Boss Test, Daily Challenge
- Completion tracking (stars, XP, percentage)
- Lock/unlock states
- Audio availability

**UserGameProfile** - User progression data:
- Total XP and current level
- Hearts (lives) system
- Daily streak tracking
- Levels completed and total stars

**GameState** - Overall game state:
- User profile
- All levels
- Current level calculation
- Due review levels

### 2. API Services

**QuranApiService** (`lib/core/api/quran_api_service.dart`)
- Integrates with api.alquran.cloud and Quran.com APIs
- Methods: getSurah, getAyahsForSurah, getTafsir, getTranslation, searchAyahs

**RecitationApiService** (`lib/core/api/recitation_api_service.dart`)
- Audio recitation support for multiple reciters
- Reciters: Mishary Rashid, Al-Husary, Abdul Basit
- Methods: getAyahAudio, getSurahAudio, getRecitationMetadata

### 3. State Management (Riverpod)

**GameificationController** - StateNotifier managing:
- Level initialization and progression
- XP and streak updates
- Level completion logic
- Automatic next level unlocking

**Providers**:
- `gamificationControllerProvider` - Main state
- `userProfileProvider` - User data
- `levelsProvider` - All levels
- `currentLevelProvider` - Active level
- Stream providers for real-time updates

### 4. UI Components

**GameificationHeader**
- User profile with avatar
- XP progress bar with level info
- Hearts/lives display
- Daily streak counter with fire icon
- Motivational Islamic quotes (rotates daily)
- Statistics cards (XP, Levels, Stars)

**LevelNodeWidget**
- Circular node with level information
- Animated glow effect for active levels
- Star rating display (0-3 stars)
- XP reward badge
- Lock overlay for locked levels
- Tap to view level details

**LevelPathPainter**
- Custom painter for curved connecting paths
- Animated path drawing on completion
- Islamic geometric decorations
- Smooth transitions between levels

**GameificationHomePage**
- Vertical scrollable progression map
- Header with user stats
- Due reviews section
- Level nodes with curved paths
- Bottom sheet for level details
- Responsive design

## Color Palette

```dart
Primary Green:      #1B5E20
Primary Green Light: #2E7D32
Gold Accent:        #D4AF37
White:              #FFFFFF
Dark Navy:          #0B0F12
```

## Features Implemented

### ✅ Level Progression System
- 30+ default levels covering Quran Surahs
- Multiple level types with unique styling
- Star rating system (0-3 stars)
- XP reward system
- Automatic level unlocking

### ✅ User Profile System
- XP tracking and leveling
- Daily streak counter
- Hearts/lives system
- Statistics tracking
- Profile persistence with Firebase

### ✅ UI/UX
- Smooth animations and transitions
- Responsive design for all screen sizes
- Islamic minimal design aesthetic
- Curved path connections between levels
- Glowing effects for active levels
- Bottom sheet level details

### ✅ Firebase Integration
- Firestore for user profiles and levels
- Real-time data synchronization
- Batch operations for efficiency
- Stream providers for live updates

### ✅ API Integration
- Quran API placeholders
- Audio recitation API placeholders
- Multiple reciter support
- Tafsir and translation support

## Integration with Existing App

### Routes Added
- `/gamification` - Main gamification home page

### Home Page Updated
- Added "التعلم" (Learning) tab
- Integrated GameificationHomePage
- Maintains existing navigation structure

### Navigation
```dart
// Access gamification home
Navigator.pushNamed(context, AppRoutes.gamificationHome);

// Or from home page tabs
HomePage -> Tab 1 (التعلم) -> GameificationHomePage
```

## Firebase Setup Required

### Firestore Collections
```
users/
  {userId}/
    gameProfile/
      profile/                    # User profile document
    levels/
      {levelId}/                  # Individual level documents
```

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      match /gameProfile/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
      match /levels/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

## Usage Example

```dart
// In a widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  
  return gameStateAsync.when(
    loading: () => LoadingWidget(),
    error: (error, st) => ErrorWidget(error: error),
    data: (gameState) => GameificationHomePage(),
  );
}

// Complete a level
ref.read(gamificationControllerProvider.notifier).completeLevel(
  levelId: 'level_1',
  starsEarned: 3,
  xpEarned: 100,
);

// Add XP
ref.read(gamificationControllerProvider.notifier).addXp(50);

// Update hearts
ref.read(gamificationControllerProvider.notifier).updateHearts(4);
```

## Customization

### Add New Level Types
1. Add to `LevelType` enum in `gamification_models.dart`
2. Create widget in `lib/features/gamification/presentation/widgets/level_types/`
3. Update `_getLevelTypeIcon()` in `level_node_widget.dart`

### Modify Colors
Edit `lib/features/gamification/presentation/theme/gamification_colors.dart`

### Change Level Generation
Modify `_generateDefaultLevels()` in `gamification_controller.dart`

### Adjust Animations
Update animation durations in `level_node_widget.dart` and `level_node_painter.dart`

## Performance Considerations

- Levels are paginated in ListView for memory efficiency
- Firebase batch operations for bulk updates
- Stream providers for real-time updates without polling
- CustomPaint for efficient path rendering
- AnimatedBuilder for smooth animations

## Testing

### Unit Tests
- Test GameLevel model serialization
- Test UserGameProfile calculations
- Test GameificationController logic

### Widget Tests
- Test LevelNodeWidget rendering
- Test GameificationHeader display
- Test level detail sheet

### Integration Tests
- Test Firebase sync
- Test level completion flow
- Test streak updates

## Future Enhancements

1. **Leaderboards** - Global and friend rankings
2. **Achievements** - Badge system for milestones
3. **Social Features** - Share progress, challenges
4. **Offline Support** - Hive local caching
5. **Analytics** - Track learning patterns
6. **Notifications** - Streak reminders, level unlocks
7. **Customization** - Avatar selection, themes
8. **Multiplayer** - Compete with friends

## Dependencies

All required packages are already in `pubspec.yaml`:
- `flutter_riverpod` - State management
- `firebase_core`, `cloud_firestore`, `firebase_auth` - Backend
- `just_audio` - Audio playback
- `lottie` - Animations
- `dio` - HTTP client
- `hive`, `hive_flutter` - Local storage

## Troubleshooting

### Firebase Connection Issues
- Verify Firebase project setup
- Check Firestore rules
- Ensure user is authenticated

### Animation Lag
- Reduce animation duration
- Optimize CustomPaint rendering
- Use `const` constructors

### Memory Issues
- Implement pagination for large level lists
- Clear cached images
- Use `dispose()` properly

## License

Part of QuranGlow - Islamic Quran Learning Platform

## Support

For issues or questions, refer to the plan file at:
`C:\Users\Ibrahem\.claude\plans\temporal-foraging-wilkinson.md`
