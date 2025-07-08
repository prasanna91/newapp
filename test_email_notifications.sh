#!/bin/bash

# 🧪 Test Email Notification System
# This script tests the email notification system with sample data

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMAIL_SCRIPT="$SCRIPT_DIR/lib/scripts/utils/email_notifications.sh"

log_info "🧪 Testing Email Notification System"

# Check if email script exists
if [ ! -f "$EMAIL_SCRIPT" ]; then
    log_error "Email notification script not found: $EMAIL_SCRIPT"
    exit 1
fi

# Set test environment variables
export ENABLE_EMAIL_NOTIFICATIONS="true"
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="prasannasrie@gmail.com"
export EMAIL_SMTP_PASS="lrnu krfm aarp urux"
export EMAIL_ID="prasannasrie@gmail.com"

# Set test app variables
export APP_NAME="Test QuikApp"
export PKG_NAME="com.test.quikapp"
export BUNDLE_ID="com.test.quikapp"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"
export WEB_URL="https://test.quikapp.co"
export USER_NAME="Test User"
export ORG_NAME="Test Organization"
export WORKFLOW_ID="test-workflow"

# Set test feature flags
export PUSH_NOTIFY="true"
export IS_CHATBOT="true"
export IS_DOMAIN_URL="true"
export IS_SPLASH="true"
export IS_PULLDOWN="true"
export IS_BOTTOMMENU="true"
export IS_LOAD_IND="true"

# Set test permissions
export IS_CAMERA="true"
export IS_LOCATION="true"
export IS_MIC="true"
export IS_NOTIFICATION="true"
export IS_CONTACT="false"
export IS_BIOMETRIC="true"
export IS_CALENDAR="false"
export IS_STORAGE="true"

# Set test integrations
export FIREBASE_CONFIG_ANDROID="test-firebase-config-android"
export FIREBASE_CONFIG_IOS="test-firebase-config-ios"
export KEY_STORE_URL="test-keystore-url"
export CERT_PASSWORD="test-cert-password"

# Create test output directory and artifacts
mkdir -p "$SCRIPT_DIR/output/android"
mkdir -p "$SCRIPT_DIR/output/ios"

# Create dummy artifacts for testing
echo "Test APK content" > "$SCRIPT_DIR/output/android/app-release.apk"
echo "Test AAB content" > "$SCRIPT_DIR/output/android/app-release.aab"
echo "Test IPA content" > "$SCRIPT_DIR/output/ios/Runner.ipa"

log_info "📧 Testing Build Start Notification..."
bash "$EMAIL_SCRIPT" "start"

log_info "📧 Testing Build Success Notification..."
bash "$EMAIL_SCRIPT" "success"

log_info "📧 Testing Build Failed Notification..."
bash "$EMAIL_SCRIPT" "failed" "Test error message: Build failed due to compilation errors"

log_success "🧪 Email notification tests completed!"
log_info "📧 Check your email for test notifications" 