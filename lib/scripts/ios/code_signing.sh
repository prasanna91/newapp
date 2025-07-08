#!/bin/bash

# 🔐 Enhanced Code Signing Script for iOS
# This script handles iOS code signing with comprehensive validation

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

log_info "🔐 Starting Enhanced iOS Code Signing"

# Set default environment variables if not already set
export CERT_P12_URL="${CERT_P12_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/Certificates.p12}"
export CERT_CER_URL="${CERT_CER_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution.cer}"
export CERT_KEY_URL="${CERT_KEY_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key}"
export CERT_PASSWORD="${CERT_PASSWORD:-password}"
export PROFILE_URL="${PROFILE_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/Twinklub_AppStore.mobileprovision}"
export APPLE_TEAM_ID="${APPLE_TEAM_ID:-9H2AD7NQ49}"
export BUNDLE_ID="${BUNDLE_ID:-com.twinklub.twinklub}"
export PROFILE_TYPE="${PROFILE_TYPE:-app-store}"

# Enhanced certificate import function
import_certificate_to_keychain() {
    local p12_file="$1"
    local password="$2"
    local cert_name="$3"
    
    log_info "🔐 Importing $cert_name into keychain..."
    
    # Try multiple keychain import methods
    local import_methods=(
        "security import '$p12_file' -k login.keychain -P '$password' -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/security"
        "security import '$p12_file' -k /Library/Keychains/System.keychain -P '$password' -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/security"
        "security import '$p12_file' -P '$password' -T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/security"
        "security import '$p12_file' -P '$password'"
    )
    
    # Try to unlock keychains first
    log_info "🔓 Attempting to unlock keychains..."
    security unlock-keychain -p "" login.keychain 2>/dev/null || true
    security unlock-keychain -p "" /Library/Keychains/System.keychain 2>/dev/null || true
    
    # Try each import method
    for i in "${!import_methods[@]}"; do
        local method="${import_methods[$i]}"
        log_info "🔐 Trying import method $((i+1))..."
        
        if eval "$method" >/dev/null 2>&1; then
            log_success "$cert_name imported successfully with method $((i+1))"
            return 0
        else
            log_warning "Import method $((i+1)) failed, trying next..."
        fi
    done
    
    # If all methods fail, try a more aggressive approach
    log_warning "All standard import methods failed, trying aggressive approach..."
    
    # Create a temporary keychain for import
    local temp_keychain="$PROJECT_ROOT/ios/temp.keychain"
    local temp_password="temp123"
    
    if security create-keychain -p "$temp_password" "$temp_keychain" >/dev/null 2>&1; then
        log_info "Created temporary keychain for import..."
        
        if security import "$p12_file" -k "$temp_keychain" -P "$password" >/dev/null 2>&1; then
            log_success "$cert_name imported into temporary keychain"
            
            # Try to merge with system keychain
            if security list-keychains -s "$temp_keychain" >/dev/null 2>&1; then
                log_success "Temporary keychain added to search list"
                return 0
            fi
        fi
        
        # Clean up temporary keychain
        security delete-keychain "$temp_keychain" 2>/dev/null || true
    fi
    
    log_error "Failed to import $cert_name into any keychain"
    return 1
}

# Validate signing variables
validate_signing_vars() {
    log_info "🔍 Validating signing configuration..."
    
    local profile_url="${PROFILE_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/Twinklub_AppStore.mobileprovision}"
    local team_id="${APPLE_TEAM_ID:-9H2AD7NQ49}"
    local bundle_id="${BUNDLE_ID:-com.twinklub.twinklub}"
    
    log_info "📋 Signing Configuration:"
    log_info "   - Profile URL: $profile_url"
    log_info "   - Team ID: $team_id"
    log_info "   - Bundle ID: $bundle_id"
    log_info "   - Profile Type: ${PROFILE_TYPE:-app-store}"
    
    if [ -z "$profile_url" ] || [ -z "$team_id" ] || [ -z "$bundle_id" ]; then
        log_error "Required signing variables missing"
        return 1
    fi
    
    log_success "Required signing variables validated"
    return 0
}

# Setup certificates with fallback logic
setup_certificates() {
    log_info "🔐 Setting up certificates with fallback logic..."
    
    # Method 1: Try CER+KEY certificate first (more reliable)
    log_info "🔐 Prioritizing CER+KEY method for better reliability..."
    if setup_cer_key_certificate; then
        log_success "🎉 CER+KEY certificate setup completed successfully"
        return 0
    else
        # Method 2: Fall back to P12 certificate
        log_warning "CER+KEY setup failed, falling back to P12 method..."
        if setup_p12_certificate; then
            log_success "🎉 P12 certificate setup completed successfully"
            return 0
        else
            log_error "❌ All certificate setup methods failed"
            return 1
        fi
    fi
}

# Setup P12 certificate
setup_p12_certificate() {
    log_info "🔐 Attempting P12 certificate setup..."
    
    local p12_url="${CERT_P12_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/Certificates.p12}"
    local p12_password="${CERT_PASSWORD:-password}"
    
    if [ -z "$p12_url" ]; then
        log_warning "CERT_P12_URL not provided, skipping P12 setup"
        return 1
    fi
    
    log_info "📥 Downloading P12 certificate from: $p12_url"
    
    if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.p12" "$p12_url"; then
        log_success "P12 certificate downloaded successfully"
        
        if openssl pkcs12 -info -in "$PROJECT_ROOT/ios/Runner.p12" -noout -passin pass:"$p12_password" >/dev/null 2>&1; then
            log_success "P12 certificate verified successfully"
            
            # Import P12 into keychain using enhanced method
            if import_certificate_to_keychain "$PROJECT_ROOT/ios/Runner.p12" "$p12_password" "P12 certificate"; then
                return 0
            else
                log_error "P12 certificate import failed"
                rm -f "$PROJECT_ROOT/ios/Runner.p12"
                return 1
            fi
        else
            log_error "P12 certificate verification failed - invalid password or corrupted file"
            rm -f "$PROJECT_ROOT/ios/Runner.p12"
            return 1
        fi
    else
        log_error "Failed to download P12 certificate"
        return 1
    fi
}

# Setup CER+KEY certificate
setup_cer_key_certificate() {
    log_info "🔐 Attempting CER+KEY certificate setup..."
    
    local cer_url="${CERT_CER_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution.cer}"
    local key_url="${CERT_KEY_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/private.key}"
    local p12_password="${CERT_PASSWORD:-password}"
    
    if [ -z "$cer_url" ] || [ -z "$key_url" ]; then
        log_warning "CERT_CER_URL or CERT_KEY_URL not provided, skipping CER+KEY setup"
        return 1
    fi
    
    log_info "📥 Downloading certificate files..."
    log_info "📥 CER file from: $cer_url"
    log_info "📥 KEY file from: $key_url"
    
    if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.cer" "$cer_url" && \
       curl -fsSL -o "$PROJECT_ROOT/ios/Runner.key" "$key_url"; then
        log_success "Certificate files downloaded successfully"
        
        # Verify files
        if openssl x509 -in "$PROJECT_ROOT/ios/Runner.cer" -text -noout >/dev/null 2>&1; then
            log_success "CER file verified successfully"
        else
            log_error "CER file verification failed"
            rm -f "$PROJECT_ROOT/ios/Runner.cer" "$PROJECT_ROOT/ios/Runner.key"
            return 1
        fi
        
        if openssl rsa -in "$PROJECT_ROOT/ios/Runner.key" -check -noout >/dev/null 2>&1; then
            log_success "KEY file verified successfully"
        else
            log_error "KEY file verification failed"
            rm -f "$PROJECT_ROOT/ios/Runner.cer" "$PROJECT_ROOT/ios/Runner.key"
            return 1
        fi
        
        # Convert to P12
        log_info "🔄 Converting CER+KEY to P12 format..."
        if openssl pkcs12 -export \
            -in "$PROJECT_ROOT/ios/Runner.cer" \
            -inkey "$PROJECT_ROOT/ios/Runner.key" \
            -out "$PROJECT_ROOT/ios/Runner.p12" \
            -passout pass:"$p12_password"; then
            log_success "Certificate converted to P12 successfully"
            
            # Import P12 into keychain using enhanced method
            if import_certificate_to_keychain "$PROJECT_ROOT/ios/Runner.p12" "$p12_password" "Generated P12 certificate"; then
                rm -f "$PROJECT_ROOT/ios/Runner.cer" "$PROJECT_ROOT/ios/Runner.key"
                return 0
            else
                log_error "Generated P12 certificate import failed"
                rm -f "$PROJECT_ROOT/ios/Runner.cer" "$PROJECT_ROOT/ios/Runner.key"
                return 1
            fi
        else
            log_error "Failed to convert certificate to P12 format"
            rm -f "$PROJECT_ROOT/ios/Runner.cer" "$PROJECT_ROOT/ios/Runner.key"
            return 1
        fi
    else
        log_error "Failed to download certificate files"
        return 1
    fi
}

# Setup provisioning profile
setup_provisioning_profile() {
    log_info "📱 Setting up provisioning profile..."
    
    local profile_url="${PROFILE_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/Twinklub_AppStore.mobileprovision}"
    
    log_info "📥 Downloading provisioning profile from: $profile_url"
    
    if curl -fsSL -o "$PROJECT_ROOT/ios/Runner.mobileprovision" "$profile_url"; then
        log_success "Provisioning profile downloaded successfully"
        
        if security cms -D -i "$PROJECT_ROOT/ios/Runner.mobileprovision" >/dev/null 2>&1; then
            log_success "Provisioning profile verified successfully"
            
            local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
            if [ ! -d "$profiles_dir" ]; then
                log_info "📁 Creating provisioning profiles directory..."
                mkdir -p "$profiles_dir"
            fi
            
            log_info "📱 Installing provisioning profile..."
            if cp "$PROJECT_ROOT/ios/Runner.mobileprovision" "$profiles_dir/"; then
                log_success "Provisioning profile installed successfully"
                return 0
            else
                log_error "Failed to install provisioning profile"
                return 1
            fi
        else
            log_error "Provisioning profile verification failed"
            rm -f "$PROJECT_ROOT/ios/Runner.mobileprovision"
            return 1
        fi
    else
        log_error "Failed to download provisioning profile"
        return 1
    fi
}

# Enhanced certificate verification
verify_certificates() {
    log_info "🔍 Verifying certificates in keychain..."
    
    log_info "📋 Available code signing identities:"
    local cert_output=$(security find-identity -v -p codesigning 2>/dev/null || echo "")
    
    if [ -n "$cert_output" ]; then
        echo "$cert_output"
        log_success "Certificates found in keychain"
        
        local valid_count=$(echo "$cert_output" | grep -c "valid identities found" || echo "0")
        if [ "$valid_count" -gt 0 ]; then
            log_success "Valid code signing identities found"
            
            # List the actual identities
            log_info "📋 Valid code signing identities:"
            security find-identity -v -p codesigning | grep -E "^[[:space:]]*[0-9]+:" || true
            
            return 0
        else
            log_warning "Certificates found but no valid identities for code signing"
            
            # Try to list all identities for debugging
            log_info "📋 All identities in keychain:"
            security find-identity -v -p codesigning || true
            
            return 1
        fi
    else
        log_error "No certificates found in keychain"
        
        # Try to list all keychains for debugging
        log_info "📋 Available keychains:"
        security list-keychains || true
        
        return 1
    fi
}

# Main execution
main() {
    log_info "🔐 Starting enhanced iOS code signing for $APP_NAME"
    
    # Validate required variables
    if ! validate_signing_vars; then
        log_error "Signing validation failed"
        exit 1
    fi
    
    # Setup provisioning profile first
    if ! setup_provisioning_profile; then
        log_error "Provisioning profile setup failed"
        exit 1
    fi
    
    # Setup certificates
    if ! setup_certificates; then
        log_error "Certificate setup failed"
        exit 1
    fi
    
    # Verify certificates
    if ! verify_certificates; then
        log_error "Certificate verification failed"
        exit 1
    fi
    
    log_success "✅ All signing components verified successfully"
    return 0
}

# Run main function
main "$@" 