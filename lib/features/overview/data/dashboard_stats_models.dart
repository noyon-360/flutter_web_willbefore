import 'package:intl/intl.dart';

enum StatMetric { revenue, orders, users, products }

enum StatPeriod {
  day('Day'),
  week('Week'),
  month('Month'),
  year('Year');

  const StatPeriod(this.label);
  final String label;
}

/// A single time slice of a chart (one hour, one day or one month).
class StatBucket {
  const StatBucket({
    required this.label,
    required this.fullLabel,
    required this.start,
    required this.end,
  });

  final String label;
  final String fullLabel;
  final DateTime start;
  final DateTime end;
}

class SeriesPoint {
  const SeriesPoint({
    required this.label,
    required this.fullLabel,
    required this.value,
    required this.isFuture,
  });

  final String label;
  final String fullLabel;
  final double value;

  /// Buckets that have not started yet are kept so the x-axis spans the whole
  /// period, but they are not drawn.
  final bool isFuture;
}

class Kpi {
  const Kpi({required this.total, this.trendPercent});

  final double total;

  /// Month-to-date vs the same span of the previous month. Null when there is
  /// nothing to compare against.
  final double? trendPercent;
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Earliest year the period navigator lets you go back to.
const kStatsFirstYear = 2024;

/// Start of the [period] that contains [date] (week starts on Monday). Used as
/// the cache key so every day of one month shares the same result.
DateTime normalizeAnchor(StatPeriod period, DateTime date) {
  switch (period) {
    case StatPeriod.day:
      return DateTime(date.year, date.month, date.day);
    case StatPeriod.week:
      return DateTime(date.year, date.month, date.day - (date.weekday - 1));
    case StatPeriod.month:
      return DateTime(date.year, date.month);
    case StatPeriod.year:
      return DateTime(date.year);
  }
}

/// The period containing [date], shifted by [direction] periods.
DateTime shiftAnchor(StatPeriod period, DateTime date, int direction) {
  final s = normalizeAnchor(period, date);
  switch (period) {
    case StatPeriod.day:
      return DateTime(s.year, s.month, s.day + direction);
    case StatPeriod.week:
      return DateTime(s.year, s.month, s.day + 7 * direction);
    case StatPeriod.month:
      return DateTime(s.year, s.month + direction);
    case StatPeriod.year:
      return DateTime(s.year + direction);
  }
}

String periodLabel(StatPeriod period, DateTime date) {
  final s = normalizeAnchor(period, date);
  switch (period) {
    case StatPeriod.day:
      return DateFormat('MMM d, yyyy').format(s);
    case StatPeriod.week:
      final e = DateTime(s.year, s.month, s.day + 6);
      return '${DateFormat('MMM d').format(s)} – '
          '${DateFormat('MMM d, yyyy').format(e)}';
    case StatPeriod.month:
      return DateFormat('MMMM yyyy').format(s);
    case StatPeriod.year:
      return '${s.year}';
  }
}

/// Buckets for the period containing [now] (pass the selected anchor date).
List<StatBucket> buildBuckets(StatPeriod period, DateTime now) {
  switch (period) {
    case StatPeriod.day:
      final fmt = DateFormat('MMM d, HH:00');
      return List.generate(24, (h) {
        final start = DateTime(now.year, now.month, now.day, h);
        return StatBucket(
          label: h.toString().padLeft(2, '0'),
          fullLabel: fmt.format(start),
          start: start,
          end: DateTime(now.year, now.month, now.day, h + 1),
        );
      });
    case StatPeriod.week:
      final fmt = DateFormat('EEE, MMM d');
      final dayOffset = now.day - (now.weekday - 1);
      return List.generate(7, (i) {
        final start = DateTime(now.year, now.month, dayOffset + i);
        return StatBucket(
          label: _weekDays[i],
          fullLabel: fmt.format(start),
          start: start,
          end: DateTime(start.year, start.month, start.day + 1),
        );
      });
    case StatPeriod.month:
      final fmt = DateFormat('EEE, MMM d');
      final days = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(days, (i) {
        final start = DateTime(now.year, now.month, i + 1);
        return StatBucket(
          label: '${i + 1}',
          fullLabel: fmt.format(start),
          start: start,
          end: DateTime(now.year, now.month, i + 2),
        );
      });
    case StatPeriod.year:
      final fmt = DateFormat('MMMM yyyy');
      return List.generate(12, (i) {
        final start = DateTime(now.year, i + 1);
        return StatBucket(
          label: _monthNames[i],
          fullLabel: fmt.format(start),
          start: start,
          end: DateTime(now.year, i + 2),
        );
      });
  }
}
