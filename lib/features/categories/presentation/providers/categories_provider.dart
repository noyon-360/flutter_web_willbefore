import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_web_willbefore/core/base/base_state.dart';

import '../../data/repos/categories_repo_impl.dart';
import '../../domain/models/category_model.dart';
import '../../domain/requests/create_category_request.dart';
import '../../domain/requests/update_category_request.dart';
import '../../domain/usecases/create_category_use_case.dart';
import '../../domain/usecases/delete_category_use_case.dart';
import '../../domain/usecases/get_category_use_case.dart';
import '../../domain/usecases/update_category_use_case.dart';

class CategoriesState extends BaseState {
  final List<CategoryModel> categories;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchTerm;

  const CategoriesState({
    super.isLoading = false,
    super.errorMessage,
    this.categories = const [],
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchTerm = '',
  });

  @override
  CategoriesState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CategoryModel>? categories,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchTerm,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      categories: categories ?? this.categories,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesProvider, CategoriesState>((ref) {
      final repository = ref.watch(categoriesRepositoryProvider);
      final getCategoriesPageUseCase = GetCategoriesPageUseCase(repository);
      final createCategoryUseCase = CreateCategoryUseCase(repository);
      final updateCategoryUseCase = UpdateCategoryUseCase(repository);
      final deleteCategoryUseCase = DeleteCategoryUseCase(repository);

      return CategoriesProvider(
        getCategoriesPageUseCase,
        createCategoryUseCase,
        updateCategoryUseCase,
        deleteCategoryUseCase,
      );
    });

class CategoriesProvider extends StateNotifier<CategoriesState> {
  final GetCategoriesPageUseCase _getCategoriesPageUseCase;
  final CreateCategoryUseCase _createCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;

  CategoriesProvider(
    this._getCategoriesPageUseCase,
    this._createCategoryUseCase,
    this._updateCategoryUseCase,
    this._deleteCategoryUseCase,
  ) : super(const CategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _getCategoriesPageUseCase.call(
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = CategoriesState(
        categories: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        searchTerm: state.searchTerm,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _getCategoriesPageUseCase.call(
        cursor: state.nextCursor,
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = state.copyWith(
        categories: [...state.categories, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> search(String term) async {
    state = CategoriesState(searchTerm: term, isLoading: true);
    await loadCategories();
  }

  Future<bool> createCategory(CreateCategoryRequest request) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final category = await _createCategoryUseCase.call(request);
      state = state.copyWith(
        isCreating: false,
        categories: [category, ...state.categories],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isCreating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(UpdateCategoryRequest request) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final updated = await _updateCategoryUseCase.call(request);
      state = state.copyWith(
        isUpdating: false,
        categories: state.categories
            .map((c) => c.id == updated.id ? updated : c)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(isDeleting: true, errorMessage: null);
    try {
      await _deleteCategoryUseCase.call(id);
      state = state.copyWith(
        isDeleting: false,
        categories: state.categories.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, errorMessage: e.toString());
      return false;
    }
  }
}
