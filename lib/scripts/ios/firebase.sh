#!/bin/bash

# 🔥 iOS Firebase Setup Script for QuikApp
# This script handles Firebase configuration for iOS

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

log_info "🔥 Starting iOS Firebase Configuration"

# Setup Firebase configuration
setup_firebase() {
    log_info "🔥 Setting up Firebase configuration..."
    
    # Check if Firebase is enabled
    if [ "${PUSH_NOTIFY:-false}" != "true" ]; then
        log_info "🔕 Push notifications disabled, skipping Firebase setup"
        return 0
    fi
    
    # Check if Firebase config URL is provided
    if [ -z "${FIREBASE_CONFIG_IOS:-}" ]; then
        log_warning "FIREBASE_CONFIG_IOS not provided, skipping Firebase setup"
        return 0
    fi
    
    log_info "📥 Downloading Firebase configuration from: $FIREBASE_CONFIG_IOS"
    
    # Create iOS directory if it doesn't exist
    local ios_dir="$PROJECT_ROOT/ios/Runner"
    mkdir -p "$ios_dir"
    
    # Download GoogleService-Info.plist
    if curl -fsSL -o "$ios_dir/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS"; then
        log_success "Firebase configuration downloaded successfully"
        
        # Verify the file is a valid plist
        if plutil -lint "$ios_dir/GoogleService-Info.plist" >/dev/null 2>&1; then
            log_success "Firebase configuration verified successfully"
            
            # Extract and display Firebase project info
            local project_id=$(plutil -extract GOOGLE_APP_ID raw "$ios_dir/GoogleService-Info.plist" 2>/dev/null || echo "Unknown")
            local bundle_id=$(plutil -extract BUNDLE_ID raw "$ios_dir/GoogleService-Info.plist" 2>/dev/null || echo "Unknown")
            
            log_info "📋 Firebase Project Information:"
            log_info "   - Project ID: $project_id"
            log_info "   - Bundle ID: $bundle_id"
            
            return 0
        else
            log_error "Firebase configuration file is not a valid plist"
            rm -f "$ios_dir/GoogleService-Info.plist"
            return 1
        fi
    else
        log_error "Failed to download Firebase configuration"
        return 1
    fi
}

# Verify Firebase dependencies in pubspec.yaml
verify_firebase_dependencies() {
    log_info "📦 Verifying Firebase dependencies..."
    
    local pubspec_file="$PROJECT_ROOT/pubspec.yaml"
    
    if [ ! -f "$pubspec_file" ]; then
        log_error "pubspec.yaml not found"
        return 1
    fi
    
    # Check for Firebase dependencies
    local has_firebase_core=false
    local has_firebase_messaging=false
    
    if grep -q "firebase_core:" "$pubspec_file"; then
        has_firebase_core=true
        log_info "✅ firebase_core dependency found"
    else
        log_warning "firebase_core dependency not found"
    fi
    
    if grep -q "firebase_messaging:" "$pubspec_file"; then
        has_firebase_messaging=true
        log_info "✅ firebase_messaging dependency found"
    else
        log_warning "firebase_messaging dependency not found"
    fi
    
    if [ "$has_firebase_core" = true ] && [ "$has_firebase_messaging" = true ]; then
        log_success "All required Firebase dependencies found"
        return 0
    else
        log_warning "Some Firebase dependencies are missing"
        return 1
    fi
}

# Setup iOS deployment target for Firebase
setup_ios_deployment_target() {
    log_info "📱 Setting up iOS deployment target for Firebase..."
    
    # Firebase requires iOS 14.0+
    local target_version="14.0"
    
    # Update Podfile
    local podfile="$PROJECT_ROOT/ios/Podfile"
    if [ -f "$podfile" ]; then
        log_info "📝 Updating Podfile deployment target..."
        
        # Backup original Podfile
        cp "$podfile" "$podfile.backup"
        
        # Update platform version
        sed -i '' "s/platform :ios, '.*'/platform :ios, '$target_version'/g" "$podfile"
        
        log_success "Podfile updated with iOS $target_version deployment target"
    else
        log_warning "Podfile not found"
    fi
    
    # Update Xcode project
    local project_file="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"
    if [ -f "$project_file" ]; then
        log_info "📝 Updating Xcode project deployment target..."
        
        # Backup original project file
        cp "$project_file" "$project_file.backup"
        
        # Update IPHONEOS_DEPLOYMENT_TARGET
        sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = $target_version;/g" "$project_file"
        
        log_success "Xcode project updated with iOS $target_version deployment target"
    else
        log_warning "Xcode project file not found"
    fi
}

# Main execution
main() {
    log_info "🔥 Starting iOS Firebase setup for $APP_NAME"
    
    # Setup iOS deployment target first
    setup_ios_deployment_target
    
    # Verify Firebase dependencies
    if ! verify_firebase_dependencies; then
        log_warning "Firebase dependencies verification failed"
    fi
    
    # Setup Firebase configuration
    if setup_firebase; then
        log_success "✅ Firebase setup completed successfully"
    else
        log_warning "⚠️ Firebase setup failed, continuing without Firebase"
    fi
    
    return 0
}

# Run main function
main "$@" 