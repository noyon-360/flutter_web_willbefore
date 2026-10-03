import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_stats_models.dart';
import '../../data/dashboard_stats_source.dart';

/// How long a result is reused before the next watcher triggers a refetch.
const _cacheTtl = Duration(minutes: 5);

/// (metric, period, normalized anchor) - see [normalizeAnchor].
typedef StatKey = (StatMetric, StatPeriod, DateTime);

final dashboardStatsSourceProvider = Provider<DashboardStatsSource>((ref) {
  return DashboardStatsSource(FirebaseFirestore.instance);
});

/// Keeps an auto-dispose provider alive for [_cacheTtl], so leaving the
/// dashboard and coming back (or switching filters back and forth) reuses the
/// result instead of querying again.
void _cacheFor(Ref ref) {
  final link = ref.keepAlive();
  final timer = Timer(_cacheTtl, link.close);
  ref.onDispose(timer.cancel);
}

// Riverpod 3 retries failed providers automatically; a failing query (e.g. a
// missing index) would be re-run dozens of times, so retries are disabled.
Duration? _noRetry(int retryCount, Object error) => null;

final statSeriesProvider = FutureProvider.autoDispose
    .family<List<SeriesPoint>, StatKey>((ref, key) {
      _cacheFor(ref);
      return ref
          .read(dashboardStatsSourceProvider)
          .series(key.$1, key.$2, key.$3);
    }, retry: _noRetry);

final kpiProvider = FutureProvider.autoDispose.family<Kpi, StatMetric>((
  ref,
  metric,
) {
  _cacheFor(ref);
  return ref.read(dashboardStatsSourceProvider).kpi(metric);
}, retry: _noRetry);

void refreshDashboard(WidgetRef ref) {
  ref.invalidate(statSeriesProvider);
  ref.invalidate(kpiProvider);
}

class ChartControls {
  ChartControls({
    this.period = StatPeriod.month,
    DateTime? anchor,
    this.visible = const {
      StatMetric.revenue,
      StatMetric.orders,
      StatMetric.users,
      StatMetric.products,
    },
    this.scaled = true,
  }) : anchor = anchor ?? DateTime.now();

  final StatPeriod period;

  /// Any date inside the selected period; [periodStart] is its normalized form.
  final DateTime anchor;
  final Set<StatMetric> visible;

  /// When true each line is drawn relative to its own peak so small series
  /// (users, products) stay readable next to revenue.
  final bool scaled;

  DateTime get periodStart => normalizeAnchor(period, anchor);

  bool get isCurrentPeriod =>
      periodStart == normalizeAnchor(period, DateTime.now());

  bool get canGoBack => shiftAnchor(period, anchor, -1).year >= kStatsFirstYear;

  ChartControls copyWith({
    StatPeriod? period,
    DateTime? anchor,
    Set<StatMetric>? visible,
    bool? scaled,
  }) => ChartControls(
    period: period ?? this.period,
    anchor: anchor ?? this.anchor,
    visible: visible ?? this.visible,
    scaled: scaled ?? this.scaled,
  );
}

class ChartControlsNotifier extends Notifier<ChartControls> {
  @override
  ChartControls build() => ChartControls();

  void setPeriod(StatPeriod period) => state = state.copyWith(period: period);

  /// Jumps to the period containing [date]; future dates are clamped to today.
  void setAnchor(DateTime date) {
    final now = DateTime.now();
    state = state.copyWith(anchor: date.isAfter(now) ? now : date);
  }

  void shift(int direction) {
    if (direction > 0 && state.isCurrentPeriod) return;
    if (direction < 0 && !state.canGoBack) return;
    setAnchor(shiftAnchor(state.period, state.anchor, direction));
  }

  void goToToday() => state = state.copyWith(anchor: DateTime.now());

  void setScaled(bool scaled) => state = state.copyWith(scaled: scaled);

  void toggle(StatMetric metric) {
    final next = {...state.visible};
    if (!next.remove(metric)) {
      next.add(metric);
    } else if (next.isEmpty) {
      return; // keep at least one line on
    }
    state = state.copyWith(visible: next);
  }
}

final chartControlsProvider =
    NotifierProvider<ChartControlsNotifier, ChartControls>(
      ChartControlsNotifier.new,
    );
