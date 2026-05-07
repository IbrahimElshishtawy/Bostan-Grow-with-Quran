# Quick Start Guide - Gamified Quran Learning App

## 🚀 Getting Started

### 1. Build & Run
```bash
cd E:\FlutterProjects\QuranGlow\quranglow
flutter pub get
flutter run
```

### 2. Access the Gamification Home
Navigate to the "التعلم" (Learning) tab in the home page, or use:
```dart
Navigator.pushNamed(context, AppRoutes.gamificationHome);
```

### 3. Firebase Setup (Required)
1. Create a Firebase project
2. Enable Firestore Database
3. Set up authentication (Email/Password or Google)
4. Add security rules (see GAMIFICATION_README.md)
5. Update `google-services.json` and `GoogleService-Info.plist`

## 📱 Features Overview

### User Profile
- XP tracking and leveling
- Daily streak counter
- Hearts/lives system (0-5)
- Statistics dashboard

### Level Progression
- 30+ levels covering Quran Surahs
- 5 level types with unique styling
- Star rating system (0-3 stars)
- Automatic level unlocking

### Animations
- Smooth node animations
- Glowing effects for active levels
- Curved path connections
- Animated progress bars

## 🎨 Customization

### Change Colors
Edit `lib/features/gamification/presentation/theme/gamification_colors.dart`

### Add New Levels
Modify `_generateDefaultLevels()` in `gamification_controller.dart`

### Adjust Animations
Update durations in `level_node_widget.dart`

## 🔧 Common Tasks

### Complete a Level
```dart
ref.read(gamificationControllerProvider.notifier).completeLevel(
  levelId: 'level_1',
  starsEarned: 3,
  xpEarned: 100,
);
```

### Add XP
```dart
ref.read(gamificationControllerProvider.notifier).addXp(50);
```

### Update Hearts
```dart
ref.read(gamificationControllerProvider.notifier).updateHearts(4);
```

### Update Streak
```dart
ref.read(gamificationControllerProvider.notifier).updateStreak();
```

## 📊 File Structure
```
lib/
├── core/
│   ├── api/
│   │   ├── quran_api_service.dart
│   │   └── recitation_api_service.dart
│   └── models/
│       └── quran_models.dart
└── features/
    └── gamification/
        ├── domain/
        │   └── models/
        │       └── gamification_models.dart
        ├── data/
        │   └── gamification_repository.dart
        ├── application/
        │   ├── gamification_controller.dart
        │   └── providers/
        │       └── gamification_providers.dart
        └── presentation/
            ├── pages/
            │   └── gamification_home_page.dart
            ├── widgets/
            │   ├── gamification_header.dart
            │   ├── level_node_widget.dart
            │   └── level_node_painter.dart
            └── theme/
                └── gamification_colors.dart
```

## 🐛 Troubleshooting

### Firebase Connection Error
- Check Firebase project setup
- Verify Firestore rules
- Ensure user is authenticated

### Animation Lag
- Reduce animation duration
- Check device performance
- Profile with DevTools

### Memory Issues
- Implement pagination
- Clear image cache
- Use proper dispose()

## 📚 Documentation
- `GAMIFICATION_README.md` - Complete guide
- `IMPLEMENTATION_SUMMARY.md` - Project overview
- `FILES_CREATED.txt` - All files created

## 🎯 Next Steps
1. Set up Firebase
2. Test on device
3. Customize colors and levels
4. Add more features (leaderboards, achievements)
5. Deploy to app stores

## 💡 Tips
- Use Riverpod DevTools for debugging
- Check Firebase console for data
- Test with multiple users
- Monitor performance with DevTools

---

For more details, see GAMIFICATION_README.md
