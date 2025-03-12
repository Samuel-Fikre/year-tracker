import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'services/year_progress_service.dart';
import 'services/age_progress_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await YearProgressService.showYearProgressNotification();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await YearProgressService.initialize();
  await YearProgressService.requestNotificationPermissions();
  await AgeProgressService.initialize();

  // Initialize workmanager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    'ethiopianYearProgress',
    'updateProgress',
    frequency: const Duration(hours: 1),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethiopian Year Progress',
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

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _checkBirthday();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _checkBirthday() async {
    if (!AgeProgressService.hasBirthday()) {
      // Show birthday input dialog after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _showBirthdayDialog();
      });
    }
    _updateAgeProgress();
  }

  void _updateProgress() {
    setState(() {
      _yearProgress = YearProgressService.calculateYearProgress();
      _updateAgeProgress();
    });
  }

  void _updateAgeProgress() {
    final progress = AgeProgressService.calculateAgeProgress();
    setState(() {
      _ageProgress = progress['progress'];
      _currentAge = progress['currentAge'];
      _nextBirthday = progress['nextBirthday'];
      _daysUntilNextBirthday = progress['daysUntilNextBirthday'];
    });
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

    if (picked != null) {
      await AgeProgressService.saveBirthday(picked);
      _updateAgeProgress();
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
                          'Progress\nTrackers',
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
                        // Notification Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            await YearProgressService
                                .showYearProgressNotification();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Notification sent!',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_active_rounded),
                          label: Text(
                            'Show Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.3, end: 0, delay: 400.ms),
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
