import 'dart:convert';
import 'package:eplace/main.dart';
import 'package:eplace/notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background notification: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String baseUrl = 'http://172.16.123.181:8081/api/v1/notifications';

  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      ).timeout(const Duration(seconds: 5));

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('User denied notification permissions');
        return;
      }
    } catch (e) {
      debugPrint("Notification permissions request failed: $e");
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification tapped: ${details.payload}');
        _navigateToNotifications();
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'eplace_high_importance_channel',
      'ePlace Approval Alerts',
      description: 'Notifications for league approval and rejection updates.',
      importance: Importance.high,
    );

    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint("Failed to create notification channel: $e");
    }

    // Handle background notification clicks (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Notification clicked from background');
      _navigateToNotifications();
    });

    // Handle initial message if app was terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM Notification clicked from terminated state');
        _navigateToNotifications();
      }
    });

    // Foreground Push Notification Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Don't let getToken block initialization if network is unstable
    _firebaseMessaging.getToken().then((token) {
      debugPrint("ePlace FCM Device Token: $token");
    }).catchError((e) {
      debugPrint("Failed to get FCM token: $e");
    });
  }

  static void _navigateToNotifications() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  static Future<void> subscribeToUserTopic(int userId) async {
    final String topic = 'user_$userId';
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print("✅ Successfully subscribed to FCM topic: $topic");
    } catch (e) {
      print("❌ Error subscribing to topic $topic: $e");
    }
  }

  /// Call this when the user logs out
  static Future<void> unsubscribeFromUserTopic(int userId) async {
    final String topic = 'user_$userId';
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print("ℹ️ Unsubscribed from FCM topic: $topic");
    } catch (e) {
      print("❌ Error unsubscribing from topic $topic: $e");
    }
  }


  static Future<List<dynamic>> fetchUserNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'X-User-Id': userId.toString()},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<int> fetchUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/unread-count'),
        headers: {'X-User-Id': userId.toString()},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await http.patch(Uri.parse('$baseUrl/$notificationId/read'));
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}