// features/users/presentation/providers/user_provider.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/base/base_state.dart';
import '../../../order/data/models/user_model.dart';
import '../../data/repository/user_profile_repository_impl.dart';
import '../../domain/repository/user_profile_repository.dart';

class AllUserState extends BaseState {
  final List<UserModel> users;
  final String? updateError;
  final String? deleteError;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchTerm;
  final String? lastInvitedEmail;

  const AllUserState({
    super.isLoading = false,
    super.errorMessage,
    this.users = const [],
    this.updateError,
    this.deleteError,
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchTerm = '',
    this.lastInvitedEmail,
  });

  @override
  AllUserState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UserModel>? users,
    String? updateError,
    String? deleteError,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchTerm,
    String? lastInvitedEmail,
  }) {
    return AllUserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      users: users ?? this.users,
      updateError: updateError ?? this.updateError,
      deleteError: deleteError ?? this.deleteError,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
      lastInvitedEmail: lastInvitedEmail ?? this.lastInvitedEmail,
    );
  }
}

final userRepositoryProvider = Provider<AllUserProfileRepository>((ref) {
  return AllUserProfileRepositorImpl();
});

final userProvider = StateNotifierProvider<UserProvider, AllUserState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserProvider(userRepository);
});

/// Kept for screens that need the signed-in user's row from the loaded user
/// list (e.g. to exclude "self" from a table). For role checks, prefer
/// `currentUserRoleProvider` in auth_provider.dart, which does not depend on
/// the paginated list having loaded the current user's page yet.
final currentUserProvider = Provider<UserModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final users = ref.watch(userProvider).users;
  final index = users.indexWhere((u) => u.id == user.uid);

  if (index != -1) {
    return users[index];
  }

  return null;
});

class UserProvider extends StateNotifier<AllUserState> {
  final AllUserProfileRepository _userRepository;

  UserProvider(this._userRepository) : super(const AllUserState()) {
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    state = state.copyWith(isLoading: true);
    try {
      final page = await _userRepository.getUsersPage(
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      if (!mounted) return;
      state = AllUserState(
        users: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        searchTerm: state.searchTerm,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load users: $error',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _userRepository.getUsersPage(
        cursor: state.nextCursor,
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      if (!mounted) return;
      state = state.copyWith(
        users: [...state.users, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more users: $error',
      );
    }
  }

  Future<void> search(String term) async {
    state = AllUserState(searchTerm: term, isLoading: true);
    await _loadFirstPage();
  }

  void refreshUsers() {
    state = AllUserState(searchTerm: state.searchTerm);
    _loadFirstPage();
  }

  /// Creates a new admin or user account with a random, never-shared
  /// password, then sends the invited user a Firebase password-reset email
  /// so they can set their own. [role] must be 'admin' or 'user' (super
  /// admin accounts are never created through the app). Only a super admin
  /// may successfully invite an 'admin' - enforced server-side.
  Future<bool> createUser({
    required String name,
    required String email,
    required String role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      lastInvitedEmail: null,
    );

    try {
      final result = await _userRepository.inviteUser(
        email: email,
        role: role,
        name: name,
      );

      if (!mounted) return true;
      state = AllUserState(
        users: state.users,
        nextCursor: state.nextCursor,
        hasMore: state.hasMore,
        searchTerm: state.searchTerm,
        lastInvitedEmail: result.email,
      );

      // The Cloud Function might take a split second to create the doc in
      // Firestore before it shows up in the paginated list.
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshUsers();
      });

      return true;
    } on FirebaseFunctionsException catch (e) {
      String message = 'Failed to invite user';

      if (e.code == 'permission-denied') {
        message = e.message ?? 'You are not allowed to invite this role';
      } else if (e.code == 'already-exists') {
        message = 'This email is already in use';
      } else if (e.code == 'invalid-argument') {
        message = 'Invalid email address';
      } else {
        message = e.message ?? message;
      }

      if (!mounted) return false;
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    state = state.copyWith(isLoading: true, updateError: null);
    try {
      await _userRepository.updateUserRole(userId, role);

      // Update local state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(role: role);
        }
        return user;
      }).toList();

      if (!mounted) return true;
      state = state.copyWith(users: updatedUsers, isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        updateError: e.message ?? 'Failed to update user role',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        updateError: 'Failed to update user role: $e',
      );
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, deleteError: null);
    try {
      await _userRepository.deleteUser(userId);

      // Remove from local state
      final updatedUsers = state.users
          .where((user) => user.id != userId)
          .toList();

      if (!mounted) return true;
      state = state.copyWith(users: updatedUsers, isLoading: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        deleteError: e.message ?? 'Failed to delete user',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        deleteError: 'Failed to delete user: $e',
      );
      return false;
    }
  }
}
