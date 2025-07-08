#!/bin/bash

# 🍎 iOS App Store Connect Validation Script for QuikApp
# This script validates all required variables for App Store Connect publishing

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

log_info "🍎 Validating iOS App Store Connect Configuration"

# Validate basic app information
validate_app_info() {
    log_info "📱 Validating app information..."
    
    local required_vars=(
        "APP_NAME"
        "BUNDLE_ID"
        "VERSION_NAME"
        "VERSION_CODE"
        "WEB_URL"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required app variable $var is not set!"
            return 1
        else
            log_success "$var: ${!var}"
        fi
    done
    
    return 0
}

# Validate profile type
validate_profile_type() {
    log_info "📋 Validating profile type..."
    
    if [ -z "$PROFILE_TYPE" ]; then
        log_error "PROFILE_TYPE is not set!"
        return 1
    fi
    
    case "$PROFILE_TYPE" in
        "app-store")
            log_success "Profile type: $PROFILE_TYPE (App Store Connect)"
            ;;
        "ad-hoc"|"enterprise"|"development")
            log_warning "Profile type: $PROFILE_TYPE (Not for App Store Connect)"
            ;;
        *)
            log_error "Invalid PROFILE_TYPE: $PROFILE_TYPE"
            log_error "Supported types: app-store, ad-hoc, enterprise, development"
            return 1
            ;;
    esac
    
    return 0
}

# Validate code signing configuration
validate_code_signing() {
    log_info "🔐 Validating code signing configuration..."
    
    local has_certificate=false
    local has_profile=false
    local has_password=false
    local has_team_id=false
    
    # Check certificate
    if [ -n "${CERT_P12_URL:-}" ]; then
        log_success "P12 certificate URL provided"
        has_certificate=true
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        log_success "CER and KEY certificate URLs provided"
        has_certificate=true
    else
        log_warning "No certificate configuration found"
    fi
    
    # Check provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        log_success "Provisioning profile URL provided"
        has_profile=true
    else
        log_warning "No provisioning profile URL provided"
    fi
    
    # Check certificate password
    if [ -n "${CERT_PASSWORD:-}" ]; then
        log_success "Certificate password provided"
        has_password=true
    else
        log_warning "No certificate password provided"
    fi
    
    # Check team ID
    if [ -n "${APPLE_TEAM_ID:-}" ]; then
        log_success "Apple Team ID: $APPLE_TEAM_ID"
        has_team_id=true
    else
        log_warning "No Apple Team ID provided"
    fi
    
    # Summary
    if [ "$has_certificate" = true ] && [ "$has_profile" = true ] && [ "$has_password" = true ] && [ "$has_team_id" = true ]; then
        log_success "Complete code signing configuration found"
        return 0
    else
        log_warning "Incomplete code signing configuration"
        return 1
    fi
}

# Validate App Store Connect API configuration
validate_appstore_connect() {
    log_info "🍎 Validating App Store Connect API configuration..."
    
    local has_key_id=false
    local has_api_key=false
    local has_issuer_id=false
    
    # Check App Store Connect Key ID
    if [ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]; then
        log_success "App Store Connect Key ID: $APP_STORE_CONNECT_KEY_IDENTIFIER"
        has_key_id=true
    else
        log_warning "No App Store Connect Key ID provided"
    fi
    
    # Check App Store Connect API Key Path
    if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
        log_success "App Store Connect API Key Path: $APP_STORE_CONNECT_API_KEY_PATH"
        has_api_key=true
    else
        log_warning "No App Store Connect API Key Path provided"
    fi
    
    # Check App Store Connect Issuer ID
    if [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        log_success "App Store Connect Issuer ID: $APP_STORE_CONNECT_ISSUER_ID"
        has_issuer_id=true
    else
        log_warning "No App Store Connect Issuer ID provided"
    fi
    
    # Summary
    if [ "$has_key_id" = true ] && [ "$has_api_key" = true ] && [ "$has_issuer_id" = true ]; then
        log_success "Complete App Store Connect API configuration found"
        return 0
    else
        log_warning "Incomplete App Store Connect API configuration"
        return 1
    fi
}

# Validate Firebase configuration (if push notifications enabled)
validate_firebase() {
    log_info "🔥 Validating Firebase configuration..."
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "Push notifications enabled - Firebase required"
        
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            log_success "Firebase configuration provided"
            return 0
        else
            log_error "Firebase configuration required when PUSH_NOTIFY is true"
            return 1
        fi
    else
        log_info "Push notifications disabled - Firebase optional"
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            log_success "Firebase configuration provided (optional)"
        else
            log_warning "No Firebase configuration provided"
        fi
        return 0
    fi
}

# Validate build environment
validate_build_environment() {
    log_info "🏗️ Validating build environment..."
    
    # Check Flutter
    if command -v flutter &> /dev/null; then
        local flutter_version=$(flutter --version | head -1)
        log_success "Flutter: $flutter_version"
    else
        log_error "Flutter not found"
        return 1
    fi
    
    # Check Xcode
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version | head -1)
        log_success "Xcode: $xcode_version"
    else
        log_error "Xcode not found"
        return 1
    fi
    
    # Check CocoaPods
    if command -v pod &> /dev/null; then
        local pod_version=$(pod --version)
        log_success "CocoaPods: $pod_version"
    else
        log_error "CocoaPods not found"
        return 1
    fi
    
    return 0
}

# Generate validation report
generate_validation_report() {
    log_info "📋 Generating validation report..."
    
    local report_file="$PROJECT_ROOT/output/ios/APPSTORE_VALIDATION_REPORT.txt"
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# iOS App Store Connect Validation Report

## App Information
- App Name: ${APP_NAME:-"NOT SET"}
- Bundle ID: ${BUNDLE_ID:-"NOT SET"}
- Version Name: ${VERSION_NAME:-"NOT SET"}
- Version Code: ${VERSION_CODE:-"NOT SET"}
- Profile Type: ${PROFILE_TYPE:-"NOT SET"}

## Code Signing Configuration
- Certificate: ${CERT_P12_URL:-"NOT SET"}
- Certificate (CER): ${CERT_CER_URL:-"NOT SET"}
- Certificate (KEY): ${CERT_KEY_URL:-"NOT SET"}
- Certificate Password: ${CERT_PASSWORD:+"SET"}${CERT_PASSWORD:-"NOT SET"}
- Provisioning Profile: ${PROFILE_URL:-"NOT SET"}
- Apple Team ID: ${APPLE_TEAM_ID:-"NOT SET"}

## App Store Connect API Configuration
- Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-"NOT SET"}
- API Key Path: ${APP_STORE_CONNECT_API_KEY_PATH:-"NOT SET"}
- Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID:-"NOT SET"}

## Firebase Configuration
- Push Notifications: ${PUSH_NOTIFY:-"false"}
- Firebase Config: ${FIREBASE_CONFIG_IOS:+"SET"}${FIREBASE_CONFIG_IOS:-"NOT SET"}

## Build Environment
- Flutter: $(flutter --version | head -1 2>/dev/null || echo "NOT AVAILABLE")
- Xcode: $(xcodebuild -version | head -1 2>/dev/null || echo "NOT AVAILABLE")
- CocoaPods: $(pod --version 2>/dev/null || echo "NOT AVAILABLE")

## Validation Results
- App Info: $([ -n "${APP_NAME:-}" ] && [ -n "${BUNDLE_ID:-}" ] && [ -n "${VERSION_NAME:-}" ] && [ -n "${VERSION_CODE:-}" ] && echo "✅ PASS" || echo "❌ FAIL")
- Profile Type: $([ "$PROFILE_TYPE" = "app-store" ] && echo "✅ PASS" || echo "❌ FAIL")
- Code Signing: $([ -n "${CERT_PASSWORD:-}" ] && [ -n "${PROFILE_URL:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && echo "✅ PASS" || echo "❌ FAIL")
- App Store Connect: $([ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] && [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ] && [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ] && echo "✅ PASS" || echo "❌ FAIL")
- Firebase: $([ "${PUSH_NOTIFY:-false}" != "true" ] || [ -n "${FIREBASE_CONFIG_IOS:-}" ] && echo "✅ PASS" || echo "❌ FAIL")

## Recommendations
EOF

    # Add recommendations based on validation results
    if [ -z "${APP_NAME:-}" ] || [ -z "${BUNDLE_ID:-}" ] || [ -z "${VERSION_NAME:-}" ] || [ -z "${VERSION_CODE:-}" ]; then
        echo "- Set all required app information variables" >> "$report_file"
    fi
    
    if [ "$PROFILE_TYPE" != "app-store" ]; then
        echo "- Set PROFILE_TYPE to 'app-store' for App Store Connect publishing" >> "$report_file"
    fi
    
    if [ -z "${CERT_PASSWORD:-}" ] || [ -z "${PROFILE_URL:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ]; then
        echo "- Provide complete code signing configuration" >> "$report_file"
    fi
    
    if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] || [ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ] || [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        echo "- Provide App Store Connect API credentials for automated upload" >> "$report_file"
    fi
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ] && [ -z "${FIREBASE_CONFIG_IOS:-}" ]; then
        echo "- Provide Firebase configuration when push notifications are enabled" >> "$report_file"
    fi
    
    log_success "Validation report generated: $report_file"
}

# Main validation function
main() {
    log_info "🚀 Starting iOS App Store Connect validation..."
    
    local validation_passed=true
    
    # Run all validations
    if ! validate_app_info; then
        validation_passed=false
    fi
    
    if ! validate_profile_type; then
        validation_passed=false
    fi
    
    if ! validate_code_signing; then
        validation_passed=false
    fi
    
    if ! validate_appstore_connect; then
        validation_passed=false
    fi
    
    if ! validate_firebase; then
        validation_passed=false
    fi
    
    if ! validate_build_environment; then
        validation_passed=false
    fi
    
    # Generate report
    generate_validation_report
    
    # Final result
    if [ "$validation_passed" = true ]; then
        log_success "🎉 iOS App Store Connect validation PASSED!"
        log_info "📦 Ready for App Store Connect publishing"
        exit 0
    else
        log_error "❌ iOS App Store Connect validation FAILED!"
        log_info "📋 Check the validation report for details"
        exit 1
    fi
}

# Run validation
main "$@" 