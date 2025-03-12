import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AgeProgressService {
  static const String _birthdayKey = 'birthday';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool hasBirthday() {
    return _prefs?.getString(_birthdayKey) != null;
  }

  static Future<void> saveBirthday(DateTime birthday) async {
    await _prefs?.setString(_birthdayKey, birthday.toIso8601String());
  }

  static DateTime? getBirthday() {
    final birthdayStr = _prefs?.getString(_birthdayKey);
    if (birthdayStr == null) return null;
    return DateTime.parse(birthdayStr);
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
}
