import 'package:flutter/material.dart';

class BirthdayPicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const BirthdayPicker({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<BirthdayPicker> createState() => _BirthdayPickerState();
}

class _BirthdayPickerState extends State<BirthdayPicker> {
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  late List<int> days;
  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = now.day;
    selectedMonth = now.month;
    selectedYear = now.year;
    days = _getDaysInMonth(selectedMonth, selectedYear);
    dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    monthController =
        FixedExtentScrollController(initialItem: selectedMonth - 1);
    yearController = FixedExtentScrollController(initialItem: now.year - 1950);
  }

  @override
  void dispose() {
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  List<int> _getDaysInMonth(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  void _updateDays() {
    setState(() {
      days = _getDaysInMonth(selectedMonth, selectedYear);
      if (selectedDay > days.length) {
        selectedDay = days.length;
        dayController.jumpToItem(selectedDay - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Days Column
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: dayController,
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => selectedDay = days[index]);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: days.length,
                      builder: (context, index) {
                        return Center(
                          child: Text(
                            days[index].toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Months Column
                Expanded(
                  flex: 2,
                  child: ListWheelScrollView.useDelegate(
                    controller: monthController,
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMonth = index + 1;
                        _updateDays();
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: months.length,
                      builder: (context, index) {
                        return Center(
                          child: Text(
                            months[index],
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Years Column
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: yearController,
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedYear = 1950 + index;
                        _updateDays();
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: DateTime.now().year - 1950 + 1,
                      builder: (context, index) {
                        return Center(
                          child: Text(
                            (1950 + index).toString(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Set Birthday Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final selectedDate =
                      DateTime(selectedYear, selectedMonth, selectedDay);
                  widget.onDateSelected(selectedDate);
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Set your Birthday',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
