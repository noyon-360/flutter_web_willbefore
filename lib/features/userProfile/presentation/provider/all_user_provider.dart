// features/users/presentation/providers/user_provider.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:http/http.dart' as http;
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
    );
  }
}

final userRepositoryProvider = Provider<AllUserProfileRepository>((ref) {
  return AllUserProfileRepositorImpl(FirebaseFirestore.instance);
});

final userProvider = StateNotifierProvider<UserProvider, AllUserState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserProvider(userRepository);
});

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
      state = AllUserState(
        users: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        searchTerm: state.searchTerm,
      );
    } catch (error) {
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
      state = state.copyWith(
        users: [...state.users, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
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

  Future<void> makeMeAdminWithToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Not logged in");
      return;
    }

    final idToken = await user.getIdToken(); // this forces a fresh token

    DPrint.log("user token $idToken");

    final response = await http.post(
      Uri.parse('http://localhost:5001/smilestreats/us-central1/makeMeAdmin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken', // this line sends the token
      },
      body: jsonEncode({}), // empty data
    );

    print("Response: ${response.body}");
  }

  Future<bool> createUser({required String name, required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      // makeMeAdminWithToken();

      // await FirebaseFunctions.instance.httpsCallable('makeMeAdmin').call({
      //   "token": await user!.getIdToken(),
      // });
      FirebaseFunctions.instance.httpsCallable("helloWorld");

      // Get the callable function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'inviteUser',
      );

      // Call the function
      final result = await callable.call({'email': email});

      DPrint.log("inviteUser ${result.data['message']}");

      // Success!
      if (result.data['success'] == true) {
        // Success!
        state = state.copyWith(isLoading: false, errorMessage: null);

        // Refresh users list immediately
        // The Cloud Function might take a split second to create the doc in Firestore
        Future.delayed(const Duration(milliseconds: 500), () {
          refreshUsers();
        });

        return true;
      } else {
        throw Exception("Invite failed");
      }
    } on FirebaseFunctionsException catch (e) {
      String message = 'Failed to invite user';

      if (e.code == 'permission-denied') {
        message = 'Only admins can invite users';
      } else if (e.code == 'invalid-argument') {
        message = 'Invalid email address';
      } else {
        message = e.message ?? message;
      }

      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
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

      state = state.copyWith(users: updatedUsers, isLoading: false);
      return true;
    } catch (e) {
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

      state = state.copyWith(users: updatedUsers, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        deleteError: 'Failed to delete user: $e',
      );
      return false;
    }
  }
}
