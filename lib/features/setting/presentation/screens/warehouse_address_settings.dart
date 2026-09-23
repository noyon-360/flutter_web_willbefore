// features/warehouse/presentation/screens/warehouse_address_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutx_core/flutx_core.dart';

import '../../domain/models/warehouse_address.dart';
import '../provider/warehouse_provider.dart';

class WarehouseAddressSettings extends ConsumerStatefulWidget {
  const WarehouseAddressSettings({super.key});

  @override
  ConsumerState<WarehouseAddressSettings> createState() =>
      _WarehouseAddressSettingsState();
}

class _WarehouseAddressSettingsState
    extends ConsumerState<WarehouseAddressSettings> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isResidential = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _streetCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _zipCtrl = TextEditingController();
    _countryCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    // Pre-fill with whatever is already loaded, then fetch fresh data.
    final address = ref.read(warehouseProvider).address;
    if (address != null) _fillForm(address);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(warehouseProvider.notifier).refresh();
    });
  }

  void _fillForm(WarehouseAddress address) {
    _nameCtrl.text = address.name ?? '';
    _streetCtrl.text = address.street1 ?? '';
    _cityCtrl.text = address.city ?? '';
    _stateCtrl.text = address.state ?? '';
    _zipCtrl.text = address.zip ?? '';
    _countryCtrl.text = address.country ?? '';
    _emailCtrl.text = address.email ?? '';
    _phoneCtrl.text = address.phone ?? '';
    _isResidential = address.isResidential;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final address = WarehouseAddress(
      name: _nameCtrl.text.trim(),
      street1: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      zip: _zipCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      isResidential: _isResidential,
    );

    final success = await ref.read(warehouseProvider.notifier).save(address);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Warehouse address saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseProvider);
    ref.listen<WarehouseState>(warehouseProvider, (previous, next) {
      if (next.address != null && next.address != previous?.address) {
        setState(() => _fillForm(next.address!));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warehouse Address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Gap.h16,

            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Street 1 *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _stateCtrl,
                decoration: const InputDecoration(
                  labelText: 'State / Province *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _zipCtrl,
                decoration: const InputDecoration(
                  labelText: 'ZIP / Postal Code *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              Gap.h12,

              Row(
                children: [
                  const Text('Is Residential?'),
                  Gap.w8,
                  Switch(
                    value: _isResidential,
                    onChanged: (v) => setState(() => _isResidential = v),
                  ),
                ],
              ),
              Gap.h24,

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _save,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Warehouse Address'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
