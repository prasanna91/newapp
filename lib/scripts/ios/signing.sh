#!/bin/bash

# 🔐 iOS Signing Script for QuikApp
# This script handles iOS code signing setup

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

log_info "🔐 Starting iOS Signing Configuration"

# Configure signing
configure_signing() {
    if [ -n "$CERT_PASSWORD" ] && [ -n "$PROFILE_URL" ]; then
        log_info "🔐 Configuring iOS signing..."
        
        # Download provisioning profile
        if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.mobileprovision" "$PROFILE_URL"; then
            log_success "Provisioning profile downloaded"
        else
            log_error "Failed to download provisioning profile"
            exit 1
        fi
        
        # Handle certificate
        if [ -n "$CERT_P12_URL" ]; then
            # Download P12 certificate
            if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.p12" "$CERT_P12_URL"; then
                log_success "P12 certificate downloaded"
            else
                log_error "Failed to download P12 certificate"
                exit 1
            fi
        elif [ -n "$CERT_CER_URL" ] && [ -n "$CERT_KEY_URL" ]; then
            # Download CER and KEY files and convert to P12
            if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.cer" "$CERT_CER_URL" && \
               curl -fsSL -o "$PROJECT_ROOT/ios/Runner.key" "$CERT_KEY_URL"; then
                log_success "Certificate files downloaded"
                
                # Convert to P12
                openssl pkcs12 -export \
                    -in "$PROJECT_ROOT/ios/Runner.cer" \
                    -inkey "$PROJECT_ROOT/ios/Runner.key" \
                    -out "$PROJECT_ROOT/ios/Runner.p12" \
                    -passout pass:"$CERT_PASSWORD"
                log_success "Certificate converted to P12"
            else
                log_error "Failed to download certificate files"
                exit 1
            fi
        else
            log_error "No certificate configuration provided"
            exit 1
        fi
    else
        log_info "Signing not configured, using development signing"
    fi
}

# Main execution
main() {
    log_info "🔐 Starting iOS signing configuration for $APP_NAME"
    
    # Configure signing
    configure_signing
    
    log_success "🎉 iOS signing configuration completed successfully!"
}

# Run main function
main "$@" 