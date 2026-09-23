import '../entities/user_entities.dart';

abstract class UserProfileRepository {
  Future<List<User>> getAllUsers();
  Stream<List<User>> getAllUsersStream();
  Future<User?> getUserById(String userId);
  Future<int> getActiveUsersCount();
}
