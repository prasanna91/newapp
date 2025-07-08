# QuikApp Build System - Web to App with Dynamic Configuration

A Flutter web-to-app application with dynamic configuration powered by Codemagic CI/CD. This app wraps a web application in a native mobile interface with customizable branding, splash screens, bottom navigation, and more.

## 🚀 Features

- **Dynamic Configuration**: All app settings are injected via environment variables
- **Web-to-App**: Wraps web content in a native mobile interface
- **Customizable UI**: Dynamic splash screen, bottom navigation, colors, fonts
- **Pull-to-Refresh**: Built-in refresh functionality for web content
- **Loading Indicators**: Custom loading states with configurable styling
- **Bottom Navigation**: Dynamic menu items with custom icons (preset or custom URLs)
- **Responsive Design**: Works on all screen sizes
- **CI/CD Ready**: Fully configured for Codemagic builds

## 📱 Supported Platforms

- Android (APK & AAB)
- iOS (IPA)
- Web (optional)

## 🏗️ Project Structure

```
quikapp_build_system/
├── lib/
│   ├── config/
│   │   └── env_config.dart          # Auto-generated config from env vars
│   ├── models/
│   │   └── bottom_menu_item.dart    # Bottom menu data models
│   ├── providers/
│   │   └── app_state_provider.dart  # App state management
│   ├── screens/
│   │   ├── main_app_screen.dart     # Main app screen
│   │   └── web_view_screen.dart     # WebView implementation
│   ├── widgets/
│   │   ├── bottom_navigation.dart   # Custom bottom navigation
│   │   └── splash_screen.dart       # Dynamic splash screen
│   └── main.dart                    # App entry point
├── assets/
│   ├── images/                      # App images (logo, icons)
│   ├── fonts/                       # Custom fonts (DM Sans)
│   └── animations/                  # Lottie animations
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
├── codemagic.yaml                  # CI/CD configuration
└── pubspec.yaml                    # Flutter dependencies
```

## ⚙️ Configuration

The app uses dynamic configuration through environment variables. All settings are defined in `lib/config/env_config.dart` which is auto-generated during the build process.

### Key Configuration Areas:

1. **App Metadata**: Name, version, package/bundle IDs
2. **Feature Flags**: Enable/disable features like splash, bottom menu, pull-to-refresh
3. **UI/Branding**: Colors, fonts, logos, splash screen settings
4. **Bottom Menu**: Menu items, icons, styling
5. **Permissions**: Camera, location, microphone, etc.
6. **Firebase**: Push notifications configuration
7. **Code Signing**: Android keystore, iOS certificates

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.4.0 or higher)
- Dart SDK
- Android Studio / Xcode (for platform-specific builds)

### Local Development

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd quikapp_build_system
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Environment Variables

For local development, you can set environment variables in your IDE or use a `.env` file. The app will use default values from `EnvConfig` if variables are not set.

## 🔧 Codemagic Integration

This project is fully configured for Codemagic CI/CD with 5 different workflows:

### Available Workflows

1. **android-free**: Basic Android APK build (no Firebase, no signing)
2. **android-paid**: Android APK with Firebase integration
3. **android-publish**: Android APK & AAB with full signing
4. **ios-workflow**: Universal iOS build (App Store, Ad-Hoc, Enterprise)
5. **combined**: Both Android and iOS builds

### Build Process

1. **Environment Setup**: Variables are injected from API response
2. **Asset Download**: Logos, certificates, and configuration files
3. **Customization**: Package names, app icons, branding
4. **Permissions**: Dynamic permission injection
5. **Firebase**: Configuration based on feature flags
6. **Code Signing**: Platform-specific signing
7. **Build**: APK/AAB/IPA generation
8. **Notification**: Email notifications on completion

### Required Variables

The build system expects these variables from your API:

```json
{
  "appId": "686c8bbc33d17e4298d4dde7",
  "workflowId": "ios-workflow",
  "environment": {
    "variables": {
      "APP_NAME": "QuikApp Build System",
      "WEB_URL": "https://quikapp.co/",
      "PKG_NAME": "com.quikapp.buildsystem",
      "BUNDLE_ID": "com.quikapp.buildsystem",
      "PUSH_NOTIFY": "true",
      "IS_BOTTOMMENU": "true",
      "SPLASH_URL": "https://raw.githubusercontent.com/...",
      "BOTTOMMENU_ITEMS": "[{...}]"
      // ... more variables
    }
  }
}
```

## 🎨 Customization

### Splash Screen

- **Logo**: Set via `SPLASH_URL`
- **Background**: Color via `SPLASH_BG_COLOR` or image via `SPLASH_BG_URL`
- **Tagline**: Text via `SPLASH_TAGLINE`
- **Animation**: Type via `SPLASH_ANIMATION` (zoom, fade, slide)
- **Duration**: Seconds via `SPLASH_DURATION`

### Bottom Navigation

- **Items**: JSON array via `BOTTOMMENU_ITEMS`
- **Colors**: Background, icon, text, active tab colors
- **Font**: Family, size, weight, style
- **Icons**: Preset Material icons or custom URLs (SVG/PNG)

### Web Content

- **URL**: Main website via `WEB_URL`
- **Pull-to-Refresh**: Enable/disable via `IS_PULLDOWN`
- **Loading Indicator**: Enable/disable via `IS_LOAD_IND`

## 📦 Building for Production

### Android

```bash
# Debug build
flutter build apk

# Release build
flutter build apk --release

# App bundle
flutter build appbundle --release
```

### iOS

```bash
# Debug build
flutter build ios

# Release build
flutter build ios --release
```

## 🔐 Code Signing

### Android

- **Keystore**: URL via `KEY_STORE_URL`
- **Password**: Via `CM_KEYSTORE_PASSWORD`
- **Alias**: Via `CM_KEY_ALIAS`
- **Key Password**: Via `CM_KEY_PASSWORD`

### iOS

- **Certificate**: P12 file via `CERT_P12_URL` or CER/KEY combination
- **Password**: Via `CERT_PASSWORD`
- **Provisioning Profile**: Via `PROFILE_URL`
- **Profile Type**: Via `PROFILE_TYPE` (app-store, ad-hoc, enterprise)

## 📧 Notifications

The build system sends email notifications on:

- Build start
- Build success (with artifact links)
- Build failure (with error details)

Configure via:

- `ENABLE_EMAIL_NOTIFICATIONS`
- `EMAIL_SMTP_SERVER`
- `EMAIL_SMTP_PORT`
- `EMAIL_SMTP_USER`
- `EMAIL_SMTP_PASS`

## 🐛 Troubleshooting

### Common Issues

1. **Missing Dependencies**: Run `flutter pub get`
2. **Build Errors**: Check environment variables in Codemagic
3. **Signing Issues**: Verify certificate/keystore URLs and passwords
4. **WebView Issues**: Check internet connectivity and URL validity

### Debug Mode

For debugging, the app uses default values from `EnvConfig`. Check the console output for configuration details.

## 📄 License

This project is proprietary software. All rights reserved.

## 🤝 Support

For support and questions:

- Email: prasannasrinivasan32@gmail.com
- Website: https://twinklub.com/

---

**Built with ❤️ using Flutter and Codemagic**
