# QuikApp Build System Demo Setup Guide

## 🚀 Quick Start

This guide will help you set up and test the QuikApp Build System locally.

## 📋 Prerequisites

- Flutter SDK 3.4.0+
- Dart SDK
- Android Studio / VS Code
- Android Emulator or iOS Simulator

## 🔧 Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

## 🎯 What You'll See

### Default Configuration

The app will start with these default settings (from `EnvConfig`):

- **App Name**: "QuikApp Build System"
- **Website**: https://quikapp.co/
- **Splash Screen**:
  - Logo from GitHub
  - Background color: #cbdbf5 (light blue)
  - Tagline: "QUIKAPP"
  - Animation: zoom
  - Duration: 4 seconds

### Bottom Navigation

The app includes a custom bottom navigation with 4 tabs:

1. **Home** - Main website
2. **Features** - Features page
3. **Documentation** - Documentation page
4. **Support** - Support page

Each tab has:

- Custom icons (preset Material icons or custom SVG/PNG)
- Dynamic colors based on active state
- Custom font (DM Sans)

### Features

- ✅ **Splash Screen**: Animated logo with tagline
- ✅ **Web-to-App**: Wraps web content in native interface
- ✅ **Pull-to-Refresh**: Swipe down to refresh content
- ✅ **Loading Indicators**: Custom loading states
- ✅ **Bottom Navigation**: Dynamic menu with custom styling
- ✅ **Responsive Design**: Works on all screen sizes

## 🔧 Customization

### Environment Variables

You can customize the app by setting environment variables:

```bash
# Example: Run with custom app name
flutter run --dart-define=APP_NAME="My Custom App"

# Example: Run with custom website
flutter run --dart-define=WEB_URL="https://example.com"

# Example: Disable splash screen
flutter run --dart-define=IS_SPLASH=false

# Example: Disable bottom menu
flutter run --dart-define=IS_BOTTOMMENU=false
```

### Available Variables

| Variable           | Type    | Default                | Description                        |
| ------------------ | ------- | ---------------------- | ---------------------------------- |
| `APP_NAME`         | String  | "QuikApp Build System" | App display name                   |
| `WEB_URL`          | String  | "https://quikapp.co/"  | Main website URL                   |
| `IS_SPLASH`        | Boolean | true                   | Enable splash screen               |
| `IS_BOTTOMMENU`    | Boolean | true                   | Enable bottom navigation           |
| `IS_PULLDOWN`      | Boolean | true                   | Enable pull-to-refresh             |
| `IS_LOAD_IND`      | Boolean | true                   | Enable loading indicators          |
| `SPLASH_DURATION`  | String  | "4"                    | Splash screen duration (seconds)   |
| `SPLASH_ANIMATION` | String  | "zoom"                 | Animation type (zoom, fade, slide) |

## 🎨 UI Customization

### Colors

The app uses these default colors:

- **Primary**: #a30237 (dark red)
- **Background**: #cbdbf5 (light blue)
- **Text**: #6d6e8c (gray)
- **Active Tab**: #a30237 (dark red)

### Fonts

- **Primary Font**: DM Sans
- **Font Sizes**: Configurable via `BOTTOMMENU_FONT_SIZE`
- **Font Weight**: Configurable via `BOTTOMMENU_FONT_BOLD`

### Icons

The bottom navigation supports two icon types:

1. **Preset Icons**: Material Design icons

   - `home_outlined`
   - `shopping_cart`
   - `person`
   - `settings`
   - And many more...

2. **Custom Icons**: URLs to SVG or PNG files
   - Supports any image format
   - Automatic color tinting
   - Configurable size

## 🔍 Debug Information

### Console Output

When you run the app, check the console for:

```
🔧 Environment Configuration:
- App Name: QuikApp Build System
- Website: https://quikapp.co/
- Splash Screen: Enabled
- Bottom Menu: Enabled
- Pull-to-Refresh: Enabled
```

### Configuration Details

The app logs configuration details on startup. Look for:

- Environment variables loaded
- Bottom menu items parsed
- Feature flags status
- URL loading status

## 🐛 Troubleshooting

### Common Issues

1. **WebView not loading**

   - Check internet connection
   - Verify URL is accessible
   - Check console for errors

2. **Splash screen not showing**

   - Verify `IS_SPLASH` is true
   - Check logo URL is accessible
   - Verify animation settings

3. **Bottom menu not appearing**

   - Verify `IS_BOTTOMMENU` is true
   - Check menu items JSON format
   - Verify icon URLs are accessible

4. **Font not loading**
   - Ensure DM Sans font files are in `assets/fonts/`
   - Check `pubspec.yaml` font configuration
   - Verify font family name matches

### Debug Mode

For detailed debugging:

```bash
flutter run --debug
```

This will show:

- All environment variables
- Configuration parsing details
- WebView loading status
- Error messages

## 📱 Platform Testing

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Web

```bash
flutter run -d chrome
```

## 🚀 Next Steps

1. **Test all features**: Splash, navigation, web content
2. **Customize colors**: Modify color variables
3. **Add custom icons**: Replace with your own icons
4. **Test on devices**: Run on physical devices
5. **Prepare for Codemagic**: Set up CI/CD pipeline

## 📞 Support

If you encounter issues:

1. Check the console output
2. Verify environment variables
3. Test with default configuration
4. Check Flutter documentation
5. Contact support team

---

**Happy coding! 🎉**
