import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_willbefore/core/constants/user_roles.dart';

import 'dashboard_stats_models.dart';

/// Order statuses that count towards revenue.
const _revenueStatuses = ['confirmed', 'shipped'];

/// Reads dashboard numbers with server-side aggregation (`count()` / `sum()`),
/// so no documents are downloaded no matter how large the collections grow.
class DashboardStatsSource {
  DashboardStatsSource(this._db);

  final FirebaseFirestore _db;

  /// Buckets that have already ended never change, so they are only queried
  /// once per session.
  final Map<String, double> _closedBuckets = {};

  Query<Map<String, dynamic>> _query(
    StatMetric metric, {
    DateTime? start,
    DateTime? end,
  }) {
    Query<Map<String, dynamic>> q;
    switch (metric) {
      case StatMetric.users:
        q = _db.collection('users').where('role', isEqualTo: UserRoles.user);
      case StatMetric.products:
        q = _db.collection('products').where('isActive', isEqualTo: true);
      case StatMetric.orders:
        q = _db.collection('orders');
      case StatMetric.revenue:
        q = _db.collection('orders').where('status', whereIn: _revenueStatuses);
    }
    if (start != null) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      q = q.where('createdAt', isLessThan: Timestamp.fromDate(end));
    }
    return q;
  }

  Future<double> value(
    StatMetric metric, {
    DateTime? start,
    DateTime? end,
  }) async {
    final q = _query(metric, start: start, end: end);
    if (metric == StatMetric.revenue) {
      final snap = await q.aggregate(sum('total')).get();
      return snap.getSum('total') ?? 0;
    }
    final snap = await q.count().get();
    return (snap.count ?? 0).toDouble();
  }

  Future<List<SeriesPoint>> series(
    StatMetric metric,
    StatPeriod period,
    DateTime anchor,
  ) {
    final now = DateTime.now();
    final buckets = buildBuckets(period, anchor);
    return Future.wait(
      buckets.map((b) async {
        if (b.start.isAfter(now)) {
          return SeriesPoint(
            label: b.label,
            fullLabel: b.fullLabel,
            value: 0,
            isFuture: true,
          );
        }
        final isClosed = !b.end.isAfter(now);
        final key =
            '${metric.name}|${b.start.millisecondsSinceEpoch}|'
            '${b.end.millisecondsSinceEpoch}';
        var v = isClosed ? _closedBuckets[key] : null;
        if (v == null) {
          v = await value(metric, start: b.start, end: b.end);
          if (isClosed) _closedBuckets[key] = v;
        }
        return SeriesPoint(
          label: b.label,
          fullLabel: b.fullLabel,
          value: v,
          isFuture: false,
        );
      }),
    );
  }

  /// All-time total plus month-to-date vs the same span of last month.
  Future<Kpi> kpi(StatMetric metric) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final prevStart = DateTime(now.year, now.month - 1);
    var prevEnd = prevStart.add(now.difference(monthStart));
    if (prevEnd.isAfter(monthStart)) prevEnd = monthStart;

    // The trend is optional: if its range queries fail (e.g. index still
    // building) the card still shows the total.
    Future<double?> trend() async {
      try {
        final r = await Future.wait([
          value(metric, start: monthStart),
          value(metric, start: prevStart, end: prevEnd),
        ]);
        return r[1] == 0 ? null : (r[0] - r[1]) / r[1] * 100;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([value(metric), trend()]);
    return Kpi(total: results[0] as double, trendPercent: results[1]);
  }
}
