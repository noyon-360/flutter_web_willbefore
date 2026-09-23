import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../../order/data/models/user_model.dart';
import '../../domain/repository/user_profile_repository.dart';

class AllUserProfileRepositorImpl implements AllUserProfileRepository {
  final FirebaseFirestore _firestore;

  AllUserProfileRepositorImpl(this._firestore);

  @override
  Future<PaginatedFetchResult<UserModel>> getUsersPage({
    String? cursor,
    String? searchTerm,
  }) {
    return fetchPaginatedPage<UserModel>(
      functionName: 'getUsersPage',
      fromMap: UserModel.fromMap,
      cursor: cursor,
      searchTerm: searchTerm,
    );
  }

  @override
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
