import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutx_core/flutx_core.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../domain/models/promo_model.dart';
import '../../domain/requests/create_promo_request.dart';
import '../../domain/requests/update_promo_request.dart';

class PromosRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PromosRemoteDataSource(this._firestore, this._storage);

  static const String _collection = 'promos';
  static const String _storageFolder = 'promos';

  Future<PaginatedFetchResult<PromoModel>> getPromosPage({
    String? cursor,
    String? searchTerm,
  }) {
    return fetchPaginatedPage<PromoModel>(
      functionName: 'getPromosPage',
      fromMap: (map) => PromoModel.fromFirestore(map, map['id'] as String),
      cursor: cursor,
      searchTerm: searchTerm,
    );
  }

  Future<List<PromoModel>> getPromos() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PromoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      DPrint.log("Error getting promos: $e");
      throw Exception("Failed to get promos: $e");
    }
  }

  Future<PromoModel> getPromoById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        throw Exception("Promo not found");
      }

      return PromoModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      DPrint.log("Error getting promo by id: $e");
      throw Exception("Failed to get promo: $e");
    }
  }

  Future<PromoModel?> getPromoByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return PromoModel.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      DPrint.log("Error getting promo by code: $e");
      throw Exception("Failed to get promo by code: $e");
    }
  }

  Stream<List<PromoModel>> getPromosStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PromoModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<List<PromoModel>> getActivePromos() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now.millisecondsSinceEpoch)
          .where('endDate', isGreaterThan: now.millisecondsSinceEpoch)
          .orderBy('endDate')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PromoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      DPrint.log("Error getting active promos: $e");
      throw Exception("Failed to get active promos: $e");
    }
  }

  Future<PromoModel> createPromo(CreatePromoRequest request) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();

      // Upload image if provided
      String? imageUrl;
      if (request.imageBytes != null && request.imageName != null) {
        imageUrl = await _uploadImage(
          request.imageBytes!,
          '${docRef.id}.${request.imageName!.split('.').last}',
        );
      }

      final promoData = {
        'title': request.title,
        'code': request.code.toUpperCase(),
        'description': request.description,
        'discountPercentage': request.discountPercentage,
        'discountAmount': request.discountAmount,
        'minimumOrderAmount': request.minimumOrderAmount,
        'startDate': request.startDate.millisecondsSinceEpoch,
        'endDate': request.endDate.millisecondsSinceEpoch,
        'imageUrl': imageUrl,
        'isActive': request.isActive,
        'usageLimit': request.usageLimit,
        'usedCount': 0,
        'applicableProductIds': request.applicableProductIds,
        'applicableCategoryIds': request.applicableCategoryIds,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      await docRef.set(promoData);

      return PromoModel.fromFirestore(promoData, docRef.id);
    } catch (e) {
      DPrint.log("Error creating promo: $e");
      throw Exception("Failed to create promo: $e");
    }
  }

  Future<PromoModel> updatePromo(UpdatePromoRequest request) async {
    try {
      final docRef = _firestore.collection(_collection).doc(request.id);
      final now = DateTime.now();

      // Handle image update
      String? imageUrl = request.existingImageUrl;
      
      if (request.imageBytes != null && request.imageName != null) {
        // Delete old image if exists
        if (request.existingImageUrl != null) {
          await _deleteImage(request.existingImageUrl!);
        }
        
        // Upload new image
        imageUrl = await _uploadImage(
          request.imageBytes!,
          '${request.id}.${request.imageName!.split('.').last}',
        );
      }

      final promoData = {
        'title': request.title,
        'code': request.code.toUpperCase(),
        'description': request.description,
        'discountPercentage': request.discountPercentage,
        'discountAmount': request.discountAmount,
        'minimumOrderAmount': request.minimumOrderAmount,
        'startDate': request.startDate.millisecondsSinceEpoch,
        'endDate': request.endDate.millisecondsSinceEpoch,
        'imageUrl': imageUrl,
        'isActive': request.isActive,
        'usageLimit': request.usageLimit,
        'applicableProductIds': request.applicableProductIds,
        'applicableCategoryIds': request.applicableCategoryIds,
        'updatedAt': now.millisecondsSinceEpoch,
      };

      await docRef.update(promoData);

      // Get the updated document
      final doc = await docRef.get();
      return PromoModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      DPrint.log("Error updating promo: $e");
      throw Exception("Failed to update promo: $e");
    }
  }

  Future<void> deletePromo(String id) async {
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
      DPrint.log("Error deleting promo: $e");
      throw Exception("Failed to delete promo: $e");
    }
  }

  Future<void> incrementPromoUsage(String id) async {
    try {
      final docRef = _firestore.collection(_collection).doc(id);
      await docRef.update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      DPrint.log("Error incrementing promo usage: $e");
      throw Exception("Failed to increment promo usage: $e");
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('$_storageFolder/$fileName');
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      DPrint.log("Error uploading image: $e");
      throw Exception("Failed to upload image: $e");
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