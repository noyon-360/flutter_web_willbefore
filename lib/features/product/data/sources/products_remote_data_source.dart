import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/pagination/paginated_fetch.dart';
import '../models/product_migration_helper.dart';
import '../models/product_model.dart';

abstract class ProductsRemoteDataSource {
  Future<PaginatedFetchResult<ProductModel>> getProductsPage({
    String? cursor,
    String? searchTerm,
    bool sortByScore = false,
  });
  Future<List<ProductModel>> getAllProducts();
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<List<ProductModel>> getProductsByPromo(String promoId);
  Future<List<ProductModel>> getActiveProducts();
  Future<ProductModel?> getProductById(String id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateProductStock(String id, int newStock);
  Future<void> toggleProductStatus(String id, bool isActive);
  Future<List<ProductModel>> searchProducts(String query);
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProductsRemoteDataSourceImpl(this._firestore);

  @override
  Future<PaginatedFetchResult<ProductModel>> getProductsPage({
    String? cursor,
    String? searchTerm,
    bool sortByScore = false,
  }) {
    return fetchPaginatedPage<ProductModel>(
      functionName: sortByScore ? 'getProductsPageByScore' : 'getProductsPage',
      fromMap: (map) => ProductModel.fromMap(map, map['id'] as String),
      cursor: cursor,
      searchTerm: searchTerm,
    );
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _safeFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _safeFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductsByPromo(String promoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('promoId', isEqualTo: promoId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _safeFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by promo: $e');
    }
  }

  @override
  Future<List<ProductModel>> getActiveProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _safeFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active products: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      
      if (doc.exists) {
        return _safeFromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product by id: $e');
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection('products')
          .add(product.toFirestore());
      
      final doc = await docRef.get();
      return _safeFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      // Get existing product to preserve createdAt
      final existingDoc = await _firestore
          .collection('products')
          .doc(product.id)
          .get();
      
      final existingData = existingDoc.data();
      final updateData = product.toFirestore();
      
      // Preserve original createdAt
      if (existingData != null && existingData['createdAt'] != null) {
        updateData['createdAt'] = existingData['createdAt'];
      }

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updateData);
      
      final doc = await _firestore.collection('products').doc(product.id).get();
      return _safeFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<void> updateProductStock(String id, int newStock) async {
    try {
      await _firestore.collection('products').doc(id).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  @override
  Future<void> toggleProductStatus(String id, bool isActive) async {
    try {
      await _firestore.collection('products').doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to toggle product status: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      // Note: This is a basic search. For better search functionality,
      // consider using Algolia or similar search service
      final querySnapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => _safeFromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Safe method to handle both old and new data formats
  ProductModel _safeFromFirestore(DocumentSnapshot doc) {
    try {
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      // Fallback to migration helper for legacy data
      print('Using migration helper for product: ${doc.id}');
      final data = doc.data() as Map<String, dynamic>;
      return ProductMigrationHelper.fromLegacyData(data, doc.id);
    }
  }
}
