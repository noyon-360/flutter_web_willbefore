import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_web_willbefore/core/base/base_state.dart';
import '../../data/repos/promos_repository_impl.dart';
import '../../domain/models/promo_model.dart';
import '../../domain/requests/create_promo_request.dart';
import '../../domain/requests/update_promo_request.dart';
import '../../domain/usecases/create_promo_use_case.dart';
import '../../domain/usecases/delete_promo_use_case.dart';
import '../../domain/usecases/get_promo_use_case.dart';
import '../../domain/usecases/update_promo_use_case.dart';

class PromosState extends BaseState {
  final List<PromoModel> promos;
  final List<PromoModel> activePromos;
  final PromoModel? selectedPromo;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;

  // Paginated results for the admin promo management table. `promos` above
  // stays reserved for the (small, filtered) active/non-expired dropdown
  // used when attaching a promo to a product.
  final List<PromoModel> adminPromos;
  final bool isLoadingAdmin;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchTerm;

  const PromosState({
    super.isLoading = true,
    super.errorMessage,
    this.promos = const [],
    this.activePromos = const [],
    this.selectedPromo,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.adminPromos = const [],
    this.isLoadingAdmin = true,
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchTerm = '',
  });

  @override
  PromosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<PromoModel>? promos,
    List<PromoModel>? activePromos,
    PromoModel? selectedPromo,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    List<PromoModel>? adminPromos,
    bool? isLoadingAdmin,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchTerm,
  }) {
    return PromosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      promos: promos ?? this.promos,
      activePromos: activePromos ?? this.activePromos,
      selectedPromo: selectedPromo ?? this.selectedPromo,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      adminPromos: adminPromos ?? this.adminPromos,
      isLoadingAdmin: isLoadingAdmin ?? this.isLoadingAdmin,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

final promosProvider = StateNotifierProvider<PromosProvider, PromosState>((
  ref,
) {
  final repository = ref.watch(promosRepositoryProvider);
  final getPromosUseCase = GetPromosUseCase(repository);
  final getPromosPageUseCase = GetPromosPageUseCase(repository);
  final createPromoUseCase = CreatePromoUseCase(repository);
  final updatePromoUseCase = UpdatePromoUseCase(repository);
  final deletePromoUseCase = DeletePromoUseCase(repository);

  return PromosProvider(
    getPromosUseCase,
    getPromosPageUseCase,
    createPromoUseCase,
    updatePromoUseCase,
    deletePromoUseCase,
  );
});

class PromosProvider extends StateNotifier<PromosState> {
  final GetPromosUseCase _getPromosUseCase;
  final GetPromosPageUseCase _getPromosPageUseCase;
  final CreatePromoUseCase _createPromoUseCase;
  final UpdatePromoUseCase _updatePromoUseCase;
  final DeletePromoUseCase _deletePromoUseCase;

  PromosProvider(
    this._getPromosUseCase,
    this._getPromosPageUseCase,
    this._createPromoUseCase,
    this._updatePromoUseCase,
    this._deletePromoUseCase,
  ) : super(const PromosState()) {
    _listenToPromos();
    loadAdminPromos();
  }

  Future<void> loadAdminPromos() async {
    state = state.copyWith(isLoadingAdmin: true);
    try {
      final page = await _getPromosPageUseCase.call(
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = state.copyWith(
        adminPromos: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingAdmin: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingAdmin: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _getPromosPageUseCase.call(
        cursor: state.nextCursor,
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = state.copyWith(
        adminPromos: [...state.adminPromos, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> search(String term) async {
    state = state.copyWith(
      searchTerm: term,
      adminPromos: [],
      nextCursor: null,
      hasMore: true,
    );
    await loadAdminPromos();
  }

  void _listenToPromos() {
    _getPromosUseCase.stream().listen(
      (promos) {
        // activePromos for CUSTOMER (must be currently active)
        final activePromos = promos
            .where((promo) => promo.isCurrentlyActive)
            .toList();

        // promos for ADMIN (can include future promos, just not expired ones)
        final selectablePromosForAdmin = promos
            .where((promo) => promo.isActive && !promo.isExpired)
            .toList();

        state = state.copyWith(
          promos:
              selectablePromosForAdmin, // Use this for dropdowns in admin screens
          activePromos: activePromos,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  // Future<void> loadPromos() async {
  //   state = state.copyWith(isLoading: true, errorMessage: null);
  //   try {
  //     final promos = await _getPromosUseCase.call();
  //     final activePromos = await _getPromosUseCase.getActive();
  //     DPrint.log("Promo codes : ${promos.first.code}");
  //     state = state.copyWith(
  //       promos: promos,
  //       activePromos: activePromos,
  //       isLoading: false,
  //     );
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: e.toString());
  //   }
  // }

  Future<bool> createPromo(CreatePromoRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final promo = await _createPromoUseCase.call(request);
      state = state.copyWith(
        isCreating: false,
        adminPromos: [promo, ...state.adminPromos],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isCreating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updatePromo(UpdatePromoRequest request) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final updated = await _updatePromoUseCase.call(request);
      state = state.copyWith(
        isUpdating: false,
        adminPromos: state.adminPromos
            .map((p) => p.id == updated.id ? updated : p)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deletePromo(String id) async {
    state = state.copyWith(isDeleting: true, errorMessage: null);
    try {
      await _deletePromoUseCase.call(id);
      state = state.copyWith(
        isDeleting: false,
        adminPromos: state.adminPromos.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, errorMessage: e.toString());
      return false;
    }
  }

  void setSelectedPromo(PromoModel? promo) {
    state = state.copyWith(selectedPromo: promo);
  }

  Future<PromoModel?> validatePromoCode(String code) async {
    try {
      final promo = await _getPromosUseCase.getByCode(code);
      if (promo != null && promo.isCurrentlyActive) {
        return promo;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
