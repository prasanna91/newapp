#!/bin/bash

# 🔐 Android Permissions Script for QuikApp
# This script configures Android permissions based on feature flags

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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

log_info "🔐 Starting Android Permissions Configuration"

# Configure permissions based on feature flags
configure_permissions() {
    log_info "🔧 Configuring Android permissions..."
    
    local manifest_file="$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml"
    
    if [ ! -f "$manifest_file" ]; then
        log_error "AndroidManifest.xml not found!"
        exit 1
    fi
    
    # Backup original file
    cp "$manifest_file" "$manifest_file.backup"
    
    # Add permissions based on feature flags
    local permissions_to_add=""
    
    # Camera permission
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.CAMERA\" />
    <uses-feature android:name=\"android.hardware.camera\" android:required=\"false\" />
    <uses-feature android:name=\"android.hardware.camera.autofocus\" android:required=\"false\" />"
        log_info "📷 Camera permissions added"
    fi
    
    # Location permissions
    if [ "${IS_LOCATION:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />
    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\" />
    <uses-permission android:name=\"android.permission.ACCESS_BACKGROUND_LOCATION\" />"
        log_info "📍 Location permissions added"
    fi
    
    # Microphone permission
    if [ "${IS_MIC:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.RECORD_AUDIO\" />
    <uses-feature android:name=\"android.hardware.microphone\" android:required=\"false\" />"
        log_info "🎤 Microphone permissions added"
    fi
    
    # Notification permission
    if [ "${IS_NOTIFICATION:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\" />
    <uses-permission android:name=\"android.permission.WAKE_LOCK\" />
    <uses-permission android:name=\"android.permission.VIBRATE\" />"
        log_info "🔔 Notification permissions added"
    fi
    
    # Contact permissions
    if [ "${IS_CONTACT:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.READ_CONTACTS\" />
    <uses-permission android:name=\"android.permission.WRITE_CONTACTS\" />
    <uses-permission android:name=\"android.permission.GET_ACCOUNTS\" />"
        log_info "👥 Contact permissions added"
    fi
    
    # Biometric permission
    if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.USE_BIOMETRIC\" />
    <uses-permission android:name=\"android.permission.USE_FINGERPRINT\" />"
        log_info "🔐 Biometric permissions added"
    fi
    
    # Calendar permissions
    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.READ_CALENDAR\" />
    <uses-permission android:name=\"android.permission.WRITE_CALENDAR\" />"
        log_info "📅 Calendar permissions added"
    fi
    
    # Storage permissions
    if [ "${IS_STORAGE:-false}" = "true" ]; then
        permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.READ_EXTERNAL_STORAGE\" />
    <uses-permission android:name=\"android.permission.WRITE_EXTERNAL_STORAGE\" />
    <uses-permission android:name=\"android.permission.READ_MEDIA_IMAGES\" />
    <uses-permission android:name=\"android.permission.READ_MEDIA_VIDEO\" />
    <uses-permission android:name=\"android.permission.READ_MEDIA_AUDIO\" />"
        log_info "💾 Storage permissions added"
    fi
    
    # Always add internet permission (required for Flutter apps)
    permissions_to_add="$permissions_to_add
    <uses-permission android:name=\"android.permission.INTERNET\" />"
    log_info "🌐 Internet permission added"
    
    # Insert permissions before the application tag
    if [ -n "$permissions_to_add" ]; then
        # Find the line with <application and insert permissions before it
        sed -i.bak "/<application/i\\$permissions_to_add" "$manifest_file"
        log_success "Permissions configured successfully"
    else
        log_warning "No permissions to add"
    fi
}

# Main execution
main() {
    log_info "🔐 Starting Android permissions configuration for $APP_NAME"
    
    # Configure permissions
    configure_permissions
    
    log_success "🎉 Android permissions configuration completed successfully!"
}

# Run main function
main "$@" 