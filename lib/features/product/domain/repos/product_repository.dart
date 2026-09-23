import '../../../../core/pagination/paginated_fetch.dart';
import '../entrity/product.dart';
import '../requests/create_product_request.dart';
import '../requests/update_product_request.dart';


abstract class ProductsRepository {
  Future<PaginatedFetchResult<Product>> getProductsPage({
    String? cursor,
    String? searchTerm,
    bool sortByScore = false,
  });
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByCategory(String categoryId);
  Future<List<Product>> getProductsByPromo(String promoId);
  Future<List<Product>> getActiveProducts();
  Future<Product?> getProductById(String id);
  Future<Product> createProduct(CreateProductRequest request);
  Future<Product> updateProduct(UpdateProductRequest request);
  Future<void> deleteProduct(String id);
  Future<void> updateProductStock(String id, int newStock);
  Future<void> toggleProductStatus(String id, bool isActive);
  Future<List<Product>> searchProducts(String query);
}
