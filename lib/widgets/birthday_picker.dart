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

  int selectedMonth = DateTime.now().month - 1;
  int selectedYear = DateTime.now().year;
  final ScrollController _monthController = ScrollController();
  final ScrollController _yearController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month Picker
          SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _monthController,
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(() => selectedMonth = index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: months.length,
                builder: (context, index) {
                  return Center(
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color:
                            index == selectedMonth ? textColor : inactiveColor,
                        fontSize: index == selectedMonth ? 20 : 16,
                        fontWeight: index == selectedMonth
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Year Picker
          SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              controller: _yearController,
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                setState(
                    () => selectedYear = DateTime.now().year - 100 + index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 101, // 100 years back from current year
                builder: (context, index) {
                  final year = DateTime.now().year - 100 + index;
                  return Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        color: year == selectedYear ? textColor : inactiveColor,
                        fontSize: year == selectedYear ? 20 : 16,
                        fontWeight: year == selectedYear
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Set Birthday Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final selectedDate =
                      DateTime(selectedYear, selectedMonth + 1);
                  widget.onDateSelected(selectedDate);
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Set your Birthday'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
