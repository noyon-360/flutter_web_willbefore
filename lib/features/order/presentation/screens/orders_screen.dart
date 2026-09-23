import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/routes/route_endpoint.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order_entities.dart';
import '../providers/order_provider.dart';
import 'order_details_screen.dart'; // Add this import

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _selectedStatusFilter;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminOrderProvider.notifier).fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminOrderProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminOrderState = ref.watch(adminOrderProvider);
    final filteredOrders = _getFilteredOrders(adminOrderState.orders);

    DPrint.log(
      'Rendering OrdersScreen with ${adminOrderState.orders} filtered orders',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(filteredOrders.length, adminOrderState.usersCount),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onSubmitted: (value) => ref
                  .read(adminOrderProvider.notifier)
                  .search(value.trim()),
              decoration: InputDecoration(
                hintText: 'Search orders by customer email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminOrderProvider.notifier).search('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildOrdersTable(
                filteredOrders,
                adminOrderState,
                _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int totalOrders, int totalUsers) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Orders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalOrders.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalUsers.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<OrderStatus?>(
              value: _selectedStatusFilter,
              hint: const Text(
                'Filter by Status',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: [
                const DropdownMenuItem<OrderStatus?>(
                  value: null,
                  child: Text('All Orders'),
                ),
                ...OrderStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.displayName),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(
    List<Order> orders,
    AdminOrderState state,
    ScrollController scrollController,
  ) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Order Details',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Customer',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Products',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: orders.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildOrderRow(orders[index], state.isUpdating);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Order order, bool isUpdating) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final shippingAddress = order.shippingAddress;

    return InkWell(
      onTap: () {
        context.goNamed(
          RouteEndpoint.ordersDetails.split('/').first,
          pathParameters: {'id': order.id},
          extra: order,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer ID: ${order.userId.substring(0, 8)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shippingAddress.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shippingAddress.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (shippingAddress.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      shippingAddress.phoneNumber,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child:
                        firstItem?.product.imageUrls != null &&
                            firstItem!.product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              firstItem.product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.orange[100],
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.orange,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.orange[100],
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.orange,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItem?.product.title ?? 'Unknown Product',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: order.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // const SizedBox(width: 8),
                  // IconButton(
                  //   onPressed: isUpdating
                  //       ? null
                  //       : () => _showStatusUpdateDialog(order),
                  //   icon: isUpdating
                  //       ? const SizedBox(
                  //           width: 16,
                  //           height: 16,
                  //           child: CircularProgressIndicator(strokeWidth: 2),
                  //         )
                  //       : const Icon(Icons.edit, size: 18),
                  //   tooltip: 'Update Status',
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id.substring(0, 8)}'),
            const SizedBox(height: 16),
            Text('Current Status: ${order.status.displayName}'),
            const SizedBox(height: 16),
            const Text('Select New Status:'),
            const SizedBox(height: 8),
            ...OrderStatus.values.map(
              (status) => RadioListTile<OrderStatus>(
                title: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.displayName),
                  ],
                ),
                value: status,
                groupValue: order.status,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _updateOrderStatus(order.id, value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final success = await ref
        .read(adminOrderProvider.notifier)
        .updateOrderStatus(orderId, newStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order status updated successfully'
                : 'Failed to update order status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedStatusFilter == null) return orders;
    return orders
        .where((order) => order.status == _selectedStatusFilter)
        .toList();
  }
}
