import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/pagination/paginated_fetch.dart';
import '../../../order/data/models/user_model.dart';
import '../../domain/repository/user_profile_repository.dart';

class AllUserProfileRepositorImpl implements AllUserProfileRepository {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  AllUserProfileRepositorImpl({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions = functions ?? FirebaseFunctions.instance,
      _auth = auth ?? FirebaseAuth.instance;

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
  Future<InviteUserResult> inviteUser({
    required String email,
    required String role,
    String? name,
  }) async {
    final callable = _functions.httpsCallable('inviteUser');
    final result = await callable.call(<String, dynamic>{
      'email': email,
      'role': role,
      if (name != null && name.isNotEmpty) 'name': name,
    });

    final data = Map<String, dynamic>.from(result.data as Map);

    // The account is created with a random, never-shared password; the
    // invited user sets their own via this reset email. Firebase sends it
    // automatically - no email service/SMTP setup required.
    await _auth.sendPasswordResetEmail(email: email);

    return InviteUserResult(uid: data['uid'] as String, email: email);
  }

  @override
  Future<void> updateUserRole(String userId, String role) async {
    final callable = _functions.httpsCallable('updateUserRole');
    await callable.call(<String, dynamic>{'userId': userId, 'role': role});
  }

  @override
  Future<void> deleteUser(String userId) async {
    final callable = _functions.httpsCallable('deleteAppUser');
    await callable.call(<String, dynamic>{'userId': userId});
  }
}
