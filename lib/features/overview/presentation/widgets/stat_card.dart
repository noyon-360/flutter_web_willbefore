import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final String? trend;
  final bool? isPositive;
  final String? trendHint;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.trend,
    this.isPositive,
    this.trendHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: trendHint ?? '',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trend!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: (isPositive ?? true)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Icon(
                              (isPositive ?? true)
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: (isPositive ?? true)
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
