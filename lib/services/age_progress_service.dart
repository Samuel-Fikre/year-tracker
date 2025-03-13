import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

class AgeProgressService {
  static const String _birthdayKey = 'birthday';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Schedule weekly birthday notifications
    await Workmanager().registerPeriodicTask(
      'birthdayProgress',
      'checkBirthdayProgress',
      frequency: const Duration(days: 7), // Check weekly
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );
  }

  static Future<void> checkAndNotify() async {
    if (!hasBirthday()) return;
    await showBirthdayNotification();
  }

  static Future<void> _scheduleWeeklyNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'progress_channel',
        title: 'Birthday Progress Update',
        body: _getBirthdayMessage(),
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationInterval(
        interval: 7 * 24 * 60 * 60, // Weekly interval in seconds
        repeats: true,
      ),
    );
  }

  static String _getBirthdayMessage() {
    final progress = calculateAgeProgress();
    final progressPercent = progress['progress'] as double;
    final daysLeft = progress['daysUntilNextBirthday'] as int;
    final nextAge = (progress['currentAge'] as int) + 1;

    if (progressPercent >= 99) {
      return "🎉 Happy Birthday! Tomorrow you'll be $nextAge! 🎂";
    } else if (progressPercent >= 90) {
      return "⏳ Almost there! Only $daysLeft days until you turn $nextAge! 🎈";
    } else if (progressPercent >= 75) {
      return "🎯 The countdown is on! $daysLeft days until your big day!";
    } else if (progressPercent >= 50) {
      return "🌟 Halfway to your next birthday! Making every day count!";
    } else if (progressPercent >= 25) {
      return "🌱 Growing wiser every day! $daysLeft days until you level up!";
    } else {
      return "🎊 Your journey to $nextAge is just beginning! Making memories along the way!";
    }
  }

  static bool hasBirthday() {
    if (_prefs == null) {
      debugPrint('Warning: SharedPreferences not initialized');
      return false;
    }
    return _prefs!.getString(_birthdayKey) != null;
  }

  static Future<void> saveBirthday(DateTime birthday) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    // Format with padded month and day to ensure proper ISO8601 format
    final formattedDate =
        '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}';
    await _prefs?.setString(_birthdayKey, formattedDate);
  }

  static DateTime? getBirthday() {
    final birthdayStr = _prefs?.getString(_birthdayKey);
    if (birthdayStr == null) return null;

    // Split the date string and parse each component
    final parts = birthdayStr.split('-');
    if (parts.length != 3) return null;

    return DateTime(
      int.parse(parts[0]), // year
      int.parse(parts[1]), // month
      int.parse(parts[2]), // day
    );
  }

  static Map<String, dynamic> calculateAgeProgress() {
    final birthday = getBirthday();
    if (birthday == null) {
      return {
        'progress': 0.0,
        'currentAge': 0,
        'nextBirthday': null,
        'daysUntilNextBirthday': 0,
      };
    }

    final now = DateTime.now();

    // Calculate current age
    int currentAge = now.year - birthday.year;
    // Adjust age if birthday hasn't occurred this year
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      currentAge--;
    }

    // Calculate next birthday
    final nextBirthday = DateTime(
      now.year +
          (now.month > birthday.month ||
                  (now.month == birthday.month && now.day >= birthday.day)
              ? 1
              : 0),
      birthday.month,
      birthday.day,
    );

    // Calculate days until next birthday
    final daysUntilNextBirthday = nextBirthday.difference(now).inDays;

    // Calculate last birthday
    final lastBirthday = DateTime(
      now.year -
          (now.month < birthday.month ||
                  (now.month == birthday.month && now.day < birthday.day)
              ? 1
              : 0),
      birthday.month,
      birthday.day,
    );

    // Calculate progress percentage
    final daysInYear = nextBirthday.difference(lastBirthday).inDays;
    final daysSinceLastBirthday = now.difference(lastBirthday).inDays;
    final progress = (daysSinceLastBirthday / daysInYear) * 100;

    return {
      'progress': progress,
      'currentAge': currentAge,
      'nextBirthday': nextBirthday,
      'daysUntilNextBirthday': daysUntilNextBirthday,
    };
  }

  static String formatBirthday(DateTime birthday) {
    return DateFormat('MMMM d, yyyy').format(birthday);
  }

  static Future<void> showBirthdayNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'progress_channel',
        title: 'Birthday Progress',
        body: _getBirthdayMessage(),
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
