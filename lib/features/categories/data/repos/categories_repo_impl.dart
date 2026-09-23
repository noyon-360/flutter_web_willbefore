import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repos/categories_repo.dart';
import '../../domain/requests/create_category_request.dart';
import '../../domain/requests/update_category_request.dart';
import '../sources/categories_remote_data_source.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDataSource remoteDataSource;

  CategoriesRepositoryImpl(this.remoteDataSource);

  @override
  Future<PaginatedFetchResult<CategoryModel>> getCategoriesPage({
    String? cursor,
    String? searchTerm,
  }) {
    return remoteDataSource.getCategoriesPage(
      cursor: cursor,
      searchTerm: searchTerm,
    );
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return await remoteDataSource.getCategories();
  }

  @override
  Stream<List<CategoryModel>> getCategoriesStream() {
    return remoteDataSource.getCategoriesStream();
  }

  @override
  Future<CategoryModel> createCategory(CreateCategoryRequest request) async {
    return await remoteDataSource.createCategory(request);
  }

  @override
  Future<CategoryModel> updateCategory(UpdateCategoryRequest request) async {
    return await remoteDataSource.updateCategory(request);
  }

  @override
  Future<void> deleteCategory(String id) async {
    return await remoteDataSource.deleteCategory(id);
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final remoteDataSource = CategoriesRemoteDataSource(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
  return CategoriesRepositoryImpl(remoteDataSource);
});