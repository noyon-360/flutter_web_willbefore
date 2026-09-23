import '../../../../core/pagination/paginated_fetch.dart';
import '../models/promo_model.dart';
import '../repos/promo_reposotory.dart';

class GetPromosPageUseCase {
  final PromosRepository repository;

  GetPromosPageUseCase(this.repository);

  Future<PaginatedFetchResult<PromoModel>> call({
    String? cursor,
    String? searchTerm,
  }) {
    return repository.getPromosPage(cursor: cursor, searchTerm: searchTerm);
  }
}

class GetPromosUseCase {
  final PromosRepository repository;

  GetPromosUseCase(this.repository);

  Future<List<PromoModel>> call() async {
    return await repository.getPromos();
  }

  Stream<List<PromoModel>> stream() {
    return repository.getPromosStream();
  }

  Future<List<PromoModel>> getActive() async {
    return await repository.getActivePromos();
  }

  Future<PromoModel?> getByCode(String code) async {
    return await repository.getPromoByCode(code);
  }
}