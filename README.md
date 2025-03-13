# Ethiopian Year & Age Progress Tracker

A beautiful Flutter application that tracks both Ethiopian calendar year progress and personal age progress, providing elegant visualizations and timely notifications.

## Features

- 🗓️ **Ethiopian Year Progress**
  - Real-time progress tracking of the current Ethiopian year
  - Beautiful circular progress indicator
  - Special notifications for milestones (New Year, quarters, Pagume)

- 🎂 **Age Progress**
  - Track your age progress in the Ethiopian calendar
  - Birthday notifications and countdown
  - Personalized messages based on progress

- ✨ **Beautiful UI**
  - Glassmorphic design
  - Smooth animations
  - Responsive layout

## Screenshots

[Add your screenshots here]

## Installation

### Prerequisites
- Flutter SDK (2.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/year-tracker.git
cd year-tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## App Icon Location

The app icon should be placed in the following locations:

- Android: `android/app/src/main/res/mipmap-*`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset`

You can use [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons) package to automatically generate icons for both platforms.

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create your feature branch:
```bash
git checkout -b feature/AmazingFeature
```
3. Commit your changes:
```bash
git commit -m 'Add some AmazingFeature'
```
4. Push to the branch:
```bash
git push origin feature/AmazingFeature
```
5. Open a Pull Request

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## Project Structure

```
lib/
├── main.dart              # App entry point
├── services/
│   ├── age_progress_service.dart    # Age tracking logic
│   └── year_progress_service.dart   # Ethiopian year tracking
├── utils/
│   └── ethiopian_date_utils.dart    # Date conversion utilities
└── widgets/              # Custom widgets (if any)
```

## Dependencies

- `ethiopian_datetime`: Ethiopian calendar utilities
- `awesome_notifications`: Local notifications
- `workmanager`: Background tasks
- `shared_preferences`: Local storage
- `google_fonts`: Typography
- `flutter_animate`: Animations
- `glassmorphism`: UI effects

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Ethiopian Calendar algorithms
- Flutter community
- Contributors

## Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)
Project Link: [https://github.com/yourusername/year-tracker](https://github.com/yourusername/year-tracker) 