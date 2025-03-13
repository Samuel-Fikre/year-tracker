import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'services/year_progress_service.dart';
import 'services/age_progress_service.dart';
import 'dart:async';

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

    // Initialize services
    await Future.wait([
      YearProgressService.initialize(),
      AgeProgressService.initialize(),
    ]);

    debugPrint('Services initialized successfully');

    // Request permissions after services are initialized
    await YearProgressService.requestNotificationPermissions();

    // Initialize workmanager for background tasks
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'ethiopianYearProgress',
      'updateProgress',
      frequency: const Duration(hours: 1),
    );

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e\n$stackTrace');
    // Run the app even if initialization fails
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethiopian Year Progress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
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
      });
    } catch (e, stackTrace) {
      debugPrint('Error updating progress: $e\n$stackTrace');
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      await AgeProgressService.saveBirthday(picked);
      _updateAllProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress\nTracker',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _showBirthdayDialog,
                              icon: const Icon(Icons.cake_rounded),
                              tooltip: 'Change Birthday',
                            ),
                            IconButton(
                              onPressed: _updateProgress,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Progress Circles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ethiopian Year Progress
                        _buildProgressCircle(
                          'Ethiopian Year',
                          _yearProgress,
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        // Age Progress
                        if (AgeProgressService.hasBirthday()) ...[
                          _buildProgressCircle(
                            'Age $_currentAge',
                            _ageProgress,
                            Theme.of(context).colorScheme.secondary,
                            subtitle: _nextBirthday != null
                                ? '${_daysUntilNextBirthday} days until ${_currentAge + 1}'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(String title, double progress, Color color,
      {String? subtitle}) {
    return GlassmorphicContainer(
      width: 250,
      height: 250,
      borderRadius: 125,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.5),
          color.withOpacity(0.5),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
            if (subtitle != null)
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(delay: 300.ms);
  }
}
