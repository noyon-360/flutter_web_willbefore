import '../../../../core/pagination/paginated_fetch.dart';
import '../../../order/data/models/user_model.dart';

abstract class AllUserProfileRepository {
  Future<PaginatedFetchResult<UserModel>> getUsersPage({
    String? cursor,
    String? searchTerm,
  });
  Future<void> updateUserRole(String userId, String role);
  Future<void> deleteUser(String userId);
}
