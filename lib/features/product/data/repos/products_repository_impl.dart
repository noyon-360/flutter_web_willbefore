import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_web_willbefore/features/product/domain/repos/product_repository.dart' show ProductsRepository;
import 'dart:typed_data';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../domain/entrity/product.dart';
import '../models/product_model.dart';
import '../../domain/requests/create_product_request.dart';
import '../../domain/requests/update_product_request.dart';
import '../sources/products_remote_data_source.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;
  final FirebaseStorage _storage;

  ProductsRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<PaginatedFetchResult<Product>> getProductsPage({
    String? cursor,
    String? searchTerm,
    bool sortByScore = false,
  }) async {
    try {
      final page = await _remoteDataSource.getProductsPage(
        cursor: cursor,
        searchTerm: searchTerm,
        sortByScore: sortByScore,
      );
      return PaginatedFetchResult<Product>(
        items: page.items.map((model) => model.toEntity()).toList(),
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (e) {
      throw Exception('Failed to get products page: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final productModels = await _remoteDataSource.getAllProducts();
      return productModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final productModels = await _remoteDataSource.getProductsByCategory(categoryId);
      return productModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByPromo(String promoId) async {
    try {
      final productModels = await _remoteDataSource.getProductsByPromo(promoId);
      return productModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get products by promo: $e');
    }
  }

  @override
  Future<List<Product>> getActiveProducts() async {
    try {
      final productModels = await _remoteDataSource.getActiveProducts();
      return productModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get active products: $e');
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final productModel = await _remoteDataSource.getProductById(id);
      return productModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get product by id: $e');
    }
  }

  @override
  Future<Product> createProduct(CreateProductRequest request) async {
    try {
      // Upload images to Firebase Storage
      final imageUrls = <String>[];
      for (int i = 0; i < request.images.length; i++) {
        final imageData = request.images[i];
        final imageUrl = await _uploadImage(
          imageData.bytes,
          'products/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        imageUrls.add(imageUrl);
      }

      // Create product model
      final productModel = ProductModel(
        id: '', // Will be set by Firestore
        title: request.title,
        description: request.description,
        actualPrice: request.actualPrice,
        discountPrice: request.discountPrice,
        stock: request.stock,
        categoryId: request.categoryId,
        promoId: request.promoId,
        sizes: request.sizes,
        colors: request.colors,
        colorCodes: request.colorCodes,
        imageUrls: imageUrls,
        facilities: request.facilities,
        isActive: request.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdModel = await _remoteDataSource.createProduct(productModel);
      return createdModel.toEntity();
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product> updateProduct(UpdateProductRequest request) async {
    try {
      // Upload new images if any
      final newImageUrls = <String>[];
      for (int i = 0; i < request.newImages.length; i++) {
        final imageData = request.newImages[i];
        final imageUrl = await _uploadImage(
          imageData.bytes,
          'products/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        newImageUrls.add(imageUrl);
      }

      // Combine existing and new image URLs
      final allImageUrls = [...request.existingImageUrls, ...newImageUrls];

      // Create updated product model
      final productModel = ProductModel(
        id: request.id,
        title: request.title,
        description: request.description,
        actualPrice: request.actualPrice,
        discountPrice: request.discountPrice,
        stock: request.stock,
        categoryId: request.categoryId,
        promoId: request.promoId,
        sizes: request.sizes,
        colors: request.colors,
        colorCodes: request.colorCodes,
        imageUrls: allImageUrls,
        facilities: request.facilities,
        isActive: request.isActive,
        createdAt: DateTime.now(), // Will be preserved by datasource
        updatedAt: DateTime.now(),
      );

      final updatedModel = await _remoteDataSource.updateProduct(productModel);
      return updatedModel.toEntity();
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // Get product to delete images from storage
      final product = await _remoteDataSource.getProductById(id);
      if (product != null) {
        // Delete images from Firebase Storage
        for (final imageUrl in product.imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Failed to delete image: $imageUrl, error: $e');
          }
        }
      }

      await _remoteDataSource.deleteProduct(id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<void> updateProductStock(String id, int newStock) async {
    try {
      await _remoteDataSource.updateProductStock(id, newStock);
    } catch (e) {
      throw Exception('Failed to update product stock: $e');
    }
  }

  @override
  Future<void> toggleProductStatus(String id, bool isActive) async {
    try {
      await _remoteDataSource.toggleProductStatus(id, isActive);
    } catch (e) {
      throw Exception('Failed to toggle product status: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final productModels = await _remoteDataSource.searchProducts(query);
      return productModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
