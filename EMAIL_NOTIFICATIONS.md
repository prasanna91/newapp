# 📧 Email Notification System for QuikApp Build System

## Overview

The QuikApp Build System includes a comprehensive email notification system that sends detailed notifications at three key points during the build process:

1. **Build Started** - When the build process begins
2. **Build Success** - When the build completes successfully
3. **Build Failed** - When the build encounters errors

## 🎨 Email Design Features

### Visual Design

- **Modern gradient backgrounds** with QuikApp's signature colors (#667eea, #764ba2)
- **Clean card-based layout** with rounded corners and subtle shadows
- **Responsive design** that works on mobile and desktop
- **Professional typography** using system fonts for consistency

### Status-Specific Styling

- 🚀 **Build Started**: Blue gradient (#667eea)
- 🎉 **Build Success**: Green gradient (#11998e)
- ❌ **Build Failed**: Red gradient (#ff6b6b)

### QuikApp Branding

- QuikApp logo in the footer
- Links to: quikapp.co, app.quikapp.co, documentation, and support
- Professional footer with copyright and attribution

## 📋 Email Content Sections

### 1. App Information 📱

- **App Name**: Display name of the application
- **Version**: Version name and code
- **Bundle ID/Package Name**: Platform-specific identifiers
- **Workflow**: Which Codemagic workflow was executed
- **Build Duration**: How long the build took

### 2. Customization Features 🎨

- **Splash Screen**: Status of splash screen feature
- **Bottom Menu**: Status of bottom navigation menu
- **Pull to Refresh**: Status of pull-to-refresh functionality
- **Loading Indicator**: Status of loading indicators

### 3. Permissions 🔐

- **Camera**: Camera access permission
- **Location**: GPS and location services
- **Microphone**: Audio recording permission
- **Notifications**: Push notification permission
- **Contacts**: Contact list access
- **Biometric**: Fingerprint/Face ID access
- **Calendar**: Calendar read/write access
- **Storage**: File storage access

### 4. Integrations 🔗

- **Firebase**: Push notification and analytics integration
- **Chat Bot**: In-app chat functionality
- **Deep Linking**: Domain-based URL handling
- **Code Signing**: App signing status

### 5. Build Artifacts 📦

- **Android APK**: Debug/Release APK file with size
- **Android AAB**: App Bundle for Play Store with size
- **iOS IPA**: Signed iOS app with size
- **iOS Archive**: Xcode archive with size

### 6. Error Details (Failed Builds) ❌

- **Error Message**: Specific error that caused the failure
- **Troubleshooting Steps**: Common solutions and next steps
- **Build Logs Link**: Direct link to Codemagic build logs

## ⚙️ Configuration

### Environment Variables

The email notification system uses the following environment variables:

```yaml
# Email Configuration
ENABLE_EMAIL_NOTIFICATIONS: "true"
EMAIL_SMTP_SERVER: "smtp.gmail.com"
EMAIL_SMTP_PORT: "587"
EMAIL_SMTP_USER: "your-email@gmail.com"
EMAIL_SMTP_PASS: "your-app-password"
EMAIL_ID: "recipient@example.com"

# App Information
APP_NAME: "Your App Name"
PKG_NAME: "com.yourcompany.yourapp"
BUNDLE_ID: "com.yourcompany.yourapp"
VERSION_NAME: "1.0.0"
VERSION_CODE: "1"
WEB_URL: "https://yourapp.com"
USER_NAME: "User Name"
ORG_NAME: "Organization Name"
WORKFLOW_ID: "workflow-name"

# Feature Flags
PUSH_NOTIFY: "true"
IS_CHATBOT: "true"
IS_DOMAIN_URL: "true"
IS_SPLASH: "true"
IS_PULLDOWN: "true"
IS_BOTTOMMENU: "true"
IS_LOAD_IND: "true"

# Permissions
IS_CAMERA: "true"
IS_LOCATION: "true"
IS_MIC: "true"
IS_NOTIFICATION: "true"
IS_CONTACT: "false"
IS_BIOMETRIC: "true"
IS_CALENDAR: "false"
IS_STORAGE: "true"

# Integrations
FIREBASE_CONFIG_ANDROID: "firebase-config-json"
FIREBASE_CONFIG_IOS: "firebase-config-json"
KEY_STORE_URL: "keystore-url"
CERT_PASSWORD: "certificate-password"
```

### SMTP Configuration

The system supports any SMTP server. For Gmail, use these settings:

```yaml
EMAIL_SMTP_SERVER: "smtp.gmail.com"
EMAIL_SMTP_PORT: "587"
EMAIL_SMTP_USER: "your-gmail@gmail.com"
EMAIL_SMTP_PASS: "your-app-password" # Use App Password, not regular password
```

**Note**: For Gmail, you must use an App Password, not your regular password. Enable 2-factor authentication and generate an App Password.

## 🔧 Integration with Build Scripts

### Android Workflow

The Android build script (`lib/scripts/android/main.sh`) automatically sends notifications:

1. **Build Start**: Sent at the beginning of the build process
2. **Build Success**: Sent when APK/AAB is successfully generated
3. **Build Failed**: Sent if any step fails with error details

### iOS Workflow

The iOS build script (`lib/scripts/ios/main.sh`) automatically sends notifications:

1. **Build Start**: Sent at the beginning of the build process
2. **Build Success**: Sent when IPA is successfully generated
3. **Build Failed**: Sent if any step fails with error details

### Combined Workflow

The combined build script (`lib/scripts/combined/main.sh`) sends notifications:

1. **Build Start**: Sent at the beginning of the combined build
2. **Build Success**: Sent when both Android and iOS builds complete
3. **Build Failed**: Sent if either platform fails

## 🧪 Testing

### Test Script

Use the provided test script to verify email functionality:

```bash
# Make the test script executable
chmod +x test_email_notifications.sh

# Run the test
./test_email_notifications.sh
```

This will send three test emails:

- Build Start notification
- Build Success notification
- Build Failed notification

### Manual Testing

You can also test the email system manually:

```bash
# Test build start
bash lib/scripts/utils/email_notifications.sh "start"

# Test build success
bash lib/scripts/utils/email_notifications.sh "success"

# Test build failure
bash lib/scripts/utils/email_notifications.sh "failed" "Test error message"
```

## 📧 Email Templates

### Build Started Email

- **Subject**: 🚀 QuikApp Build Started - [App Name]
- **Content**: App information, customization status, integrations, and permissions
- **Purpose**: Notify that build has begun and show configuration

### Build Success Email

- **Subject**: 🎉 QuikApp Build Successful - [App Name]
- **Content**: All app information plus build artifacts and download links
- **Purpose**: Confirm successful build and provide artifact access

### Build Failed Email

- **Subject**: ❌ QuikApp Build Failed - [App Name]
- **Content**: Error details, troubleshooting steps, and recovery options
- **Purpose**: Alert about failure and provide resolution guidance

## 🔍 Troubleshooting

### Common Issues

1. **Emails not sending**

   - Check `ENABLE_EMAIL_NOTIFICATIONS` is set to "true"
   - Verify SMTP credentials are correct
   - Ensure recipient email is valid

2. **Gmail authentication errors**

   - Use App Password instead of regular password
   - Enable 2-factor authentication
   - Check if "Less secure app access" is enabled (if not using App Password)

3. **Missing information in emails**
   - Verify all environment variables are set
   - Check that build artifacts exist in output directories
   - Ensure feature flags are properly configured

### Debug Mode

To enable debug logging, add this to your build script:

```bash
export EMAIL_DEBUG="true"
```

This will show detailed SMTP communication logs.

## 📱 Mobile Responsiveness

The email templates are fully responsive and optimized for:

- **Desktop**: Full-width layout with side-by-side sections
- **Tablet**: Adaptive grid that adjusts to screen size
- **Mobile**: Stacked layout with touch-friendly buttons

## 🎯 Best Practices

1. **Use App Passwords**: For Gmail, always use App Passwords instead of regular passwords
2. **Test Regularly**: Run the test script before deploying to production
3. **Monitor Delivery**: Check spam folders if emails aren't received
4. **Update Credentials**: Rotate SMTP passwords regularly
5. **Backup Configuration**: Keep email configuration in secure environment variables

## 🔐 Security Considerations

- **SMTP Credentials**: Store passwords in secure environment variables
- **App Passwords**: Use Gmail App Passwords for better security
- **TLS Encryption**: All emails are sent over encrypted connections
- **No Sensitive Data**: Emails don't contain sensitive build information

## 📞 Support

For issues with the email notification system:

1. Check the troubleshooting section above
2. Verify your SMTP configuration
3. Test with the provided test script
4. Review build logs for error messages
5. Contact QuikApp support if issues persist

---

**QuikApp Build System** - Professional mobile app builds with comprehensive notifications
