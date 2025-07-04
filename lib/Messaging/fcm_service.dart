import 'dart:convert'; // Used for encoding/decoding notification payloads
import 'package:firebase_core/firebase_core.dart'; // Required to initialize Firebase
import 'package:firebase_messaging/firebase_messaging.dart'; // For handling FCM push notifications
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For displaying notifications locally

/// This class handles all Firebase Cloud Messaging (FCM) operations
/// including initialization, background/foreground handling, and displaying local notifications.
class FCMService {
  // Firebase Messaging instance to interact with FCM
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Local notifications plugin instance for displaying notifications in foreground
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// This method handles background messages.
  /// Required for FCM to function when the app is not in foreground or terminated.
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(); // Re-initialize Firebase when in background
    print(' Background message: ${message.messageId}');
  }

  /// Initializes FCM and local notifications.
  /// Must be called during app startup (e.g., in `main()`).
  /// The [navigatorKey] allows navigation when a notification is tapped.
  static Future<void> initFCM(GlobalKey<NavigatorState> navigatorKey) async {
    // Request permission for iOS; on Android it’s granted by default
    await _messaging.requestPermission();

    // Get the device's unique FCM token (used to send notifications to it)
    String? token = await _messaging.getToken();
    print('*_*_*_*FCM Token: $token');

    // Android-specific initialization settings for local notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // 🔧 Replace with your app icon if needed

    // Common initialization settings (can include iOS/Mac if needed)
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize local notifications and handle notification taps
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!); // Decode payload sent with notification
            _navigateToReview(data, navigatorKey); // Navigate on tap
          } catch (e) {
            print(" Error parsing payload: $e");
          }
        }
      },
    );

    //  Handle notifications received while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');

      if (message.notification != null) {
        final data = message.data;
        final userId = data['userId'];
        final entryId = data['entryId'];
        final reviewId = data['reviewId'];

        // Show local notification only if these IDs are present
        if (userId != null && entryId != null && reviewId != null) {
          final payload = jsonEncode(data); // Encode data to attach as payload
          _showNotification(
            title: message.notification!.title ?? 'No Title',
            body: message.notification!.body ?? 'No Body',
            payload: payload,
          );
        }
      }
    });

    //  Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(' Notification tapped (from background)');
      final data = message.data;
      _navigateToReview(data, navigatorKey); // Navigate to appropriate screen
    });

    //  Register background handler (app terminated or not running)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Displays a local notification using FlutterLocalNotificationsPlugin
  static Future<void> _showNotification({
    required String title,
    required String body,
    String? payload, // Optional JSON payload for handling navigation
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // 🔧 Channel ID (must match AndroidManifest if customized)
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification with title, body, and optional payload
    await _localNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Navigates to specific screens based on notification data
  /// First goes to `/review`, then pushes to `/reviewDetail`
  static void _navigateToReview(Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
    final userId = data['userId'];
    final entryId = data['entryId'];
    final reviewId = data['reviewId'];

    if (userId != null && entryId != null && reviewId != null) {
      final context = navigatorKey.currentContext;

      if (context != null) {
        // First navigate to the review overview screen
        Navigator.pushNamed(context, '/review', arguments: {
          'userId': userId,
          'entryId': entryId,
          'reviewId': reviewId,
        });

        // Then navigate to detailed review screen after a short delay
        Future.delayed(Duration(milliseconds: 300), () {
          Navigator.pushNamed(
            context,
            '/reviewDetail',
            arguments: {
              'userId': userId,
              'entryId': entryId,
              'reviewId': reviewId,
            },
          );
        });
      }
    }
  }
}
