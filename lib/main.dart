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

    // Set error handling for the entire app
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.toString()}');
    };

    // Pre-cache Google Fonts first to prevent black screen
    await GoogleFonts.pendingFonts([
      GoogleFonts.inter(),
    ]);

    // Initialize WorkManager first
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Initialize services sequentially to prevent race conditions
    await YearProgressService.initialize();
    await AgeProgressService.initialize();

    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('Critical error during app startup: $e\n$stack');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      child: Builder(
        builder: (context) {
          final themeProvider = ThemeProvider.of(context);
          return MaterialApp(
            title: 'Track',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider._themeMode,
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
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return Material(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                );
              };
              return child!;
            },
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class _InheritedThemeProvider extends InheritedWidget {
  final _ThemeProviderState data;

  const _InheritedThemeProvider({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedThemeProvider oldWidget) {
    return true;
  }
}

class ThemeProvider extends StatefulWidget {
  final Widget child;

  const ThemeProvider({
    super.key,
    required this.child,
  });

  static _ThemeProviderState of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<_InheritedThemeProvider>();
    assert(result != null, 'No ThemeProvider found in context');
    return result!.data;
  }

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedThemeProvider(
      data: this,
      child: widget.child,
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
  Timer? _updateTimer;
  bool _isInitialized = true; // Change to true by default

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      _updateAllProgress();

      // Start periodic updates
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateAllProgress();
      });

      // Check if we need to show birthday dialog
      if (!AgeProgressService.hasBirthday()) {
        // Show birthday input dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showBirthdayDialog();
        }
      }

      // Set system UI style
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _initializeApp: $e\n$stackTrace');
      // Don't set error state, just update UI with available data
      _updateAllProgress();
    }
  }

  void _updateAllProgress() {
    if (!mounted) return;

    try {
      final yearProgress = YearProgressService.calculateYearProgress();
      final ageProgress = AgeProgressService.calculateAgeProgress();

      if (mounted) {
        setState(() {
          _yearProgress = yearProgress;
          _ageProgress = ageProgress['progress'];
          _currentAge = ageProgress['currentAge'];
          _daysUntilNextBirthday = ageProgress['daysUntilNextBirthday'];
        });
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
      // Don't show error state, just keep previous values
    }
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
                          onPressed: () =>
                              ThemeProvider.of(context).toggleTheme(),
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
