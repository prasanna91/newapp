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
    if [ "${PUSH_NOTIFY:-false}" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
        log_info "🔥 Configuring Firebase for iOS..."
        
        # Download Firebase config
        if curl -fsSL -o "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS"; then
            log_success "Firebase configuration downloaded"
        else
            log_error "Failed to download Firebase configuration"
            exit 1
        fi
    else
        log_info "Firebase not enabled or configuration not provided"
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