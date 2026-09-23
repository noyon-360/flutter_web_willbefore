// features/warehouse/presentation/providers/warehouse_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/warehouse_address.dart';

class WarehouseState {
  final WarehouseAddress? address;
  final bool isLoading;
  final String? error;

  WarehouseState({this.address, this.isLoading = false, this.error});

  WarehouseState copyWith({WarehouseAddress? address, bool? isLoading, String? error}) {
    return WarehouseState(
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Keep your FutureProvider
final _warehouseAddressProvider = FutureProvider<WarehouseAddress?>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('settings')
      .doc('warehouse_address')
      .get();
  if (!doc.exists) return null;
  return WarehouseAddress.fromJson(doc.data()!);
});

// StateNotifier that watches the FutureProvider
final warehouseProvider = StateNotifierProvider<WarehouseProvider, WarehouseState>((ref) {
  return WarehouseProvider(ref);
});

class WarehouseProvider extends StateNotifier<WarehouseState> {
  final Ref _ref;

  WarehouseProvider(this._ref) : super(WarehouseState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final asyncValue = await _ref.read(_warehouseAddressProvider.future);
    if (!mounted) return;
    state = state.copyWith(address: asyncValue, isLoading: false);
  }

  Future<bool> save(WarehouseAddress address) async {
    state = state.copyWith(isLoading: true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('warehouse_address')
          .set(address.toJson(), SetOptions(merge: true));

      if (!mounted) return true;
      state = state.copyWith(address: address, isLoading: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // Optional: refresh
  void refresh() => _load();
}