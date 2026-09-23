import '../../../../core/pagination/paginated_fetch.dart';
import '../models/promo_model.dart';
import '../requests/create_promo_request.dart';
import '../requests/update_promo_request.dart';

abstract class PromosRepository {
  Future<PaginatedFetchResult<PromoModel>> getPromosPage({
    String? cursor,
    String? searchTerm,
  });
  Future<List<PromoModel>> getPromos();
  Future<PromoModel> getPromoById(String id);
  Future<PromoModel?> getPromoByCode(String code);
  Future<PromoModel> createPromo(CreatePromoRequest request);
  Future<PromoModel> updatePromo(UpdatePromoRequest request);
  Future<void> deletePromo(String id);
  Stream<List<PromoModel>> getPromosStream();
  Future<List<PromoModel>> getActivePromos();
  Future<void> incrementPromoUsage(String id);
}