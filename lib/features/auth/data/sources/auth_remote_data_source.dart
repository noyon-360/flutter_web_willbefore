import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutx_core/flutx_core.dart';

import '../../../../core/errors/auth_exception.dart';
import '../../domain/requests/login_request.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  AuthRemoteDataSource(
    this._firebaseAuth, [
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  ])  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  Future<User> login(LoginRequest request) async {
    DPrint.log("Login Requests -> ${request.email}");
    try {
      // setPersistence is web-only; LOCAL survives browser restarts,
      // SESSION clears when the tab/browser closes.
      if (kIsWeb) {
        await _firebaseAuth.setPersistence(
          request.rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      DPrint.log("Logged in credential : ${userCredential.user?.email}");
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? "Login failed. Please try again.");
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> logout() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token)
              .delete();
        }
      } catch (e) {
        DPrint.error("Failed to clean up FCM token on logout: $e");
      }
    }
    await _firebaseAuth.signOut();
  }
}
