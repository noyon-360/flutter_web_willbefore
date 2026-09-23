import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';
import 'package:flutter_web_willbefore/core/constants/user_roles.dart';
// import '../../../../data/dummy_data.dart'; // No longer used for fallbacks
import '../../../../models/dashboard_models.dart';
import '../../../product/presentation/providers/products_providers.dart';
import '../../../userProfile/presentation/provider/all_user_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_card.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  String _newUserFilter = 'Month';
  String _liveProductFilter = 'Day';
  String _revenueFilter = 'Year';

  final double _totalRevenue = 0.0;
  final bool _isLoadingRevenue = false;
  final List<ChartData> _revenueData = [];
  List<ChartData> _liveProductData = [];
  List<ChartData> _newUserData = [];

  @override
  void initState() {
    super.initState();
    // Delay provider modifications until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).fetchProducts();
      _fetchLiveProductData();
      _fetchNewUserData();
    });
  }

  // Calculate timestamps based on filter
  Map<String, dynamic> _getTimeRange(String filter) {
    final now = DateTime.now();
    DateTime startDate;

    switch (filter) {
      case 'Day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
      default:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return {
      'start_date': startDate,
      'interval_start': startDate.millisecondsSinceEpoch ~/ 1000,
      'interval_end': now.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // Removed _aggregateChartData as aggregation is now handled within fetch methods

  // Fetch live product data from Firestore
  void _fetchLiveProductData() {
    final products = ref.read(productsProvider).products;
    final timeRange = _getTimeRange(_liveProductFilter);
    final startDate = timeRange['start_date'] as DateTime;

    final Map<String, int> productCounts = {};
    final List<String> labels = [];

    // Initialize labels based on filter
    if (_liveProductFilter == 'Day') {
      for (int i = 0; i <= 23; i++) {
        String label = i.toString().padLeft(2, '0');
        labels.add(label);
        productCounts[label] = 0;
      }
    } else if (_liveProductFilter == 'Week') {
      const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      labels.addAll(weekDays);
      for (var day in weekDays) productCounts[day] = 0;
    } else if (_liveProductFilter == 'Month') {
      final daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        String label = i.toString();
        labels.add(label);
        productCounts[label] = 0;
      }
    } else {
      // Year
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      labels.addAll(months);
      for (var month in months) productCounts[month] = 0;
    }

    for (var product in products.where((p) => p.isActive)) {
      if (product.createdAt.isAfter(startDate)) {
        String label;
        switch (_liveProductFilter) {
          case 'Day':
            label = product.createdAt.hour.toString().padLeft(2, '0');
            break;
          case 'Week':
            const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            label = weekDays[product.createdAt.weekday - 1];
            break;
          case 'Month':
            label = product.createdAt.day.toString();
            break;
          case 'Year':
          default:
            const months = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            label = months[product.createdAt.month - 1];
            break;
        }
        if (productCounts.containsKey(label)) {
          productCounts[label] = productCounts[label]! + 1;
        }
      }
    }

    final List<ChartData> chartData = labels
        .map(
          (label) =>
              ChartData(label: label, value: productCounts[label]!.toDouble()),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _liveProductData = chartData;
    });
  }

  // Fetch new user data from Firestore
  void _fetchNewUserData() {
    final users = ref.read(userProvider).users;
    final timeRange = _getTimeRange(_newUserFilter);
    final startDate = timeRange['start_date'] as DateTime;

    final Map<String, int> userCounts = {};
    final List<String> labels = [];

    // Initialize labels based on filter
    if (_newUserFilter == 'Day') {
      for (int i = 0; i <= 23; i++) {
        String label = i.toString().padLeft(2, '0');
        labels.add(label);
        userCounts[label] = 0;
      }
    } else if (_newUserFilter == 'Week') {
      const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      labels.addAll(weekDays);
      for (var day in weekDays) userCounts[day] = 0;
    } else if (_newUserFilter == 'Month') {
      final daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        String label = i.toString();
        labels.add(label);
        userCounts[label] = 0;
      }
    } else {
      // Year
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      labels.addAll(months);
      for (var month in months) userCounts[month] = 0;
    }

    for (var user in users.where((u) => !UserRoles.isStaff(u.role))) {
      if (user.createdAt.isAfter(startDate)) {
        String label;
        switch (_newUserFilter) {
          case 'Day':
            label = user.createdAt.hour.toString().padLeft(2, '0');
            break;
          case 'Week':
            const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            label = weekDays[user.createdAt.weekday - 1];
            break;
          case 'Month':
            label = user.createdAt.day.toString();
            break;
          case 'Year':
          default:
            const months = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            label = months[user.createdAt.month - 1];
            break;
        }
        if (userCounts.containsKey(label)) {
          userCounts[label] = userCounts[label]! + 1;
        }
      }
    }

    final List<ChartData> chartData = labels
        .map(
          (label) =>
              ChartData(label: label, value: userCounts[label]!.toDouble()),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _newUserData = chartData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final userState = ref.watch(userProvider);

    // Listen for changes in products and users to update counts reactively
    ref.listen(productsProvider, (previous, next) {
      if (previous?.products.length != next.products.length) {
        _fetchLiveProductData();
      }
    });
    ref.listen(userProvider, (previous, next) {
      if (previous?.users.length != next.users.length) {
        _fetchNewUserData();
      }
    });

    double totalRevenue = _isLoadingRevenue ? 0.0 : _totalRevenue;
    int totalLiveProducts = productsState.products
        .where((p) => p.isActive)
        .length;
    int totalUsers = userState.users
        .where((u) => !UserRoles.isStaff(u.role))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.attach_money,
                  title: 'Total Revenue',
                  value: _isLoadingRevenue
                      ? 'Loading...'
                      : '\$${totalRevenue.toStringAsFixed(2)}',
                  iconColor: AppColors.primaryLaurel,
                  trend: '+12.5%', // Mock trend for now
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  icon: Icons.inventory,
                  title: 'Total Live Product',
                  value: '$totalLiveProducts',
                  iconColor: AppColors.primaryLaurel,
                  trend: '+5.2%', // Mock trend
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: StatCard(
                  icon: Icons.people,
                  title: 'Total User',
                  value: userState.isLoading ? 'Loading...' : '$totalUsers',
                  iconColor: AppColors.primaryLaurel,
                  trend: '+1.8%', // Mock trend
                  isPositive: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ChartCard(
                  title:
                      'New User (${_newUserData.fold(0.0, (sum, item) => sum + item.value).toInt()})',
                  data: _newUserData,
                  chartType: ChartType.line,
                  selectedFilter: _newUserFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _newUserFilter = filter;
                      _fetchNewUserData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ChartCard(
                  title:
                      'Live Product report (${_liveProductData.fold(0.0, (sum, item) => sum + item.value).toInt()})',
                  data: _liveProductData,
                  chartType: ChartType.bar,
                  selectedFilter: _liveProductFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _liveProductFilter = filter;
                      _fetchLiveProductData();
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Revenue Chart
          ChartCard(
            title:
                'Revenue report (\$${_revenueData.fold(0.0, (sum, item) => sum + item.value).toStringAsFixed(2)})',
            data: _revenueData,
            chartType: ChartType.area,
            timeFilters: const ['Day', 'Week', 'Month', 'Year'],
            selectedFilter: _revenueFilter,
            onFilterChanged: (filter) {
              setState(() {
                _revenueFilter = filter;
              });
            },
          ),

          // const SizedBox(height: 32),

          // // Charges Section
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       'Recent Charges',
          //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          //     ),
          //     DropdownButton<String>(
          //       value: _chargeFilter,
          //       items: ['All', 'Succeeded', 'Pending', 'Failed']
          //           .map((filter) => DropdownMenuItem(
          //                 value: filter,
          //                 child: Text(filter),
          //               ))
          //           .toList(),
          //       onChanged: (value) {
          //         if (value != null) {
          //           setState(() {
          //             _chargeFilter = value;
          //             _fetchCharges();
          //           });
          //         }
          //       },
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 8),

          // _isLoadingCharges
          //     ? Center(child: CircularProgressIndicator())
          //     : _charges.isEmpty
          //         ? Center(child: Text('No charges found'))
          //         : ListView.builder(
          //             shrinkWrap: true,
          //             physics: NeverScrollableScrollPhysics(),
          //             itemCount: _charges.length,
          //             itemBuilder: (context, index) {
          //               final charge = _charges[index];
          //               return Card(
          //                 margin: EdgeInsets.symmetric(vertical: 4),
          //                 child: ListTile(
          //                   title: Text('Amount: \$${charge['amount'] / 100}'),
          //                   subtitle: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text('Status: ${charge['status']}'),
          //                       Text('Date: ${DateTime.fromMillisecondsSinceEpoch(charge['created'] * 1000).toString()}'),
          //                       if (charge['metadata']['shippo_address_id'] != null)
          //                         Text('Shippo Address ID: ${charge['metadata']['shippo_address_id']}'),
          //                       if (charge['metadata']['order_items'] != null)
          //                         Text('Items: ${charge['metadata']['order_items']}'),
          //                     ],
          //                   ),
          //                   trailing: Icon(
          //                     charge['status'] == 'succeeded'
          //                         ? Icons.check_circle
          //                         : charge['status'] == 'pending'
          //                             ? Icons.hourglass_empty
          //                             : Icons.error,
          //                     color: charge['status'] == 'succeeded'
          //                         ? Colors.green
          //                         : charge['status'] == 'pending'
          //                             ? Colors.orange
          //                             : Colors.red,
          //                   ),
          //                 ),
          //               );
          //             },
          //           ),
        ],
      ),
    );
  }
}
