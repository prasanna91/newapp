#!/bin/bash

# 🍎 iOS App Store Validation Script for QuikApp
# This script validates App Store Connect requirements

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

log_info "🍎 Starting iOS App Store Validation"

# Validate App Store Connect API configuration
validate_appstore_connect() {
    log_info "🔍 Validating App Store Connect API configuration..."
    
    local has_key_id=false
    local has_issuer_id=false
    local has_api_key=false
    
    if [ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]; then
        has_key_id=true
        log_info "✅ App Store Connect Key Identifier found"
    else
        log_warning "⚠️ App Store Connect Key Identifier not provided"
    fi
    
    if [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        has_issuer_id=true
        log_info "✅ App Store Connect Issuer ID found"
    else
        log_warning "⚠️ App Store Connect Issuer ID not provided"
    fi
    
    if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
        has_api_key=true
        log_info "✅ App Store Connect API Key Path found"
    else
        log_warning "⚠️ App Store Connect API Key Path not provided"
    fi
    
    if [ "$has_key_id" = true ] && [ "$has_issuer_id" = true ] && [ "$has_api_key" = true ]; then
        log_success "✅ App Store Connect API configuration complete"
        return 0
    else
        log_warning "⚠️ App Store Connect API configuration incomplete"
        log_info "📋 Manual upload to App Store Connect will be required"
        return 1
    fi
}

# Validate code signing configuration
validate_code_signing() {
    log_info "🔐 Validating code signing configuration..."
    
    local has_certificate=false
    local has_profile=false
    local has_team_id=false
    
    # Check for certificate configuration
    if [ -n "${CERT_P12_URL:-}" ] || ([ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]); then
        has_certificate=true
        log_info "✅ Certificate configuration found"
    else
        log_warning "⚠️ Certificate configuration not found"
    fi
    
    # Check for provisioning profile
    if [ -n "${PROFILE_URL:-}" ]; then
        has_profile=true
        log_info "✅ Provisioning profile configuration found"
    else
        log_warning "⚠️ Provisioning profile configuration not found"
    fi
    
    # Check for team ID
    if [ -n "${APPLE_TEAM_ID:-}" ]; then
        has_team_id=true
        log_info "✅ Apple Team ID found: $APPLE_TEAM_ID"
    else
        log_warning "⚠️ Apple Team ID not provided"
    fi
    
    if [ "$has_certificate" = true ] && [ "$has_profile" = true ] && [ "$has_team_id" = true ]; then
        log_success "✅ Code signing configuration complete"
        return 0
    else
        log_warning "⚠️ Code signing configuration incomplete"
        return 1
    fi
}

# Validate bundle identifier
validate_bundle_id() {
    log_info "📦 Validating bundle identifier..."
    
    if [ -n "${BUNDLE_ID:-}" ]; then
        # Check if bundle ID follows Apple's format
        if [[ "$BUNDLE_ID" =~ ^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$ ]]; then
            log_success "✅ Bundle ID format is valid: $BUNDLE_ID"
            return 0
        else
            log_warning "⚠️ Bundle ID format may be invalid: $BUNDLE_ID"
            log_info "📋 Bundle ID should follow reverse domain notation (e.g., com.company.app)"
            return 1
        fi
    else
        log_error "❌ Bundle ID not provided"
        return 1
    fi
}

# Validate app metadata
validate_app_metadata() {
    log_info "📱 Validating app metadata..."
    
    local has_app_name=false
    local has_version_name=false
    local has_version_code=false
    
    if [ -n "${APP_NAME:-}" ]; then
        has_app_name=true
        log_info "✅ App name found: $APP_NAME"
    else
        log_warning "⚠️ App name not provided"
    fi
    
    if [ -n "${VERSION_NAME:-}" ]; then
        has_version_name=true
        log_info "✅ Version name found: $VERSION_NAME"
    else
        log_warning "⚠️ Version name not provided"
    fi
    
    if [ -n "${VERSION_CODE:-}" ]; then
        has_version_code=true
        log_info "✅ Version code found: $VERSION_CODE"
    else
        log_warning "⚠️ Version code not provided"
    fi
    
    if [ "$has_app_name" = true ] && [ "$has_version_name" = true ] && [ "$has_version_code" = true ]; then
        log_success "✅ App metadata complete"
        return 0
    else
        log_warning "⚠️ App metadata incomplete"
        return 1
    fi
}

# Validate profile type
validate_profile_type() {
    log_info "📋 Validating profile type..."
    
    local valid_types=("app-store" "ad-hoc" "enterprise" "development")
    local profile_type="${PROFILE_TYPE:-app-store}"
    local is_valid=false
    
    for valid_type in "${valid_types[@]}"; do
        if [ "$profile_type" = "$valid_type" ]; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = true ]; then
        log_success "✅ Profile type is valid: $profile_type"
        
        # Check if profile type matches App Store requirements
        if [ "$profile_type" = "app-store" ]; then
            log_info "📋 App Store profile type selected - ready for App Store submission"
        else
            log_warning "⚠️ Profile type '$profile_type' selected - not suitable for App Store submission"
        fi
        
        return 0
    else
        log_error "❌ Invalid profile type: $profile_type"
        log_info "📋 Valid types: ${valid_types[*]}"
        return 1
    fi
}

# Validate Firebase configuration
validate_firebase() {
    log_info "🔥 Validating Firebase configuration..."
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "🔔 Push notifications enabled - Firebase required"
        
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            log_success "✅ Firebase configuration provided"
            return 0
        else
            log_error "❌ Firebase configuration required when PUSH_NOTIFY is true"
            return 1
        fi
    else
        log_info "🔕 Push notifications disabled - Firebase optional"
        if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
            log_info "✅ Firebase configuration provided (optional)"
        fi
        return 0
    fi
}

# Generate validation report
generate_validation_report() {
    log_info "📊 Generating validation report..."
    
    local report_file="$PROJECT_ROOT/output/ios/APP_STORE_VALIDATION_REPORT.txt"
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
🍎 iOS App Store Validation Report
=====================================
Generated: $(date)
App Name: ${APP_NAME:-"Not provided"}
Bundle ID: ${BUNDLE_ID:-"Not provided"}
Profile Type: ${PROFILE_TYPE:-"Not provided"}

📋 Validation Results:
EOF
    
    # Add validation results
    echo "✅ Bundle ID: ${BUNDLE_ID:-"Not provided"}" >> "$report_file"
    echo "✅ App Name: ${APP_NAME:-"Not provided"}" >> "$report_file"
    echo "✅ Version: ${VERSION_NAME:-"Not provided"} (${VERSION_CODE:-"Not provided"})" >> "$report_file"
    echo "✅ Team ID: ${APPLE_TEAM_ID:-"Not provided"}" >> "$report_file"
    echo "✅ Profile Type: ${PROFILE_TYPE:-"Not provided"}" >> "$report_file"
    echo "✅ Push Notifications: ${PUSH_NOTIFY:-"false"}" >> "$report_file"
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        echo "✅ Firebase Config: ${FIREBASE_CONFIG_IOS:-"Not provided"}" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "📋 App Store Connect API:" >> "$report_file"
    echo "   - Key Identifier: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-"Not provided"}" >> "$report_file"
    echo "   - Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID:-"Not provided"}" >> "$report_file"
    echo "   - API Key Path: ${APP_STORE_CONNECT_API_KEY_PATH:-"Not provided"}" >> "$report_file"
    
    log_success "📊 Validation report generated: $report_file"
}

# Main execution
main() {
    log_info "🍎 Starting iOS App Store validation for $APP_NAME"
    
    local validation_passed=true
    
    # Run all validations
    if ! validate_bundle_id; then
        validation_passed=false
    fi
    
    if ! validate_app_metadata; then
        validation_passed=false
    fi
    
    if ! validate_profile_type; then
        validation_passed=false
    fi
    
    if ! validate_code_signing; then
        validation_passed=false
    fi
    
    if ! validate_firebase; then
        validation_passed=false
    fi
    
    # App Store Connect validation is optional
    validate_appstore_connect || log_warning "App Store Connect API not configured"
    
    # Generate validation report
    generate_validation_report
    
    if [ "$validation_passed" = true ]; then
        log_success "✅ iOS App Store validation completed successfully"
        log_info "📋 App is ready for App Store submission"
        return 0
    else
        log_warning "⚠️ iOS App Store validation completed with issues"
        log_info "📋 Please review the validation report and fix any issues"
        return 1
    fi
}

# Run main function
main "$@" 