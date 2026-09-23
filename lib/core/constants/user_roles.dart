/// Central definition of the three account roles used across the app.
///
/// Stored as raw strings on the Firestore `users/{uid}` doc (unchanged for
/// existing `admin`/`user` accounts). `superAdmin` is the new top tier: it
/// can manage admins and users, while `admin` can only manage users.
class UserRoles {
  UserRoles._();

  static const String superAdmin = 'super_admin';
  static const String admin = 'admin';
  static const String user = 'user';

  /// Roles allowed to log into this dashboard at all.
  static const List<String> staffRoles = [superAdmin, admin];

  /// Roles that can be assigned to someone through the invite/role UI.
  /// Super admin is intentionally excluded - it is never granted from the app.
  static const List<String> assignableRoles = [admin, user];

  static bool isSuperAdmin(String? role) => role == superAdmin;

  static bool isAdmin(String? role) => role == admin;

  static bool isStaff(String? role) => role == superAdmin || role == admin;

  static String label(String? role) {
    switch (role) {
      case superAdmin:
        return 'Super Admin';
      case admin:
        return 'Admin';
      default:
        return 'User';
    }
  }
}
