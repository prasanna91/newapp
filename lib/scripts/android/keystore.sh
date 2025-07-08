#!/bin/bash

# 🔐 Android Keystore Script for QuikApp
# This script handles Android code signing setup

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

log_info "🔐 Starting Android Keystore Configuration"

# Configure keystore
configure_keystore() {
    if [ -n "$KEY_STORE_URL" ] && [ -n "$CM_KEYSTORE_PASSWORD" ] && [ -n "$CM_KEY_ALIAS" ] && [ -n "$CM_KEY_PASSWORD" ]; then
        log_info "🔐 Configuring Android keystore..."
        
        # Download keystore
        if curl -fsSL -o "$PROJECT_ROOT/android/app/upload-keystore.jks" "$KEY_STORE_URL"; then
            log_success "Keystore downloaded"
            
            # Create key.properties
            cat > "$PROJECT_ROOT/android/key.properties" << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=upload-keystore.jks
EOF
            log_success "Key properties created"
        else
            log_error "Failed to download keystore"
            exit 1
        fi
    else
        log_info "Keystore not configured, using debug signing"
    fi
}

# Main execution
main() {
    log_info "🔐 Starting Android keystore configuration for $APP_NAME"
    
    # Configure keystore
    configure_keystore
    
    log_success "🎉 Android keystore configuration completed successfully!"
}

# Run main function
main "$@" 