import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../network/api_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _initialized = false;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        final messaging = FirebaseMessaging.instance;

        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        debugPrint(
          'Notification permission status: ${settings.authorizationStatus}',
        );

        _fcmToken = await messaging.getToken();
        debugPrint('FCM Device Token: $_fcmToken');

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Foreground notification received: ${message.notification?.title}',
          );
          _showInAppNotification(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) _handleNotificationTap(initialMessage);

        _initialized = true;
      } catch (e) {
        debugPrint('Error initializing Firebase Messaging: $e');
      }
    }
  }

  Future<void> syncDeviceToken(ApiClient apiClient) async {
    if (kIsWeb) return;
    try {
      _fcmToken ??= await FirebaseMessaging.instance.getToken();

      if (_fcmToken != null && apiClient.isAuthenticated) {
        debugPrint('Sending device token to Laravel backend: $_fcmToken');
        await apiClient.post(
          ApiEndpoints.saveDeviceToken,
          body: {'token': _fcmToken},
        );
        debugPrint('Device token saved successfully on backend.');
      }

      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) async {
            _fcmToken = newToken;
            if (apiClient.isAuthenticated) {
              try {
                await apiClient.post(
                  ApiEndpoints.saveDeviceToken,
                  body: {'token': newToken},
                );
              } catch (_) {}
            }
          });
    } catch (e) {
      debugPrint('Error syncing device token: $e');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'إشعار جديد';
    final body = message.notification?.body ?? '';

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2F6F73),
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
      'Notification opened: ${message.messageId}, data: ${message.data}',
    );
  }
}
