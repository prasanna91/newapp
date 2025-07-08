import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../providers/app_state_provider.dart';
import 'firebase_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseService _firebaseService = FirebaseService();
  AppStateProvider? _appStateProvider;

  /// Initialize notification handler
  Future<void> initialize(AppStateProvider appStateProvider) async {
    _appStateProvider = appStateProvider;

    // Set up notification callback
    _firebaseService.onNotificationTapped = _handleNotificationTapped;

    // Initialize Firebase service if push notifications are enabled
    if (EnvConfig.pushNotify) {
      await _firebaseService.initialize();
      debugPrint('🔔 Notification handler initialized with Firebase');
    } else {
      debugPrint('🔕 Push notifications disabled in configuration');
    }
  }

  /// Handle notification tap and navigate accordingly
  void _handleNotificationTapped(String url) {
    debugPrint('👆 Notification tapped with URL: $url');

    if (_appStateProvider != null) {
      // Update the current URL in the app state
      _appStateProvider!.updateCurrentUrl(url);

      // If app is in background, bring it to foreground
      if (_appStateProvider!.isAppInBackground) {
        _appStateProvider!.bringAppToForeground();
      }
    }
  }

  /// Get current FCM token
  String? get fcmToken => _firebaseService.fcmToken;

  /// Check if Firebase is initialized
  bool get isFirebaseInitialized => _firebaseService.isInitialized;

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseService.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseService.unsubscribeFromTopic(topic);
  }

  /// Get notification settings
  Future<dynamic> getNotificationSettings() async {
    return await _firebaseService.getNotificationSettings();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _firebaseService.deleteToken();
  }
}
