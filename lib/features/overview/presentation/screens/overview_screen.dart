import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';

import '../../data/dashboard_stats_models.dart';
import '../providers/dashboard_stats_provider.dart';
import '../widgets/overview_trend_card.dart';
import '../widgets/stat_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 1000) {
                return Row(
                  children: [
                    for (final (i, m) in StatMetric.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 24),
                      Expanded(child: _KpiCard(metric: m)),
                    ],
                  ],
                );
              }
              // Narrow window: two cards per row.
              final w = (c.maxWidth - 24) / 2;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  for (final m in StatMetric.values)
                    SizedBox(
                      width: w,
                      child: _KpiCard(metric: m),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const OverviewTrendCard(),
        ],
      ),
    );
  }
}

class _KpiCard extends ConsumerWidget {
  const _KpiCard({required this.metric});

  final StatMetric metric;

  String get _title => switch (metric) {
    StatMetric.revenue => 'Total Revenue',
    StatMetric.orders => 'Total Orders',
    StatMetric.users => 'Total Users',
    StatMetric.products => 'Live Products',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(kpiProvider(metric));
    final trend = kpi.value?.trendPercent;

    return StatCard(
      icon: metric.icon,
      title: _title,
      value: kpi.when(
        data: (k) => metric.format(k.total),
        loading: () => '…',
        error: (_, _) => '—',
      ),
      iconColor: AppColors.primaryLaurel,
      trend: trend == null
          ? null
          : '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
      isPositive: trend == null ? null : trend >= 0,
      trendHint: 'Month to date vs the same period last month',
    );
  }
}
