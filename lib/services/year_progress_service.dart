import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class YearProgressService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // no icon for now, we'll add it later if needed
      [
        NotificationChannel(
          channelKey: 'year_progress_channel',
          channelName: 'Ethiopian Year Progress',
          channelDescription:
              'Shows the progress of the current Ethiopian year',
          defaultColor: Colors.purple,
          ledColor: Colors.purple,
          importance: NotificationImportance.High,
        ),
      ],
    );
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

  static Future<void> showYearProgressNotification() async {
    double progress = calculateYearProgress();
    String progressText = progress.toStringAsFixed(2);

    // Get formatted Ethiopian date
    final ethiopianDate = ETDateTime.now();
    final formattedDate = ETDateFormat('MMMM d, yyyy').format(ethiopianDate);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'year_progress_channel',
        title: 'Ethiopian Year Progress',
        body: '$progressText% of the Ethiopian year $formattedDate has passed',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<void> requestNotificationPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}
