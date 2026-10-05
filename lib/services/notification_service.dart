// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutx_core/flutx_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  // Background handler (must be top-level/static)
  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    DPrint.log("Background message: ${message.messageId}");
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Firebase messaging on main.dart → safe to use here
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    }

   final granted = await _requestPermissions();

    if (!kIsWeb) {
      await _createNotificationChannel();
    }

    await _initializeLocalNotifications();

    // Safe token handling for iOS + Android + Web
    if (granted) _startFcmTokenSync();
  }

  // ──────────────────────────────────────────────────────────────
  // 1. Permission
  // ──────────────────────────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    DPrint.log("Permission status: ${settings.authorizationStatus}");
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ──────────────────────────────────────────────────────────────
  // 2. Android channel (Non-web only)
  // ──────────────────────────────────────────────────────────────
  Future<void> _createNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // ──────────────────────────────────────────────────────────────
  // 3. Local notifications (foreground)
  // ──────────────────────────────────────────────────────────────
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        DPrint.log("Notification tapped: ${response.payload}");
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      // Local notifications can sometimes work on Web if browser permissions allow,
      // but usually the browser handles foreground notifications itself if integrated correctly.
      // We keep it for consistency.
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }

  // ──────────────────────────────────────────────────────────────
  // 4. SAFE FCM TOKEN + AUTO UPDATE TO FIRESTORE
  // ──────────────────────────────────────────────────────────────
  void _startFcmTokenSync() {
    // First attempt
    _safeGetAndSaveToken();

    // Listen to future refreshes
    _messaging.onTokenRefresh.listen(_safeGetAndSaveToken);
  }

  Future<String?> _safeGetAndSaveToken([String? _]) async {
    String? token;

    if (kIsWeb) {
      try {
        // You might need a VAPID key here if you have one.
        // Example: token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY');
        token = await _messaging.getToken();
      } catch (e) {
        DPrint.error("Failed to get Web FCM token: $e");
      }
    } else if (Platform.isIOS) {
      DPrint.log("Checking for APNs token...");
      for (int i = 0; i < 10; i++) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          DPrint.log("APNs token received");
          break;
        }
        DPrint.log("Waiting for APNs token... attempt ${i + 1}");
        await Future.delayed(const Duration(milliseconds: 500));
      }
      token = await _messaging.getToken();
    } else {
      token = await _messaging.getToken();
    }

    if (token == null) {
      DPrint.error("Failed to retrieve FCM token");
      return null;
    }

    DPrint.log("FCM Token obtained: $token");

    // Save to Firestore if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token)
            .set({
              'token': token,
              'updatedAt': FieldValue.serverTimestamp(),
              'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
              'deviceName': kIsWeb ? 'Web Browser' : Platform.localHostname,
            });

        DPrint.log(
          "FCM token saved to fcmTokens subcollection for ${user.uid}",
        );
      } catch (e) {
        DPrint.error("Failed to save FCM token: $e");
      }
    }

    return token;
  }

  Future<void> removeToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token)
            .delete();
        DPrint.log("FCM token removed from Firestore");
      }
    } catch (e) {
      DPrint.error("Failed to remove FCM token: $e");
    }
  }

  // Public helpers
  Future<String?> getToken() async => await _safeGetAndSaveToken();
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
