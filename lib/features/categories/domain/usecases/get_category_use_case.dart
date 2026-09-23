import '../../../../core/pagination/paginated_fetch.dart';
import '../models/category_model.dart';
import '../repos/categories_repo.dart';

class GetCategoriesPageUseCase {
  final CategoriesRepository repository;

  GetCategoriesPageUseCase(this.repository);

  Future<PaginatedFetchResult<CategoryModel>> call({
    String? cursor,
    String? searchTerm,
  }) {
    return repository.getCategoriesPage(cursor: cursor, searchTerm: searchTerm);
  }
}

class GetCategoriesUseCase {
  final CategoriesRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<CategoryModel>> call() async {
    return await repository.getCategories();
  }

  Stream<List<CategoryModel>> stream() {
    return repository.getCategoriesStream();
  }
}