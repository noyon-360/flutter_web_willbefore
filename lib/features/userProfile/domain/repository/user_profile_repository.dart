import '../../../../core/pagination/paginated_fetch.dart';
import '../../../order/data/models/user_model.dart';

class InviteUserResult {
  final String uid;
  final String email;

  const InviteUserResult({required this.uid, required this.email});
}

abstract class AllUserProfileRepository {
  Future<PaginatedFetchResult<UserModel>> getUsersPage({
    String? cursor,
    String? searchTerm,
  });

  /// Creates a new admin/user account with a random, never-shared password,
  /// then sends the invited user a Firebase password-reset email so they can
  /// set their own. [role] must be 'admin' or 'user'; enforced server-side
  /// too (only a super admin may invite an admin).
  Future<InviteUserResult> inviteUser({
    required String email,
    required String role,
    String? name,
  });

  /// Changes another user's role. Server-side only a super admin may call
  /// this, and super admin accounts can never be retargeted this way.
  Future<void> updateUserRole(String userId, String role);

  /// Deletes a user's Firestore doc and Firebase Auth account. Server-side
  /// admins may only delete role 'user' accounts; super admins may delete
  /// admins and users but never other super admins.
  Future<void> deleteUser(String userId);
}
