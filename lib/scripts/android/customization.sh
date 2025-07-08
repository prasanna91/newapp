#!/bin/bash

# 🎨 Android Customization Script for QuikApp
# This script customizes the Android app with package name, app name, and icon

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

log_info "🎨 Starting Android Customization"

# Update package name in build.gradle
update_package_name() {
    log_info "📝 Updating package name to: $PKG_NAME"
    
    local build_gradle_file="$PROJECT_ROOT/android/app/build.gradle"
    
    if [ -f "$build_gradle_file" ]; then
        # Backup original file
        cp "$build_gradle_file" "$build_gradle_file.backup"
        
        # Update applicationId
        sed -i.bak "s/applicationId \".*\"/applicationId \"$PKG_NAME\"/" "$build_gradle_file"
        
        log_success "Package name updated in build.gradle"
    else
        log_error "build.gradle file not found!"
        exit 1
    fi
}

# Update app name in AndroidManifest.xml
update_app_name() {
    log_info "📝 Updating app name to: $APP_NAME"
    
    local manifest_file="$PROJECT_ROOT/android/app/src/main/AndroidManifest.xml"
    
    if [ -f "$manifest_file" ]; then
        # Backup original file
        cp "$manifest_file" "$manifest_file.backup"
        
        # Update android:label
        sed -i.bak "s/android:label=\".*\"/android:label=\"$APP_NAME\"/" "$manifest_file"
        
        log_success "App name updated in AndroidManifest.xml"
    else
        log_error "AndroidManifest.xml file not found!"
        exit 1
    fi
}

# Update app icon
update_app_icon() {
    log_info "🎨 Updating app icon..."
    
    local icon_path="${APP_ICON_PATH:-assets/images/logo.png}"
    local source_icon="$PROJECT_ROOT/$icon_path"
    
    if [ -f "$source_icon" ]; then
        # Create mipmap directories if they don't exist
        mkdir -p "$PROJECT_ROOT/android/app/src/main/res/mipmap-mdpi"
        mkdir -p "$PROJECT_ROOT/android/app/src/main/res/mipmap-hdpi"
        mkdir -p "$PROJECT_ROOT/android/app/src/main/res/mipmap-xhdpi"
        mkdir -p "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxhdpi"
        mkdir -p "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxxhdpi"
        
        # Copy icon to all mipmap directories
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
        
        # Also copy as ic_launcher_round for round icons
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png"
        cp "$source_icon" "$PROJECT_ROOT/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png"
        
        log_success "App icon updated"
    else
        log_warning "App icon not found at: $source_icon"
        log_info "Using default Flutter icon"
    fi
}

# Update version information
update_version() {
    log_info "📝 Updating version information..."
    
    local build_gradle_file="$PROJECT_ROOT/android/app/build.gradle"
    
    if [ -f "$build_gradle_file" ]; then
        # Update versionName
        sed -i.bak "s/versionName \".*\"/versionName \"$VERSION_NAME\"/" "$build_gradle_file"
        
        # Update versionCode
        sed -i.bak "s/versionCode .*/versionCode $VERSION_CODE/" "$build_gradle_file"
        
        log_success "Version information updated"
    else
        log_error "build.gradle file not found!"
        exit 1
    fi
}

# Main execution
main() {
    log_info "🎨 Starting Android customization for $APP_NAME"
    
    # Validate required variables
    if [ -z "$PKG_NAME" ]; then
        log_error "PKG_NAME is required!"
        exit 1
    fi
    
    if [ -z "$APP_NAME" ]; then
        log_error "APP_NAME is required!"
        exit 1
    fi
    
    # Run customization steps
    update_package_name
    update_app_name
    update_app_icon
    update_version
    
    log_success "🎉 Android customization completed successfully!"
}

# Run main function
main "$@" 