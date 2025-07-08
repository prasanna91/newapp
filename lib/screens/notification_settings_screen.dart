import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/env_config.dart';
import '../services/notification_handler.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationHandler _notificationHandler = NotificationHandler();
  String? _fcmToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationInfo();
  }

  Future<void> _loadNotificationInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _fcmToken = _notificationHandler.fcmToken;
    } catch (e) {
      debugPrint('Error loading notification info: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationStatusCard(),
                  const SizedBox(height: 16),
                  _buildFCMTokenCard(),
                  const SizedBox(height: 16),
                  _buildTopicSubscriptionCard(),
                  const SizedBox(height: 16),
                  _buildTestNotificationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  EnvConfig.pushNotify
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: EnvConfig.pushNotify ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Push Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              EnvConfig.pushNotify
                  ? 'Push notifications are enabled for this app.'
                  : 'Push notifications are disabled in configuration.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _notificationHandler.isFirebaseInitialized
                      ? Icons.check_circle
                      : Icons.error,
                  color: _notificationHandler.isFirebaseInitialized
                      ? Colors.green
                      : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _notificationHandler.isFirebaseInitialized
                      ? 'Firebase initialized'
                      : 'Firebase not initialized',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFCMTokenCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.token, size: 24),
                const SizedBox(width: 8),
                Text(
                  'FCM Token',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fcmToken != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  _fcmToken!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _fcmToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('FCM Token copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Token'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _notificationHandler.deleteToken();
                        await _loadNotificationInfo();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('FCM Token deleted')),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No FCM token available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await _loadNotificationInfo();
                },
                child: const Text('Refresh Token'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSubscriptionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.topic, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Topic Subscriptions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTopicItem('all_users', 'All Users'),
            _buildTopicItem('android_users', 'Android Users'),
            _buildTopicItem('ios_users', 'iOS Users'),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicItem(String topic, String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(displayName),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await _notificationHandler.unsubscribeFromTopic(topic);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unsubscribed from $displayName')),
                );
              }
            },
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Test Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Test the notification system with sample messages.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTestNotificationInfo(),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Test Info'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showNotificationFormat(),
                    icon: const Icon(Icons.code, size: 16),
                    label: const Text('Format'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTestNotificationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notification Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To test notifications, send a message to:'),
            const SizedBox(height: 8),
            SelectableText(
              'Topic: all_users',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(
              'Or platform-specific:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText('android_users (Android)'),
            SelectableText('ios_users (iOS)'),
            const SizedBox(height: 8),
            const Text('Use the FCM token above for device-specific testing.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationFormat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Format'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supported notification format:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  '''{
  "message": {
    "topic": "all_users",
    "notification": {
      "title": "ui-ux-design 💬",
      "body": "Hey! This is open https://pixaware.co/solutions/design/ui-ux-design/"
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "url": "https://pixaware.co/solutions/design/ui-ux-design/",
      "image": "https://example.com/image.png",
      "type": "news"
    },
    "apns": {
      "payload": {
        "aps": {
          "alert": {
            "title": "ui-ux-design 💬",
            "body": "Hey! This is open https://pixaware.co/solutions/design/ui-ux-design/"
          },
          "mutable-content": 1
        }
      },
      "fcm_options": {
        "image": "https://example.com/image.png"
      }
    }
  }
}''',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
