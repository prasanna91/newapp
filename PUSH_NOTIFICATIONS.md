# Push Notifications Implementation Guide

## 🚀 Overview

The QuikApp Build System now supports comprehensive push notifications with Firebase Cloud Messaging (FCM) for all three app states:

1. **App Closed State** - Notifications wake up the app
2. **App Background State** - Notifications bring app to foreground
3. **App Open State** - Notifications show as in-app alerts

## 🔧 Features

### ✅ Supported Features

- **Multi-State Handling**: All three app states supported
- **Topic Subscriptions**: Platform-specific and general topics
- **Rich Notifications**: Images, custom data, and actions
- **Deep Linking**: URL navigation from notifications
- **FCM Token Management**: Automatic token refresh and management
- **Notification Settings UI**: Built-in settings screen
- **Background Processing**: Custom Firebase messaging service

### 📱 Platform Support

- **Android**: Custom Firebase messaging service
- **iOS**: Native notification handling with rich media support
- **Cross-Platform**: Unified notification handling

## 🏗️ Architecture

### Core Components

1. **FirebaseService** (`lib/services/firebase_service.dart`)

   - Handles FCM initialization and token management
   - Manages notification permissions
   - Processes messages for all app states
   - Handles topic subscriptions

2. **NotificationHandler** (`lib/services/notification_handler.dart`)

   - Integrates with app state management
   - Handles notification taps and navigation
   - Manages app lifecycle state

3. **AppStateProvider** (Updated)

   - Tracks app background/foreground state
   - Manages URL navigation from notifications
   - Handles app lifecycle changes

4. **NotificationSettingsScreen** (`lib/screens/notification_settings_screen.dart`)
   - Shows FCM token and status
   - Manages topic subscriptions
   - Provides testing information

## 🔥 Firebase Setup

### Android Configuration

1. **MainActivity** (`android/app/src/main/kotlin/com/quikapp/buildsystem/MainActivity.kt`)

   ```kotlin
   class MainActivity: FlutterActivity() {
       override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
           GeneratedPluginRegistrant.registerWith(flutterEngine)
       }
   }
   ```

2. **Custom Firebase Service** (`android/app/src/main/kotlin/com/quikapp/buildsystem/QuikAppFirebaseMessagingService.kt`)

   - Handles background notifications
   - Creates notification channels
   - Manages notification display

3. **AndroidManifest.xml** (Auto-configured by build scripts)
   ```xml
   <service
       android:name=".QuikAppFirebaseMessagingService"
       android:exported="false">
       <intent-filter>
           <action android:name="com.google.firebase.MESSAGING_EVENT" />
       </intent-filter>
   </service>
   ```

### iOS Configuration

1. **AppDelegate** (`ios/Runner/AppDelegate.swift`)

   ```swift
   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
       override func application(
           _ application: UIApplication,
           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
       ) -> Bool {
           FirebaseApp.configure()
           Messaging.messaging().delegate = self
           // ... notification setup
           return super.application(application, didFinishLaunchingWithOptions: launchOptions)
       }
   }
   ```

2. **Notification Delegates**
   - `MessagingDelegate`: Handles FCM token updates
   - `UNUserNotificationCenterDelegate`: Handles notification display and taps

## 📨 Notification Format

### Supported Message Structure

```json
{
  "message": {
    "topic": "all_users",
    "notification": {
      "title": "ui-ux-design 💬",
      "body": "Hey! This is open https://pixaware.co/solutions/design/ui-ux-design/"
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "url": "https://pixaware.co/solutions/design/ui-ux-design/",
      "image": "https://s3-us-west-2.amazonaws.com/issuewireassets/primg/158125/og_pw-logo-white-11zon66751544.png",
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
        },
        "yourCustomImageUrlKey": "https://s3-us-west-2.amazonaws.com/issuewireassets/primg/158125/og_pw-logo-white-11zon66751544.png"
      },
      "fcm_options": {
        "image": "https://s3-us-west-2.amazonaws.com/issuewireassets/primg/158125/og_pw-logo-white-11zon66751544.png"
      }
    }
  }
}
```

### Message Components

1. **Topic Targeting**

   - `all_users`: All app users
   - `android_users`: Android users only
   - `ios_users`: iOS users only

2. **Notification Block**

   - `title`: Notification title
   - `body`: Notification message

3. **Data Block**

   - `click_action`: Required for Flutter
   - `url`: Deep link URL
   - `image`: Rich notification image
   - `type`: Notification type (news, update, etc.)

4. **APNS Block** (iOS-specific)
   - Rich media support
   - Custom payload data
   - FCM options for images

## 🎯 App State Handling

### 1. App Closed State

```dart
// Handled by FirebaseMessaging.instance.getInitialMessage()
FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
```

### 2. App Background State

```dart
// Handled by FirebaseMessaging.onMessageOpenedApp
FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
```

### 3. App Open State

```dart
// Handled by FirebaseMessaging.onMessage
FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
```

## 🔧 Configuration

### Environment Variables

The push notification system is controlled by these environment variables:

```yaml
# Enable/disable push notifications
PUSH_NOTIFY: "true"

# Firebase configuration (auto-injected by build scripts)
FIREBASE_CONFIG_ANDROID: "base64_encoded_google_services_json"
FIREBASE_CONFIG_IOS: "base64_encoded_GoogleService_Info_plist"
```

### Build Script Integration

The build scripts automatically:

1. **Download Firebase Config**: From provided URLs
2. **Inject Configuration**: Into platform-specific files
3. **Setup Permissions**: Add notification permissions
4. **Configure Services**: Set up Firebase messaging services

## 🧪 Testing

### 1. Using FCM Console

1. Go to Firebase Console > Cloud Messaging
2. Create a new notification
3. Target by topic: `all_users`, `android_users`, or `ios_users`
4. Use the message format above
5. Send and test

### 2. Using FCM Token

1. Open the app
2. Go to Notification Settings (bell icon in app bar)
3. Copy the FCM token
4. Use FCM Console to send to specific device

### 3. Using cURL

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "DEVICE_FCM_TOKEN",
       "notification": {
         "title": "Test Notification",
         "body": "This is a test message"
       },
       "data": {
         "url": "https://quikapp.co/",
         "type": "test"
       }
     }' \
     https://fcm.googleapis.com/fcm/send
```

### 4. Topic Testing

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "/topics/all_users",
       "notification": {
         "title": "Topic Test",
         "body": "This goes to all users"
       },
       "data": {
         "url": "https://quikapp.co/",
         "type": "news"
       }
     }' \
     https://fcm.googleapis.com/fcm/send
```

## 📱 User Experience

### Notification Settings Screen

The app includes a built-in notification settings screen accessible via the bell icon in the app bar (when `PUSH_NOTIFY=true`).

**Features:**

- ✅ Notification status indicator
- 🔑 FCM token display and copy
- 📡 Topic subscription management
- 🧪 Testing information and format examples

### App State Indicators

The app tracks and responds to:

- **Foreground**: Shows in-app notifications
- **Background**: Brings app to foreground on tap
- **Terminated**: Launches app and navigates to URL

## 🔐 Security Considerations

### Token Management

- Automatic token refresh
- Secure token storage
- Token deletion capability

### Permission Handling

- Graceful permission requests
- Fallback for denied permissions
- Platform-specific permission handling

### Data Validation

- URL validation before navigation
- Safe JSON parsing
- Error handling for malformed messages

## 🚀 Deployment

### Codemagic Integration

The push notification system is fully integrated with Codemagic CI/CD:

1. **Environment Variables**: Automatically injected from API
2. **Firebase Config**: Downloaded and configured during build
3. **Platform Setup**: Android and iOS services configured
4. **Testing**: Ready for production deployment

### Production Checklist

- [ ] Firebase project configured
- [ ] FCM API key obtained
- [ ] Platform-specific config files uploaded
- [ ] Environment variables set in Codemagic
- [ ] Test notifications sent
- [ ] Deep linking verified
- [ ] App state handling tested

## 📚 Troubleshooting

### Common Issues

1. **Notifications not showing**

   - Check `PUSH_NOTIFY` environment variable
   - Verify Firebase configuration
   - Check notification permissions

2. **Deep links not working**

   - Verify URL format in notification data
   - Check app state handling
   - Test with valid URLs

3. **FCM token issues**
   - Check Firebase project configuration
   - Verify platform-specific setup
   - Test token generation

### Debug Information

The app provides comprehensive debug logging:

```
🔔 Firebase service initialized successfully
📱 Notification permission status: authorized
🔑 FCM Token: [token]
📡 Subscribed to topics: all_users, android_users
📨 Foreground message received: [message_id]
👆 Notification tapped: [payload]
```

## 🎉 Summary

The QuikApp Build System now provides a complete push notification solution that:

- ✅ Supports all three app states
- ✅ Handles rich notifications with images
- ✅ Provides deep linking capabilities
- ✅ Includes comprehensive testing tools
- ✅ Integrates seamlessly with Codemagic CI/CD
- ✅ Offers user-friendly settings interface

The implementation is production-ready and follows Firebase best practices for both Android and iOS platforms.
