import '../../domain/entities/user_entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserProfileRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<User>> getAllUsers() async {
    final userModels = await _remoteDataSource.getAllUsers();
    return userModels.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<List<User>> getAllUsersStream() {
    return _remoteDataSource.getAllUsersStream().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Future<User?> getUserById(String userId) async {
    final userModel = await _remoteDataSource.getUserById(userId);
    return userModel?.toEntity();
  }

  @override
  Future<int> getActiveUsersCount() {
    return _remoteDataSource.getActiveUsersCount();
  }
}
