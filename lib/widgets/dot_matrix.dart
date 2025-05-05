import 'package:flutter/material.dart';

class DotMatrix extends StatelessWidget {
  final double progress;
  final int rows;
  final int columns;
  final double dotSize;
  final double horizontalSpacing;
  final double verticalSpacing;
  final String title;
  final String? subtitle;
  final String? rightText;

  const DotMatrix({
    super.key,
    required this.progress,
    required this.title,
    this.subtitle,
    this.rightText,
    this.rows = 18,
    this.columns = 22,
    this.dotSize = 4.0,
    this.horizontalSpacing = 6.0,
    this.verticalSpacing = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDots = rows * columns;
    final filledDots = (totalDots * (progress / 100)).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: -0.3,
                            ),
                      ),
                  ],
                ),
                if (rightText != null)
                  Text(
                    rightText!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                  ),
              ],
            ),
          ),

          // Dot Matrix Grid
          Column(
            children: List.generate(rows, (row) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: verticalSpacing / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(columns, (col) {
                    final index = row * columns + col;
                    final isFilled = index < filledDots;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalSpacing / 2),
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white24 : Colors.black12),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
