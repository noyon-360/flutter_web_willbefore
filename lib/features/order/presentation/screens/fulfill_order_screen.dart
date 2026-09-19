import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutx_core/flutx_core.dart';

import '../../../../core/services/shippo_service.dart';
import '../../../setting/presentation/provider/warehouse_provider.dart';
import '../../domain/entities/order_entities.dart';
import '../providers/order_provider.dart';
import '../providers/send_shipment_notification.dart';

class FullfillOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  final Order? initialOrder;
  const FullfillOrderScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<FullfillOrderScreen> createState() =>
      _FulfillOrderScreenState();
}

class _FulfillOrderScreenState extends ConsumerState<FullfillOrderScreen> {
  bool _isLoading = false;
  bool _isVoiding = false;
  String? _trackingNumber;
  String? _labelUrl;
  String? _trackingUrl;
  String? _error;

  final _shippo = AdminShippoService();

  // Parcel Inputs
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String _distanceUnit = 'in';
  String _massUnit = 'oz';

  // Address edit inputs
  bool _isEditingAddress = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;

  // Rate selection
  List<Map<String, dynamic>>? _rates;
  Map<String, dynamic>? _selectedRate;
  bool _isFetchingRates = false;

  Order? _order;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _lengthController = TextEditingController(text: '10');
    _widthController = TextEditingController(text: '6');
    _heightController = TextEditingController(text: '4');
    _weightController = TextEditingController(text: '8.0');

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _countryController = TextEditingController();

    // Initial attempt to find order
    final adminState = ref.read(adminOrderProvider);
    final index = adminState.orders.indexWhere((o) => o.id == widget.orderId);
    if (index != -1) {
      _order = adminState.orders[index];
      _initializeControllers();
    } else if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    if (_initialized || _order == null) return;

    // Update weight based on items
    final totalWeightOz = _order!.items.fold<double>(
      0,
      (sum, item) => sum + (item.product.weightOz) * item.quantity,
    );
    final initialWeight = totalWeightOz > 0 ? totalWeightOz : 8.0;
    _weightController.text = initialWeight.toString();

    _resetAddressControllersFromOrder();

    // Pre-populate existing fulfillment info, if any.
    _trackingNumber = _order!.trackingNumber;
    _labelUrl = _order!.labelUrl;
    _trackingUrl = _order!.trackingUrl;

    _initialized = true;
  }

  void _resetAddressControllersFromOrder() {
    final addr = _order!.shippingAddress;
    _nameController.text = addr.fullName;
    _phoneController.text = addr.phoneNumber;
    _emailController.text = addr.email;
    _address1Controller.text = addr.addressLine1;
    _address2Controller.text = addr.addressLine2;
    _cityController.text = addr.city;
    _stateController.text = addr.state;
    _zipController.text = addr.postalCode;
    _countryController.text = addr.country;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------
  //  Address editing
  // --------------------------------------------------------------
  Future<void> _saveAddress() async {
    final updated = ShippingAddress(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _zipController.text.trim(),
      country: _countryController.text.trim(),
    );

    setState(() => _isLoading = true);
    final success = await ref
        .read(adminOrderProvider.notifier)
        .updateShippingAddress(_order!.id, updated);
    if (!mounted) return;

    if (success) {
      setState(() {
        _order = _order!.copyWith(shippingAddress: updated);
        _isEditingAddress = false;
        _isLoading = false;
        // Address changed — any previously fetched rates are stale.
        _rates = null;
        _selectedRate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipping address updated'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update shipping address'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------------------
  //  Address validation helper
  // --------------------------------------------------------------
  bool _isValidAddress(Map<String, dynamic>? addr, {required bool isUS}) {
    if (addr == null) return false;

    // Check modern validation results first
    if (addr.containsKey('validation_results')) {
      final validation = addr['validation_results'];
      if (validation is Map && validation['is_valid'] == true) {
        return true;
      }
    }

    if (isUS) return addr['object_state'] == 'VALID';
    return addr['object_id'] != null;
  }

  // --------------------------------------------------------------
  //  Fetch rates (creates addresses/parcel/shipment, does NOT buy)
  // --------------------------------------------------------------
  Future<void> _fetchRates() async {
    setState(() {
      _isFetchingRates = true;
      _error = null;
      _rates = null;
      _selectedRate = null;
    });

    try {
      // ---- 1. Warehouse address -------------------------------------------------
      final warehouseState = ref.read(warehouseProvider);
      if (warehouseState.address == null) {
        final provider = ref.read(warehouseProvider.notifier);
        provider.refresh();
        if (ref.read(warehouseProvider).address == null) {
          throw Exception(
            'Warehouse address not configured. Please set it in Admin → Settings.',
          );
        }
      }
      final warehouse = ref.read(warehouseProvider).address!;
      final bool isWarehouseUS = warehouse.country?.toUpperCase() == 'US';

      if (warehouse.email == null || warehouse.email!.trim().isEmpty) {
        throw Exception(
          'Warehouse email is missing. Please add it in Admin → Settings → Warehouse Address.',
        );
      }
      if (warehouse.phone == null || warehouse.phone!.trim().isEmpty) {
        throw Exception(
          'Warehouse phone is missing. Please add it in Admin → Settings → Warehouse Address.',
        );
      }

      // ---- 2. FROM address -------------------------------------------------------
      final fromAddr = await _shippo.createAddress(
        name: warehouse.name ?? 'Warehouse',
        street1: warehouse.street1 ?? '',
        city: warehouse.city ?? '',
        state: warehouse.state ?? '',
        zip: warehouse.zip ?? '',
        country: warehouse.country ?? '',
        email: warehouse.email,
        phone: warehouse.phone,
        isResidential: warehouse.isResidential,
      );

      if (!_isValidAddress(fromAddr, isUS: isWarehouseUS)) {
        throw Exception(
          'Warehouse address invalid: ${_extractShippoMessage(fromAddr)}',
        );
      }

      // ---- 3. TO address ---------------------------------------------------------
      final toAddr = await _shippo.createAddress(
        name: _order!.shippingAddress.fullName,
        street1: _order!.shippingAddress.addressLine1,
        city: _order!.shippingAddress.city,
        state: _order!.shippingAddress.state,
        zip: _order!.shippingAddress.postalCode,
        country: _order!.shippingAddress.country,
        phone: _order!.shippingAddress.phoneNumber,
        email: _order!.shippingAddress.email,
      );

      final bool isCustomerUS =
          _order!.shippingAddress.country.toUpperCase() == 'US';
      if (!_isValidAddress(toAddr, isUS: isCustomerUS)) {
        throw Exception(
          'Customer address invalid: ${_extractShippoMessage(toAddr)}. '
          'Use "Edit Address" above to correct it, then try again.',
        );
      }

      // ---- 4. Parcel -------------------------------------------------------------
      final length = double.tryParse(_lengthController.text);
      final width = double.tryParse(_widthController.text);
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);

      if (length == null || width == null || height == null || weight == null) {
        throw Exception(
          'Please enter valid numeric values for dimensions and weight.',
        );
      }

      final parcelId = await _shippo.createParcel(
        length: length,
        width: width,
        height: height,
        distanceUnit: _distanceUnit,
        weight: weight,
        massUnit: _massUnit,
      );

      // ---- 4.5 Customs Declaration (International) -------------------------------
      String? customsDeclarationId;
      final bool isDomesticUS = isWarehouseUS && isCustomerUS;

      if (!isDomesticUS) {
        final List<String> customsItemIds = [];
        for (final item in _order!.items) {
          final itemId = await _shippo.createCustomsItem(
            description: item.product.title,
            quantity: item.quantity.toDouble(),
            netWeight: item.product.weightOz > 0 ? item.product.weightOz : 1.0,
            massUnit: 'oz',
            valueAmount: item.product.effectivePrice,
            valueCurrency: 'USD',
            originCountry: warehouse.country ?? 'US',
          );
          customsItemIds.add(itemId);
        }

        customsDeclarationId = await _shippo.createCustomsDeclaration(
          customsItemIds: customsItemIds,
          certify: true,
          signer: warehouse.name ?? 'Sender',
        );
      }

      // ---- 5. Shipment -----------------------------------------------------------
      final shipment = await _shippo.createShipment(
        addressFromId: fromAddr['object_id'] as String,
        addressToId: toAddr['object_id'] as String,
        parcelIds: [parcelId],
        customsDeclarationId: customsDeclarationId,
      );

      // ---- 6. Rates ---------------------------------------------------------------
      final rawRates = (shipment['rates'] as List).cast<Map<String, dynamic>>();
      if (rawRates.isEmpty) {
        throw Exception('No shipping rates returned by Shippo');
      }

      final rates = List<Map<String, dynamic>>.from(rawRates)
        ..sort(
          (a, b) => double.parse(a['amount']).compareTo(double.parse(b['amount'])),
        );

      // Default pre-selection mirrors the old automatic behavior (cheapest
      // USPS domestically, cheapest overall internationally) but admins can
      // now pick a higher tier — e.g. to upgrade a customer for free — or
      // any other carrier, before a label is purchased.
      Map<String, dynamic> defaultRate;
      if (isDomesticUS) {
        final uspsRates = rates
            .where((r) => (r['provider'] as String).toUpperCase().contains('USPS'))
            .toList();
        defaultRate = uspsRates.isNotEmpty ? uspsRates.first : rates.first;
      } else {
        defaultRate = rates.first;
      }

      setState(() {
        _rates = rates;
        _selectedRate = defaultRate;
      });
    } catch (e) {
      setState(() => _error = _getFriendlyErrorMessage(e));
      DPrint.error('Fetch Rates Error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingRates = false);
    }
  }

  String _extractShippoMessage(Map<String, dynamic> addr) {
    try {
      final messages = addr['messages'] as List?;
      if (messages != null && messages.isNotEmpty) {
        return messages
            .map((m) => m is Map ? (m['text'] ?? m.toString()) : m.toString())
            .join(', ');
      }
      return 'Full Response: ${jsonEncode(addr)}';
    } catch (_) {
      return 'Response: $addr';
    }
  }

  // --------------------------------------------------------------
  //  Buy the selected label
  // --------------------------------------------------------------
  Future<void> _buyLabel() async {
    if (_selectedRate == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transaction = await _shippo.buyLabel(_selectedRate!['object_id']);

      if (transaction['status'] != 'SUCCESS') {
        String msg = 'Label purchase failed';
        if (transaction['messages'] != null) {
          final messages = transaction['messages'] as List;
          msg = messages.map((m) => m['text'] ?? m.toString()).join('\n');
        }
        throw Exception(msg);
      }

      final trackingRaw = transaction['tracking_number']?.toString();
      if (trackingRaw == null || trackingRaw.isEmpty) {
        throw Exception(
          'Carrier did not provide a tracking number. Label generation aborted.',
        );
      }

      final success = await ref
          .read(adminOrderProvider.notifier)
          .fulfillOrder(
            orderId: _order!.id,
            trackingNumber: transaction['tracking_number'],
            trackingUrl: transaction['tracking_url_provider'],
            labelUrl: transaction['label_url'],
            shippoTransactionId: transaction['object_id'],
          );
      if (!success) throw Exception('Failed to update order in database');

      setState(() {
        final tracking = transaction['tracking_number']?.toString();
        _trackingNumber = (tracking != null && tracking.isNotEmpty)
            ? tracking
            : 'Not Provided by Carrier';
        _labelUrl = transaction['label_url'];
        _trackingUrl = transaction['tracking_url_provider'];
      });

      await sendShipmentNotification(
        orderId: _order!.id,
        userId: _order!.userId,
        trackingNumber: transaction['tracking_number'],
        trackingUrl: transaction['tracking_url_provider'],
        labelUrl: transaction['label_url'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Label generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = _getFriendlyErrorMessage(e));
      DPrint.error('Buy Label Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------------
  //  Void the current label so a corrected one can be generated
  // --------------------------------------------------------------
  Future<void> _voidLabelAndStartOver() async {
    final transactionId = _order!.shippoTransactionId;
    if (transactionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void this label?'),
        content: const Text(
          'This will request a refund for the purchased label from the '
          'carrier and clear the tracking info on this order, so you can '
          'fix the address or pick a different shipping tier and generate '
          'a new label. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Void Label'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isVoiding = true;
      _error = null;
    });

    try {
      await _shippo.refundLabel(transactionId);

      final success = await ref
          .read(adminOrderProvider.notifier)
          .resetFulfillment(_order!.id);
      if (!success) throw Exception('Failed to reset order fulfillment');

      if (!mounted) return;
      setState(() {
        _order = _order!.copyWith(status: OrderStatus.confirmed);
        _labelUrl = null;
        _trackingNumber = null;
        _trackingUrl = null;
        _rates = null;
        _selectedRate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Label voided. Refund may take a few days to process with the carrier.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _error = _getFriendlyErrorMessage(e));
      DPrint.error('Void Label Error: $e');
    } finally {
      if (mounted) setState(() => _isVoiding = false);
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final String errorStr = error.toString();

    // Handle common Shippo/Technical errors
    if (errorStr.contains('Warehouse address not configured')) {
      return 'Please set up your warehouse address in Admin Settings first.';
    }
    if (errorStr.contains('Please enter valid numeric values')) {
      return 'Ensure dimensions and weight are valid positive numbers.';
    }
    if (errorStr.contains('No shipping rates returned')) {
      return 'No shipping rates found. Please check both warehouse and customer addresses.';
    }

    // Try to parse JSON errors from Shippo
    try {
      if (errorStr.contains('Exception:')) {
        final jsonPart = errorStr.split('Exception: ').last;
        final data = jsonDecode(jsonPart);
        if (data is Map) {
          if (data.containsKey('messages')) {
            final messages = data['messages'] as List;
            return messages.map((m) => m['text'] ?? m.toString()).join('\n');
          }
          if (data.containsKey('detail')) return data['detail'];
          if (data.containsKey('message')) return data['message'];
        }
      }
    } catch (_) {}

    // Fallback cleaning
    return errorStr
        .replaceAll('Exception: ', '')
        .replaceAll('Parcel Error: ', '')
        .replaceAll('Shipment Error: ', '')
        .replaceAll('Address Error: ', '');
  }

  // --------------------------------------------------------------
  //  UI
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Listen for state changes to find the order if not already found
    ref.listen(adminOrderProvider, (previous, next) {
      if (_order == null) {
        final index = next.orders.indexWhere((o) => o.id == widget.orderId);
        if (index != -1) {
          setState(() {
            _order = next.orders[index];
            _initializeControllers();
          });
        }
      }
    });

    final warehouseState = ref.watch(warehouseProvider);

    // If order is still loading from database
    if (_order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Loading warehouse address
    if (warehouseState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Warehouse not set
    if (warehouseState.address == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fulfill Order')),
        body: const Center(
          child: Text(
            'Warehouse address not configured.\nPlease set it in Admin → Settings.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Fulfill Order #${_order!.id.substring(0, 8)}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // Parcel Details Input
            if (_labelUrl == null) ...[
              _buildParcelDetailsCard(),
              const SizedBox(height: 24),
            ],

            if (_labelUrl == null && _rates == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isFetchingRates || _isEditingAddress
                      ? null
                      : _fetchRates,
                  icon: _isFetchingRates
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.local_shipping, color: AppColors.white),
                  label: Text(
                    _isFetchingRates ? 'Fetching Rates...' : 'Get Shipping Rates',
                    style: const TextStyle(color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLaurel,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

            if (_labelUrl == null && _rates != null) ...[
              _buildRateSelectionCard(),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _rates = null;
                              _selectedRate = null;
                            }),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading || _selectedRate == null
                          ? null
                          : _buyLabel,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print, color: AppColors.white),
                      label: Text(
                        _isLoading ? 'Purchasing...' : 'Buy Selected Label',
                        style: const TextStyle(color: AppColors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLaurel,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_labelUrl != null) ...[
              _buildSuccessCard(),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_labelUrl!)),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Label'),
                  ),
                  if (_trackingUrl != null && _trackingUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_trackingUrl!)),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Track Package'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _isVoiding ? null : _voidLabelAndStartOver,
                    icon: _isVoiding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.undo, color: Colors.red),
                    label: Text(
                      _isVoiding ? 'Voiding...' : 'Void Label & Start Over',
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],

            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fulfillment Issue',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red[800], height: 1.4),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  //  UI Helpers
  // --------------------------------------------------------------
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping To',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // Address can only be corrected before a label is purchased —
              // once bought, it must be voided first (Shippo labels are
              // immutable).
              if (_labelUrl == null)
                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            if (_isEditingAddress) {
                              _resetAddressControllersFromOrder();
                            }
                            _isEditingAddress = !_isEditingAddress;
                          });
                        },
                  icon: Icon(_isEditingAddress ? Icons.close : Icons.edit),
                  label: Text(_isEditingAddress ? 'Cancel' : 'Edit Address'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditingAddress)
            _buildAddressEditForm()
          else ...[
            Text(_order!.shippingAddress.fullName),
            Text(_order!.shippingAddress.addressLine1),
            if (_order!.shippingAddress.addressLine2.isNotEmpty)
              Text(_order!.shippingAddress.addressLine2),
            Text(
              '${_order!.shippingAddress.city}, ${_order!.shippingAddress.state} ${_order!.shippingAddress.postalCode}',
            ),
            Text(_order!.shippingAddress.country),
            if (_order!.shippingAddress.phoneNumber.isNotEmpty)
              Text(_order!.shippingAddress.phoneNumber),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(controller: _nameController, label: 'Full Name'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: _phoneController, label: 'Phone'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(controller: _emailController, label: 'Email'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(controller: _address1Controller, label: 'Address Line 1'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _address2Controller,
          label: 'Address Line 2 (optional)',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: _cityController, label: 'City'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(controller: _stateController, label: 'State'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: _zipController, label: 'Postal Code'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _countryController,
                label: 'Country (e.g. US)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
            ),
            child: Text(
              _isLoading ? 'Saving...' : 'Save Address',
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Shipping Tier',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick any carrier/tier — e.g. upgrade the customer to a faster '
            'tier at no extra charge to them.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ...(_rates ?? []).map((rate) {
            final id = rate['object_id'];
            final provider = rate['provider']?.toString() ?? 'Unknown';
            final service =
                (rate['servicelevel'] is Map
                    ? rate['servicelevel']['name']
                    : null)?.toString() ??
                '';
            final amount = rate['amount']?.toString() ?? '0';
            final currency = rate['currency']?.toString() ?? 'USD';
            final days = rate['estimated_days'];
            final isSelected = _selectedRate?['object_id'] == id;

            return RadioListTile<String>(
              value: id,
              groupValue: _selectedRate?['object_id'],
              onChanged: _isLoading
                  ? null
                  : (_) => setState(() => _selectedRate = rate),
              selected: isSelected,
              dense: true,
              title: Text('$provider — $service'),
              subtitle: days != null ? Text('Est. $days day(s)') : null,
              secondary: Text(
                '\$$amount $currency',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Label Generated!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking: $_trackingNumber',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcel Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lengthController,
                  label: 'Length',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _widthController,
                  label: 'Width',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'Height',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('distance_unit'),
                  value: ['in', 'cm', 'ft', 'mm'].contains(_distanceUnit)
                      ? _distanceUnit
                      : 'in',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                  items: ['in', 'cm', 'ft', 'mm']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _distanceUnit = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Weight',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('mass_unit'),
                  value: ['oz', 'lb', 'kg', 'g'].contains(_massUnit)
                      ? _massUnit
                      : 'oz',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                  items: ['oz', 'lb', 'kg', 'g']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _massUnit = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
