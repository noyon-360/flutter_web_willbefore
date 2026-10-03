import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../../data/dashboard_stats_models.dart';
import '../providers/dashboard_stats_provider.dart';

extension StatMetricStyle on StatMetric {
  String get label => switch (this) {
    StatMetric.revenue => 'Revenue',
    StatMetric.orders => 'Orders',
    StatMetric.users => 'Users',
    StatMetric.products => 'Products',
  };

  Color get color => switch (this) {
    StatMetric.revenue => AppColors.primaryLaurel,
    StatMetric.orders => const Color(0xFF3B82F6),
    StatMetric.users => const Color(0xFFF59E0B),
    StatMetric.products => const Color(0xFF8B5CF6),
  };

  IconData get icon => switch (this) {
    StatMetric.revenue => Icons.attach_money,
    StatMetric.orders => Icons.shopping_cart,
    StatMetric.users => Icons.people,
    StatMetric.products => Icons.inventory,
  };

  String format(double v) => this == StatMetric.revenue
      ? NumberFormat.currency(symbol: r'$').format(v)
      : NumberFormat.decimalPattern().format(v.round());

  String formatCompact(double v) => this == StatMetric.revenue
      ? NumberFormat.compactCurrency(symbol: r'$').format(v)
      : NumberFormat.compact().format(v);
}

class OverviewTrendCard extends ConsumerWidget {
  const OverviewTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controls = ref.watch(chartControlsProvider);
    final notifier = ref.read(chartControlsProvider.notifier);

    // All four series are watched even when hidden, so they load in parallel
    // and toggling a line is instant (no refetch).
    final series = {
      for (final m in StatMetric.values)
        m: ref.watch(
          statSeriesProvider((m, controls.period, controls.periodStart)),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message:
                        'Scaled: every line fills the chart height so small '
                        'series stay visible. Actual: one shared axis.',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Pill(
                          label: 'Scaled',
                          selected: controls.scaled,
                          onTap: () => notifier.setScaled(true),
                        ),
                        _Pill(
                          label: 'Actual',
                          selected: !controls.scaled,
                          onTap: () => notifier.setScaled(false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  for (final p in StatPeriod.values)
                    _Pill(
                      label: p.label,
                      selected: p == controls.period,
                      onTap: () => notifier.setPeriod(p),
                    ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => refreshDashboard(ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PeriodNavigator(controls: controls),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in StatMetric.values)
                _LegendChip(
                  metric: m,
                  active: controls.visible.contains(m),
                  points: series[m]!.value,
                  loading: series[m]!.isLoading,
                  onTap: () => notifier.toggle(m),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: _Chart(
              series: {for (final e in series.entries) e.key: e.value},
              controls: controls,
            ),
          ),
        ],
      ),
    );
  }
}

/// `‹  October 2026  ›  [Today]` - browse past days, weeks, months and years.
class _PeriodNavigator extends ConsumerWidget {
  const _PeriodNavigator({required this.controls});

  final ChartControls controls;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(chartControlsProvider.notifier);
    final now = DateTime.now();
    DateTime? picked;
    switch (controls.period) {
      case StatPeriod.day:
      case StatPeriod.week:
        picked = await showDatePicker(
          context: context,
          initialDate: controls.anchor,
          firstDate: DateTime(kStatsFirstYear),
          lastDate: now,
        );
      case StatPeriod.month:
      case StatPeriod.year:
        picked = await _pickMonthOrYear(
          context,
          controls.anchor,
          pickMonth: controls.period == StatPeriod.month,
        );
    }
    if (picked != null) notifier.setAnchor(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chartControlsProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous',
          icon: const Icon(Icons.chevron_left),
          onPressed: controls.canGoBack ? () => notifier.shift(-1) : null,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pick(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondaryHintColor,
                ),
                const SizedBox(width: 8),
                Text(
                  periodLabel(controls.period, controls.anchor),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next',
          icon: const Icon(Icons.chevron_right),
          onPressed: controls.isCurrentPeriod ? null : () => notifier.shift(1),
        ),
        if (!controls.isCurrentPeriod) ...[
          const SizedBox(width: 4),
          _Pill(label: 'Today', selected: false, onTap: notifier.goToToday),
        ],
      ],
    );
  }
}

/// Month picker (year arrows + 12 months) or, with [pickMonth] false, a plain
/// year list. Returns the first day of the chosen month / year.
Future<DateTime?> _pickMonthOrYear(
  BuildContext context,
  DateTime initial, {
  required bool pickMonth,
}) {
  final now = DateTime.now();
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      var year = initial.year;
      return StatefulBuilder(
        builder: (ctx, setState) {
          final Widget content;
          if (pickMonth) {
            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: year > kStatsFirstYear
                          ? () => setState(() => year--)
                          : null,
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: year < now.year
                          ? () => setState(() => year++)
                          : null,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      ChoiceChip(
                        label: Text(DateFormat.MMM().format(DateTime(2000, m))),
                        selected: year == initial.year && m == initial.month,
                        onSelected: DateTime(year, m).isAfter(now)
                            ? null
                            : (_) => Navigator.pop(ctx, DateTime(year, m)),
                      ),
                  ],
                ),
              ],
            );
          } else {
            content = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var y = now.year; y >= kStatsFirstYear; y--)
                  ChoiceChip(
                    label: Text('$y'),
                    selected: y == initial.year,
                    onSelected: (_) => Navigator.pop(ctx, DateTime(y)),
                  ),
              ],
            );
          }
          return AlertDialog(
            title: Text(pickMonth ? 'Select month' : 'Select year'),
            content: SizedBox(width: 320, child: content),
          );
        },
      );
    },
  );
}

class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.controls});

  final Map<StatMetric, AsyncValue<List<SeriesPoint>>> series;
  final ChartControls controls;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      for (final m in StatMetric.values)
        if (controls.visible.contains(m) && series[m]!.value != null) m,
    ];
    final anyLoading = series.values.any((s) => s.isLoading);
    final errors = [
      for (final e in series.entries)
        if (e.value.hasError && controls.visible.contains(e.key)) e,
    ];

    if (metrics.isEmpty) {
      if (errors.isNotEmpty) return _ErrorNote(errors: errors);
      return const Center(child: CircularProgressIndicator());
    }

    final labels = series[metrics.first]!.value!;
    final n = labels.length;
    final scaled = controls.scaled;

    double peak(StatMetric m) =>
        series[m]!.value!.fold<double>(0, (a, p) => p.value > a ? p.value : a);
    final peaks = {for (final m in metrics) m: peak(m)};
    final overallPeak = peaks.values.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = scaled ? 1.1 : (overallPeak == 0 ? 1.0 : overallPeak * 1.15);

    final bars = [
      for (final m in metrics)
        LineChartBarData(
          spots: [
            for (var i = 0; i < n; i++)
              if (!series[m]!.value![i].isFuture)
                FlSpot(
                  i.toDouble(),
                  scaled
                      ? (peaks[m] == 0
                            ? 0
                            : series[m]!.value![i].value / peaks[m]!)
                      : series[m]!.value![i].value,
                ),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: m.color,
          barWidth: 2.5,
          dotData: FlDotData(show: n <= 31),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                m.color.withValues(alpha: scaled ? 0.08 : 0.12),
                m.color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
    ];

    const axisStyle = TextStyle(
      fontSize: 11,
      color: AppColors.textSecondaryHintColor,
    );
    final xInterval = n > 12 ? (n / 8).ceilToDouble() : 1.0;

    return Stack(
      children: [
        LineChart(
          LineChartData(
            minX: 0,
            maxX: (n - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineBarsData: bars,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: scaled ? 0.25 : null,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppColors.borderColor, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= n) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(labels[i].label, style: axisStyle),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !scaled,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        NumberFormat.compact().format(value),
                        style: axisStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.white,
                tooltipBorder: const BorderSide(color: AppColors.borderColor),
                getTooltipItems: (spots) => [
                  for (final (k, s) in spots.indexed)
                    _tooltipItem(
                      metric: metrics[s.barIndex],
                      point: series[metrics[s.barIndex]]!.value![s.spotIndex],
                      showDate: k == 0,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (anyLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (errors.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Tooltip(
              message: errors
                  .map((e) => '${e.key.label}: ${e.value.error}')
                  .join('\n'),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  LineTooltipItem _tooltipItem({
    required StatMetric metric,
    required SeriesPoint point,
    required bool showDate,
  }) {
    return LineTooltipItem(
      showDate ? '${point.fullLabel}\n' : '',
      const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryColor,
      ),
      children: [
        TextSpan(
          text: '● ',
          style: TextStyle(color: metric.color, fontWeight: FontWeight.w400),
        ),
        TextSpan(
          text: '${metric.label}: ${metric.format(point.value)}',
          style: const TextStyle(
            color: AppColors.textSecondaryColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.errors});

  final List<MapEntry<StatMetric, AsyncValue<List<SeriesPoint>>>> errors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Could not load chart data.\n${errors.first.value.error}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.metric,
    required this.active,
    required this.points,
    required this.loading,
    required this.onTap,
  });

  final StatMetric metric;
  final bool active;
  final List<SeriesPoint>? points;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = points?.fold<double>(0, (a, p) => a + p.value);
    final color = active ? metric.color : AppColors.textSecondaryHintColor;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? metric.color.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? metric.color : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              metric.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active
                    ? AppColors.textSecondaryColor
                    : AppColors.textSecondaryHintColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total != null
                  ? metric.formatCompact(total)
                  : (loading ? '…' : '–'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLaurel : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryLaurel : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
