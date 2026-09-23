import '../../../../core/pagination/paginated_fetch.dart';
import '../entrity/product.dart';
import '../repos/product_repository.dart';

class GetProductsPageUseCase {
  final ProductsRepository _repository;

  GetProductsPageUseCase(this._repository);

  Future<PaginatedFetchResult<Product>> call({
    String? cursor,
    String? searchTerm,
    bool sortByScore = false,
  }) {
    return _repository.getProductsPage(
      cursor: cursor,
      searchTerm: searchTerm,
      sortByScore: sortByScore,
    );
  }
}

class GetProductsUseCase {
  final ProductsRepository _repository;

  GetProductsUseCase(this._repository);

  Future<List<Product>> call() async {
    return await _repository.getAllProducts();
  }
}

class GetActiveProductsUseCase {
  final ProductsRepository _repository;

  GetActiveProductsUseCase(this._repository);

  Future<List<Product>> call() async {
    return await _repository.getActiveProducts();
  }
}

class GetProductsByCategoryUseCase {
  final ProductsRepository _repository;

  GetProductsByCategoryUseCase(this._repository);

  Future<List<Product>> call(String categoryId) async {
    return await _repository.getProductsByCategory(categoryId);
  }
}

class GetProductsByPromoUseCase {
  final ProductsRepository _repository;

  GetProductsByPromoUseCase(this._repository);

  Future<List<Product>> call(String promoId) async {
    return await _repository.getProductsByPromo(promoId);
  }
}

class GetProductByIdUseCase {
  final ProductsRepository _repository;

  GetProductByIdUseCase(this._repository);

  Future<Product?> call(String id) async {
    return await _repository.getProductById(id);
  }
}

class SearchProductsUseCase {
  final ProductsRepository _repository;

  SearchProductsUseCase(this._repository);

  Future<List<Product>> call(String query) async {
    return await _repository.searchProducts(query);
  }
}
