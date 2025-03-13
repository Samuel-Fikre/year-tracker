import 'package:ethiopian_datetime/ethiopian_datetime.dart';

class EthiopianDateUtils {
  static DateTime ethiopianToGregorian(int year, int month, int day) {
    // Ethiopian calendar starts ~7/8 years behind Gregorian
    // and starts on September 11 (or 12 in leap years)
    final isLeapYear = year % 4 == 3;
    final gregorianYear = year + 7;

    // Calculate total days from Ethiopian new year
    int totalDays = (month - 1) * 30 + day - 1;

    // Start from September 11/12
    final startMonth = 9;
    final startDay = isLeapYear ? 12 : 11;

    // Add days to September 11/12
    final start = DateTime(gregorianYear, startMonth, startDay);
    return start.add(Duration(days: totalDays));
  }

  static ETDateTime gregorianToEthiopian(DateTime gregorian) {
    // Find Ethiopian new year in Gregorian calendar
    final isLeapYear = gregorian.year % 4 == 0;
    final ethiopianNewYear = DateTime(gregorian.year, 9, isLeapYear ? 12 : 11);

    // If date is before Ethiopian new year, use previous Ethiopian year
    if (gregorian.isBefore(ethiopianNewYear)) {
      final ethiopianYear = gregorian.year - 8;
      final dayDiff = ethiopianNewYear.difference(gregorian).inDays;

      // Calculate month and day
      final daysInLastMonth = 30;
      final month = 13 - (dayDiff ~/ daysInLastMonth);
      final day = daysInLastMonth - (dayDiff % daysInLastMonth);

      return ETDateTime(ethiopianYear, month, day);
    } else {
      final ethiopianYear = gregorian.year - 7;
      final dayDiff = gregorian.difference(ethiopianNewYear).inDays;

      // Calculate month and day
      final month = (dayDiff ~/ 30) + 1;
      final day = (dayDiff % 30) + 1;

      return ETDateTime(ethiopianYear, month, day);
    }
  }

  static final List<String> monthNames = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume'
  ];

  static String formatEthiopianDate(ETDateTime date) {
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
}
