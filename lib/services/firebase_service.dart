import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // Callback for handling notification taps
  Function(String)? onNotificationTapped;

  /// Initialize Firebase and push notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up message handlers
      await _setupMessageHandlers();

      // Get FCM token
      await _getFCMToken();

      // Subscribe to topics
      await _subscribeToTopics();

      _isInitialized = true;
      debugPrint('🔥 Firebase service initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          '📱 Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('❌ Failed to request notification permissions: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('📱 Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize local notifications: $e');
    }
  }

  /// Set up Firebase message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    debugPrint('🔔 Firebase message handlers configured');
  }

  /// Get FCM token for this device
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Subscribe to platform-specific and general topics
  Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general topic
      await _firebaseMessaging.subscribeToTopic('all_users');

      // Subscribe to platform-specific topics
      if (Platform.isAndroid) {
        await _firebaseMessaging.subscribeToTopic('android_users');
      } else if (Platform.isIOS) {
        await _firebaseMessaging.subscribeToTopic('ios_users');
      }

      debugPrint(
          '📡 Subscribed to topics: all_users, ${Platform.isAndroid ? "android_users" : "ios_users"}');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topics: $e');
    }
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message received: ${message.messageId}');

    try {
      // Show local notification for foreground messages
      await _showLocalNotification(message);

      // Parse and handle the message data
      _parseMessageData(message);
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }

  /// Handle notification when app is opened from background
  Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    debugPrint('📱 App opened from notification: ${message.messageId}');
    _parseMessageData(message);
  }

  /// Handle initial message when app is opened from terminated state
  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      debugPrint(
          '🚀 App opened from terminated state with notification: ${message.messageId}');
      _parseMessageData(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'quikapp_channel',
        'QuikApp Notifications',
        channelDescription: 'Notifications for QuikApp Build System',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/launcher_icon',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'QuikApp',
        message.notification?.body ?? '',
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  /// Handle notification tap
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    debugPrint('👆 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Parse message data and handle different types
  void _parseMessageData(RemoteMessage message) {
    try {
      Map<String, dynamic> data = message.data;
      _handleNotificationData(data);
    } catch (e) {
      debugPrint('❌ Error parsing message data: $e');
    }
  }

  /// Handle notification data and perform actions
  void _handleNotificationData(Map<String, dynamic> data) {
    try {
      String? url = data['url'];
      String? type = data['type'];
      String? image = data['image'];

      debugPrint(
          '📊 Notification data - URL: $url, Type: $type, Image: $image');

      // Call the callback if provided
      if (onNotificationTapped != null && url != null) {
        onNotificationTapped!(url);
      }

      // Handle different notification types
      switch (type) {
        case 'news':
          _handleNewsNotification(url, image);
          break;
        case 'update':
          _handleUpdateNotification(url);
          break;
        default:
          _handleGenericNotification(url);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling notification data: $e');
    }
  }

  /// Handle news type notifications
  void _handleNewsNotification(String? url, String? image) {
    debugPrint('📰 News notification - URL: $url, Image: $image');
    if (url != null) {
      _launchUrl(url);
    }
  }

  /// Handle update type notifications
  void _handleUpdateNotification(String? url) {
    debugPrint('🔄 Update notification - URL: $url');
    if (url != null) {
      _launchUrl(url);
    }
  }

  /// Handle generic notifications
  void _handleGenericNotification(String? url) {
    debugPrint('📱 Generic notification - URL: $url');
    if (url != null) {
      _launchUrl(url);
    }
  }

  /// Launch URL
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('🌐 Launched URL: $url');
      } else {
        debugPrint('❌ Could not launch URL: $url');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📡 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('📡 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete FCM token: $e');
    }
  }
}
