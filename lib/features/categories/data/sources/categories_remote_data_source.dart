import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutx_core/flutx_core.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../domain/models/category_model.dart';
import '../../domain/requests/create_category_request.dart';
import '../../domain/requests/update_category_request.dart';

class CategoriesRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CategoriesRemoteDataSource(this._firestore, this._storage);

  static const String _collection = 'categories';
  static const String _storageFolder = 'categories';

  Future<PaginatedFetchResult<CategoryModel>> getCategoriesPage({
    String? cursor,
    String? searchTerm,
  }) {
    return fetchPaginatedPage<CategoryModel>(
      functionName: 'getCategoriesPage',
      fromMap: (map) =>
          CategoryModel.fromFirestore(map, map['id'] as String),
      cursor: cursor,
      searchTerm: searchTerm,
    );
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      DPrint.log("Error getting categories: $e");
      throw Exception("Failed to get categories: $e");
    }
  }

  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<CategoryModel> createCategory(CreateCategoryRequest request) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();

      String? imageUrl;
      if (request.imageBytes != null && request.imageName != null) {
        imageUrl = await _uploadImage(
          request.imageBytes!,
          '${docRef.id}_${request.imageName}',
        );
      }

      final categoryData = {
        'name': request.name,
        'imageUrl': imageUrl,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      await docRef.set(categoryData);

      return CategoryModel.fromFirestore(categoryData, docRef.id);
    } catch (e) {
      DPrint.log("Error creating category: $e");
      throw Exception("Failed to create category: $e");
    }
  }

  Future<CategoryModel> updateCategory(UpdateCategoryRequest request) async {
    try {
      final docRef = _firestore.collection(_collection).doc(request.id);
      final now = DateTime.now();

      String? imageUrl = request.existingImageUrl;

      // If new image is provided, upload it and delete old one
      if (request.imageBytes != null && request.imageName != null) {
        // Delete old image if exists
        if (request.existingImageUrl != null) {
          await _deleteImage(request.existingImageUrl!);
        }

        // Upload new image
        imageUrl = await _uploadImage(
          request.imageBytes!,
          '${request.id}_${request.imageName}',
        );
      }

      final categoryData = {
        'name': request.name,
        'imageUrl': imageUrl,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      await docRef.update(categoryData);

      // Get the updated document
      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      DPrint.log("Error updating category: $e");
      throw Exception("Failed to update category: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        final data = doc.data();
        final imageUrl = data?['imageUrl'] as String?;

        // Delete image if exists
        if (imageUrl != null) {
          await _deleteImage(imageUrl);
        }

        // Delete document
        await doc.reference.delete();
      }
    } catch (e) {
      DPrint.log("Error deleting category: $e");
      throw Exception("Failed to delete category: $e");
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('$_storageFolder/$fileName');

      // Determine content type from file extension
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      DPrint.log("Error uploading image: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // default to jpeg
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      DPrint.log("Error deleting image: $e");
      // Don't throw error for image deletion failure
    }
  }
}
