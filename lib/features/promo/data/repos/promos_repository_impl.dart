import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../domain/models/promo_model.dart';
import '../../domain/repos/promo_reposotory.dart';
import '../../domain/requests/create_promo_request.dart';
import '../../domain/requests/update_promo_request.dart';
import '../sources/promo_remote_data_source.dart';

class PromosRepositoryImpl implements PromosRepository {
  final PromosRemoteDataSource remoteDataSource;

  PromosRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedFetchResult<PromoModel>> getPromosPage({
    String? cursor,
    String? searchTerm,
  }) {
    return remoteDataSource.getPromosPage(cursor: cursor, searchTerm: searchTerm);
  }

  @override
  Future<List<PromoModel>> getPromos() async {
    return await remoteDataSource.getPromos();
  }

  @override
  Future<PromoModel> getPromoById(String id) async {
    return await remoteDataSource.getPromoById(id);
  }

  @override
  Future<PromoModel?> getPromoByCode(String code) async {
    return await remoteDataSource.getPromoByCode(code);
  }

  @override
  Stream<List<PromoModel>> getPromosStream() {
    return remoteDataSource.getPromosStream();
  }

  @override
  Future<List<PromoModel>> getActivePromos() async {
    return await remoteDataSource.getActivePromos();
  }

  @override
  Future<PromoModel> createPromo(CreatePromoRequest request) async {
    return await remoteDataSource.createPromo(request);
  }

  @override
  Future<PromoModel> updatePromo(UpdatePromoRequest request) async {
    return await remoteDataSource.updatePromo(request);
  }

  @override
  Future<void> deletePromo(String id) async {
    return await remoteDataSource.deletePromo(id);
  }

  @override
  Future<void> incrementPromoUsage(String id) async {
    return await remoteDataSource.incrementPromoUsage(id);
  }
}

final promosRepositoryProvider = Provider<PromosRepository>((ref) {
  final remoteDataSource = PromosRemoteDataSource(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
  return PromosRepositoryImpl(remoteDataSource);
});