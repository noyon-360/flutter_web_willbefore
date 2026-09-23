import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_web_willbefore/core/base/base_state.dart';
import 'package:flutter_web_willbefore/core/constants/user_roles.dart';
import 'package:flutter_web_willbefore/features/auth/data/repos/auth_repository_impl.dart';
import 'package:flutter_web_willbefore/features/auth/domain/models/user_model.dart';
import 'package:flutter_web_willbefore/features/auth/domain/repos/auth_repository.dart';
import 'package:flutter_web_willbefore/features/auth/domain/requests/login_request.dart';
import 'package:flutter_web_willbefore/features/auth/domain/usecases/login_use_case.dart';

/// Sentinel used to distinguish "leave unchanged" from "explicitly clear to
/// null" for nullable fields in [AuthState.copyWith].
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class AuthState extends BaseState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isInitialized;
  final String? role;

  const AuthState({
    super.isLoading = false,
    super.errorMessage,
    this.user,
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.role,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    Object? user = _unset,
    bool? isAuthenticated,
    bool? isInitialized,
    Object? role = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      user: identical(user, _unset) ? this.user : user as UserModel?,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      role: identical(role, _unset) ? this.role : role as String?,
    );
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final loginUseCase = LoginUseCase(authRepository);

  return AuthProvider(loginUseCase, authRepository);
});

/// The signed-in staff member's role ('super_admin' or 'admin'), sourced
/// from their Firestore users/{uid} doc rather than the paginated users
/// list, so it is available even before that list has loaded.
final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).role;
});

final isSuperAdminProvider = Provider<bool>((ref) {
  return UserRoles.isSuperAdmin(ref.watch(currentUserRoleProvider));
});

class AuthProvider extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;

  AuthProvider(this._loginUseCase, this._authRepository) : super(AuthState()) {
    _initializeAuthState();

    /// [Listen] to auth state changes
    _authRepository.authStateChanges.listen((user) {
      state = state.copyWith(user: user, isAuthenticated: user != null);
    });
  }

  Future<void> _initializeAuthState() async {
    try {
      // On web, Firebase restores a persisted session from IndexedDB
      // asynchronously, so `FirebaseAuth.instance.currentUser` can still be
      // null right after startup even when a valid session exists. Waiting
      // for the first `authStateChanges` event avoids bouncing an already
      // logged-in user to the login screen on every page load.
      final user = await _authRepository.authStateChanges.first;
      if (user != null) {
        final role = await _authRepository.getUserRole(user.uid);
        if (!UserRoles.isStaff(role)) {
          await _authRepository.logout();
          if (!mounted) return;
          state = state.copyWith(isAuthenticated: false, isInitialized: true);
          return;
        }
        if (!mounted) return;
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isInitialized: true,
          role: role,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(isAuthenticated: false, isInitialized: true);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isAuthenticated: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> login(LoginRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userModel = await _loginUseCase.call(request);

      final role = await _authRepository.getUserRole(userModel.uid);
      if (!UserRoles.isStaff(role)) {
        await _authRepository.logout();
        if (!mounted) return false;
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Access denied. Only admins can log in.',
        );
        return false;
      }

      if (!mounted) return true;
      state = state.copyWith(isAuthenticated: true, role: role);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.logout();

      if (!mounted) return;
      state = state.copyWith(
        user: null,
        role: null,
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
