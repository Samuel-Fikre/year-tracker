import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

class YearProgressService {
  static Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'progress_channel',
            channelName: 'Progress Notifications',
            channelDescription:
                'Notifications about year and birthday progress',
            defaultColor: const Color(0xFF6C63FF),
            ledColor: const Color(0xFF6C63FF),
            importance: NotificationImportance.High,
            enableVibration: true,
            enableLights: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
            playSound: true,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
        ],
      );

      // Only register workmanager if notifications are allowed
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isAllowed) {
        // Schedule daily check for progress updates
        await Workmanager().registerPeriodicTask(
          'ethiopianYearProgress',
          'checkYearProgress',
          frequency: const Duration(hours: 24),
          initialDelay: const Duration(minutes: 1),
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );

        // Show initial notification
        await checkAndNotify();
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // Continue even if notifications fail
    }
  }

  static Future<void> checkAndNotify() async {
    try {
      final progress = calculateYearProgress();
      final ethiopianDate = ETDateTime.now();

      final isSpecialOccasion = progress >= 99.5 || // Last day
          ethiopianDate.month == 13 || // Pagume
          (progress >= 74.5 && progress <= 75.5) || // Third quarter
          (progress >= 49.5 && progress <= 50.5) || // Half year
          (progress >= 24.5 && progress <= 25.5) || // First quarter
          progress <= 1; // New year

      // Show daily progress notification
      await showYearProgressNotification(isSpecialOccasion: isSpecialOccasion);
    } catch (e) {
      debugPrint('Error checking and notifying progress: $e');
    }
  }

  static double calculateYearProgress() {
    // Get current Ethiopian date
    final ethiopianDate = ETDateTime.now();

    // Calculate days passed in the current Ethiopian year
    int daysPassed = ((ethiopianDate.month - 1) * 30 + ethiopianDate.day);
    if (ethiopianDate.month == 13) {
      daysPassed = 360 + ethiopianDate.day;
    }

    // Check if it's a leap year (every 4 years, with year % 4 == 3)
    bool isLeapYear = ethiopianDate.year % 4 == 3;
    int totalDaysInYear = isLeapYear ? 366 : 365;

    // Calculate progress percentage
    return (daysPassed / totalDaysInYear) * 100;
  }

  static String _getYearProgressMessage() {
    final progress = calculateYearProgress();
    final ethiopianDate = ETDateTime.now();
    final year = ethiopianDate.year;

    // Special milestone messages
    if (progress >= 99.5) {
      // Last day of the year
      return "🎆 Enkutatash is tomorrow! Ready to welcome ${year + 1}! 🎊";
    } else if (ethiopianDate.month == 13) {
      // Pagume
      return "🌟 We're in Pagume! The Ethiopian year $year is wrapping up! 💫";
    } else if (progress >= 74.5 && progress <= 75.5) {
      // Third quarter milestone
      return "🍂 Nine months completed! Three quarters of the Ethiopian year ${year} passed!";
    } else if (progress >= 49.5 && progress <= 50.5) {
      // Halfway milestone
      return "☀️ Major milestone: Halfway through the Ethiopian year ${year}!";
    } else if (progress >= 24.5 && progress <= 25.5) {
      // First quarter milestone
      return "🌱 First quarter of Ethiopian year ${year} completed!";
    } else if (progress <= 1) {
      // New year started
      return "✨ Happy Ethiopian New Year $year! አዲስ አመት!";
    } else {
      // Regular progress update
      return "Ethiopian year $year is ${progress.toStringAsFixed(1)}% complete";
    }
  }

  static Future<void> showYearProgressNotification(
      {bool isSpecialOccasion = false}) async {
    final ethiopianDate = ETDateTime.now();
    final formattedDate = ETDateFormat('MMMM d, yyyy').format(ethiopianDate);

    final message = _getYearProgressMessage();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'progress_channel',
        title: isSpecialOccasion
            ? '🎉 Ethiopian Year Milestone!'
            : 'Ethiopian Year Progress',
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> requestNotificationPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      final userResponse =
          await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
      debugPrint('Notification permission response: $userResponse');

      // If permissions granted, initialize notifications
      if (userResponse) {
        await initialize();
      }
    }
  }
}
