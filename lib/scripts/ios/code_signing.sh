#!/bin/bash

# 🔐 iOS Code Signing Script for QuikApp
# This script handles iOS code signing setup and management

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

log_info "🔐 Starting iOS Code Signing Configuration"

# Validate signing requirements
validate_signing_requirements() {
    log_info "🔍 Validating signing requirements..."
    
    local has_certificate=false
    local has_profile=false
    
    # Check for certificate
    if [ -n "${CERT_P12_URL:-}" ] || ([ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]); then
        has_certificate=true
        log_info "Certificate configuration found"
    fi
    
    # Check for provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        has_profile=true
        log_info "Provisioning profile configuration found"
    fi
    
    # Check for password
    if [ -n "${CERT_PASSWORD:-}" ]; then
        log_info "Certificate password provided"
    else
        log_warning "No certificate password provided"
    fi
    
    # Check for team ID
    if [ -n "${APPLE_TEAM_ID:-}" ]; then
        log_info "Apple Team ID provided: $APPLE_TEAM_ID"
    else
        log_warning "No Apple Team ID provided"
    fi
    
    if [ "$has_certificate" = true ] && [ "$has_profile" = true ]; then
        log_success "All signing requirements met"
        return 0
    else
        log_warning "Incomplete signing configuration - will use development signing"
        return 1
    fi
}

# Download and setup certificate
setup_certificate() {
    log_info "🔐 Setting up certificate..."
    
    local cert_dir="$PROJECT_ROOT/ios"
    mkdir -p "$cert_dir"
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        # Download P12 certificate
        log_info "📥 Downloading P12 certificate..."
        if curl -fsSL -o "$cert_dir/Runner.p12" "$CERT_P12_URL"; then
            log_success "P12 certificate downloaded"
        else
            log_error "Failed to download P12 certificate"
            return 1
        fi
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        # Download CER and KEY files and convert to P12
        log_info "📥 Downloading certificate files..."
        
        if curl -fsSL -o "$cert_dir/Runner.cer" "$CERT_CER_URL" && \
           curl -fsSL -o "$cert_dir/Runner.key" "$CERT_KEY_URL"; then
            log_success "Certificate files downloaded"
            
            # Convert to P12
            log_info "🔄 Converting certificate to P12..."
            if [ -n "${CERT_PASSWORD:-}" ]; then
                openssl pkcs12 -export \
                    -in "$cert_dir/Runner.cer" \
                    -inkey "$cert_dir/Runner.key" \
                    -out "$cert_dir/Runner.p12" \
                    -passout pass:"$CERT_PASSWORD"
                log_success "Certificate converted to P12"
            else
                log_error "Certificate password required for conversion"
                return 1
            fi
        else
            log_error "Failed to download certificate files"
            return 1
        fi
    else
        log_warning "No certificate configuration provided"
        return 1
    fi
    
    return 0
}

# Download and setup provisioning profile
setup_provisioning_profile() {
    log_info "📋 Setting up provisioning profile..."
    
    if [ -n "${PROFILE_URL:-}" ]; then
        local profile_dir="$PROJECT_ROOT/ios"
        mkdir -p "$profile_dir"
        
        # Download provisioning profile
        log_info "📥 Downloading provisioning profile..."
        if curl -fsSL -o "$profile_dir/Runner.mobileprovision" "$PROFILE_URL"; then
            log_success "Provisioning profile downloaded"
            
            # Extract and display profile info
            if command -v security &> /dev/null; then
                log_info "📋 Provisioning profile information:"
                security cms -D -i "$profile_dir/Runner.mobileprovision" 2>/dev/null | \
                    plutil -extract Entitlements xml1 -o - - 2>/dev/null | \
                    grep -E "(application-identifier|team-identifier|get-task-allow)" || true
            fi
        else
            log_error "Failed to download provisioning profile"
            return 1
        fi
    else
        log_warning "No provisioning profile URL provided"
        return 1
    fi
    
    return 0
}

# Setup keychain
setup_keychain() {
    log_info "🔑 Setting up keychain..."
    
    # Create temporary keychain
    local keychain_name="quikapp_temp.keychain"
    local keychain_password="temp_password_123"
    
    # Create keychain
    security create-keychain -p "$keychain_password" "$keychain_name"
    security default-keychain -s "$keychain_name"
    security unlock-keychain -p "$keychain_password" "$keychain_name"
    security set-keychain-settings -t 3600 -u "$keychain_name"
    
    # Import certificate if available
    if [ -f "$PROJECT_ROOT/ios/Runner.p12" ] && [ -n "${CERT_PASSWORD:-}" ]; then
        log_info "📥 Importing certificate to keychain..."
        security import "$PROJECT_ROOT/ios/Runner.p12" -k "$keychain_name" -P "$CERT_PASSWORD" -T /usr/bin/codesign
        log_success "Certificate imported to keychain"
    fi
    
    # Set keychain search list
    security list-keychains -s "$keychain_name"
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain_name"
    
    log_success "Keychain setup completed"
}

# Configure Xcode project for signing
configure_xcode_signing() {
    log_info "⚙️ Configuring Xcode project for signing..."
    
    cd "$PROJECT_ROOT"
    
    # Update project.pbxproj with signing configuration
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_info "📝 Updating Xcode project signing configuration..."
        
        # Backup original file
        cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup
        
        # Update signing settings
        if [ -n "${APPLE_TEAM_ID:-}" ]; then
            # Set development team
            sed -i '' "s/DEVELOPMENT_TEAM = \"\";/DEVELOPMENT_TEAM = \"$APPLE_TEAM_ID\";/g" ios/Runner.xcodeproj/project.pbxproj
            
            # Set code signing identity
            sed -i '' "s/CODE_SIGN_IDENTITY = \"\";/CODE_SIGN_IDENTITY = \"iPhone Developer\";/g" ios/Runner.xcodeproj/project.pbxproj
            sed -i '' "s/CODE_SIGN_IDENTITY\[sdk=iphoneos\*\] = \"\";/CODE_SIGN_IDENTITY[sdk=iphoneos*] = \"iPhone Developer\";/g" ios/Runner.xcodeproj/project.pbxproj
            
            # Enable code signing
            sed -i '' "s/CODE_SIGNING_REQUIRED = \"\";/CODE_SIGNING_REQUIRED = \"YES\";/g" ios/Runner.xcodeproj/project.pbxproj
            sed -i '' "s/CODE_SIGNING_ALLOWED = \"\";/CODE_SIGNING_ALLOWED = \"YES\";/g" ios/Runner.xcodeproj/project.pbxproj
            
            log_success "Xcode project signing configuration updated"
        else
            log_warning "No Apple Team ID provided, using default signing"
        fi
    else
        log_warning "Xcode project file not found"
    fi
}

# Main execution
main() {
    log_info "🔐 Starting iOS code signing configuration for $APP_NAME"
    
    # Validate requirements
    if validate_signing_requirements; then
        # Setup certificate
        if setup_certificate; then
            log_success "Certificate setup completed"
        else
            log_warning "Certificate setup failed, will use development signing"
        fi
        
        # Setup provisioning profile
        if setup_provisioning_profile; then
            log_success "Provisioning profile setup completed"
        else
            log_warning "Provisioning profile setup failed, will use development signing"
        fi
        
        # Setup keychain
        setup_keychain
        
        # Configure Xcode project
        configure_xcode_signing
    else
        log_info "Using development signing (no production certificates)"
    fi
    
    log_success "🎉 iOS code signing configuration completed!"
}

# Run main function
main "$@" 