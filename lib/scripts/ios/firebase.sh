#!/bin/bash

# 🔥 iOS Firebase Script for QuikApp
# This script configures Firebase for iOS

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

# Configure Firebase
configure_firebase() {
    log_info "🔥 Checking Firebase configuration..."
    
    # Check if push notifications are enabled
    if [ "${PUSH_NOTIFY:-false}" != "true" ]; then
        log_info "Push notifications disabled (PUSH_NOTIFY=false), skipping Firebase setup"
        return 0
    fi
    
    # Check if Firebase config is provided
    if [ -z "$FIREBASE_CONFIG_IOS" ]; then
        log_error "PUSH_NOTIFY is true but FIREBASE_CONFIG_IOS is not provided"
        log_error "Please provide FIREBASE_CONFIG_IOS environment variable"
        exit 1
    fi
    
    log_info "🔥 Configuring Firebase for iOS..."
    
    # Create Runner directory if it doesn't exist
    mkdir -p "$PROJECT_ROOT/ios/Runner"
    
    # Download Firebase config
    if curl -fsSL -o "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS"; then
        log_success "Firebase configuration downloaded successfully"
        
        # Validate the downloaded file
        if [ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]; then
            local file_size=$(du -h "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" | cut -f1)
            log_success "GoogleService-Info.plist created (${file_size})"
        else
            log_error "Firebase config file was not created"
            exit 1
        fi
    else
        log_error "Failed to download Firebase configuration from: $FIREBASE_CONFIG_IOS"
        log_error "Please check the URL and ensure it's accessible"
        exit 1
    fi
}

# Main execution
main() {
    log_info "🔥 Starting iOS Firebase configuration for $APP_NAME"
    
    # Configure Firebase
    configure_firebase
    
    log_success "🎉 iOS Firebase configuration completed successfully!"
}

# Run main function
main "$@" 