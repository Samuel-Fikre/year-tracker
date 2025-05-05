import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import 'services/year_progress_service.dart';
import 'services/age_progress_service.dart';
import 'dart:async';
import 'widgets/dot_matrix.dart';
import 'widgets/birthday_picker.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'checkYearProgress':
        await YearProgressService.checkAndNotify();
        break;
      case 'checkBirthdayProgress':
        await AgeProgressService.showBirthdayNotification();
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize WorkManager first
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    } catch (e) {
      debugPrint('Workmanager initialization error: $e');
    }

    // Then initialize services that depend on WorkManager
    try {
      await YearProgressService.initialize();
    } catch (e) {
      debugPrint('YearProgress initialization error: $e');
    }

    try {
      await AgeProgressService.initialize();
    } catch (e) {
      debugPrint('AgeProgress initialization error: $e');
    }

    try {
      await YearProgressService.requestNotificationPermissions();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('Critical error during app startup: $e\n$stack');
    // Ensure the app runs even if there are initialization errors
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.grey[800]!,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          background: Colors.white,
          onBackground: Colors.black,
        ),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          titleLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.grey[300]!,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
          background: Colors.black,
          onBackground: Colors.white,
        ),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          titleLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // This will follow system theme
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _yearProgress = 0.0;
  double _ageProgress = 0.0;
  int _currentAge = 0;
  int _daysUntilNextBirthday = 0;
  DateTime? _nextBirthday;
  Timer? _updateTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Set up timer to update progress every minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAllProgress();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateAllProgress() {
    if (!mounted) return;

    try {
      final yearProgress = YearProgressService.calculateYearProgress();
      final ageProgress = AgeProgressService.calculateAgeProgress();

      setState(() {
        _yearProgress = yearProgress;
        _ageProgress = ageProgress['progress'];
        _currentAge = ageProgress['currentAge'];
        _nextBirthday = ageProgress['nextBirthday'];
        _daysUntilNextBirthday = ageProgress['daysUntilNextBirthday'];
        _isInitialized = true;
      });
    } catch (e, stackTrace) {
      debugPrint('Error updating progress: $e\n$stackTrace');
      setState(
          () => _isInitialized = true); // Still mark as initialized to show UI
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Only initialize services in main.dart, not here
      debugPrint('Initializing app UI');

      // Update progress immediately
      _updateAllProgress();

      // Check if we need to show birthday dialog
      if (!AgeProgressService.hasBirthday()) {
        // Show birthday input dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showBirthdayDialog();
        });
      }

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _initializeApp: $e\n$stackTrace');
    }
  }

  void _updateProgress() {
    _updateAllProgress();
  }

  Future<void> _showBirthdayDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BirthdayPicker(
          onDateSelected: (date) async {
            await AgeProgressService.saveBirthday(date);
            _updateAllProgress();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          color: isDark ? Colors.white : Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Track',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.cake_outlined,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          onPressed: _showBirthdayDialog,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            // Toggle theme
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Ethiopian Year Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DotMatrix(
                  progress: _yearProgress,
                  title: 'Ethiopian Year',
                  rightText: '${_yearProgress.toStringAsFixed(1)}%',
                ),
              ),

              const SizedBox(height: 24),

              // Age Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DotMatrix(
                  progress: _ageProgress,
                  title: '${_ageProgress.toStringAsFixed(1)}%',
                  subtitle: _daysUntilNextBirthday > 0
                      ? '$_daysUntilNextBirthday days until ${_currentAge + 1}'
                      : null,
                  rightText: 'Age $_currentAge',
                ),
              ),

              SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.2), // Dynamic bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
