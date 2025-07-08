#!/bin/bash

# 🚀 Combined Build Script for QuikApp
# This script builds both Android and iOS apps in sequence

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

# Error handling
trap 'log_error "Build failed at line $LINENO. Exit code: $?"; exit 1' ERR

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ANDROID_SCRIPT_DIR="$SCRIPT_DIR/../android"
IOS_SCRIPT_DIR="$SCRIPT_DIR/../ios"
UTILS_DIR="$SCRIPT_DIR/../utils"

# Build start time for duration tracking
BUILD_START_TIME=$(date +%s)

log_info "🚀 Starting Combined Build Process"
log_info "📁 Project Root: $PROJECT_ROOT"
log_info "📁 Script Directory: $SCRIPT_DIR"

# Source environment variables
if [ -f "$UTILS_DIR/gen_env_config.sh" ]; then
    log_info "🔧 Sourcing environment configuration..."
    source "$UTILS_DIR/gen_env_config.sh"
else
    log_error "Environment configuration script not found!"
    exit 1
fi

# Validate required variables
validate_required_vars() {
    log_info "🔍 Validating required environment variables..."
    
    local required_vars=(
        "APP_NAME"
        "PKG_NAME"
        "BUNDLE_ID"
        "VERSION_NAME"
        "VERSION_CODE"
        "WEB_URL"
        "PROFILE_TYPE"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required variable $var is not set!"
            exit 1
        fi
    done
    
    log_success "All required variables validated"
}

# Create output directories
setup_directories() {
    log_info "📁 Setting up output directories..."
    
    mkdir -p "$PROJECT_ROOT/output/android"
    mkdir -p "$PROJECT_ROOT/output/ios"
    mkdir -p "$PROJECT_ROOT/temp"
    
    log_success "Output directories created"
}

# Generate environment configuration
generate_env_config() {
    log_info "🔧 Generating environment configuration..."
    
    if [ -f "$UTILS_DIR/gen_env_config.sh" ]; then
        bash "$UTILS_DIR/gen_env_config.sh"
        log_success "Environment configuration generated"
    else
        log_error "Environment configuration script not found!"
        exit 1
    fi
}

# Build Android
build_android() {
    log_info "🤖 Building Android app..."
    
    if [ -f "$ANDROID_SCRIPT_DIR/main.sh" ]; then
        log_info "🚀 Starting Android build..."
        bash "$ANDROID_SCRIPT_DIR/main.sh"
        log_success "Android build completed"
    else
        log_error "Android build script not found!"
        exit 1
    fi
}

# Build iOS
build_ios() {
    log_info "🍎 Building iOS app..."
    
    if [ -f "$IOS_SCRIPT_DIR/main.sh" ]; then
        log_info "🚀 Starting iOS build..."
        bash "$IOS_SCRIPT_DIR/main.sh"
        log_success "iOS build completed"
    else
        log_error "iOS build script not found!"
        exit 1
    fi
}

# Generate combined build summary
generate_summary() {
    log_info "📋 Generating combined build summary..."
    
    local summary_file="$PROJECT_ROOT/output/COMBINED_BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
# Combined Build Summary

## Build Information
- App Name: ${APP_NAME}
- Package Name: ${PKG_NAME}
- Bundle ID: ${BUNDLE_ID}
- Version Name: ${VERSION_NAME}
- Version Code: ${VERSION_CODE}
- Workflow: ${WORKFLOW_ID}
- Profile Type: ${PROFILE_TYPE}

## Build Time
- Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Android Artifacts
EOF

    if [ -f "$PROJECT_ROOT/output/android/app-release.apk" ]; then
        local apk_size=$(du -h "$PROJECT_ROOT/output/android/app-release.apk" | cut -f1)
        echo "- APK: app-release.apk (${apk_size})" >> "$summary_file"
    fi
    
    if [ -f "$PROJECT_ROOT/output/android/app-release.aab" ]; then
        local aab_size=$(du -h "$PROJECT_ROOT/output/android/app-release.aab" | cut -f1)
        echo "- AAB: app-release.aab (${aab_size})" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    echo "## iOS Artifacts" >> "$summary_file"
    
    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        local ipa_size=$(du -h "$PROJECT_ROOT/output/ios/Runner.ipa" | cut -f1)
        echo "- IPA: Runner.ipa (${ipa_size})" >> "$summary_file"
    fi
    
    if [ -d "$PROJECT_ROOT/output/ios/Runner.xcarchive" ]; then
        local archive_size=$(du -sh "$PROJECT_ROOT/output/ios/Runner.xcarchive" | cut -f1)
        echo "- Archive: Runner.xcarchive (${archive_size})" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    echo "## Features" >> "$summary_file"
    echo "- Push Notifications: ${PUSH_NOTIFY:-false}" >> "$summary_file"
    echo "- Firebase Android: ${FIREBASE_CONFIG_ANDROID:+true}" >> "$summary_file"
    echo "- Firebase iOS: ${FIREBASE_CONFIG_IOS:+true}" >> "$summary_file"
    echo "- Android Code Signing: ${KEY_STORE_URL:+true}" >> "$summary_file"
    echo "- iOS Code Signing: ${CERT_PASSWORD:+true}" >> "$summary_file"
    echo "- Bottom Menu: ${IS_BOTTOMMENU:-false}" >> "$summary_file"
    echo "- Splash Screen: ${IS_SPLASH:-false}" >> "$summary_file"
    
    log_success "Combined build summary generated: $summary_file"
}

# Send email notification
send_email_notification() {
    local status="$1"
    local error_message="${2:-}"
    
    if [ -f "$UTILS_DIR/email_notifications.sh" ]; then
        log_info "📧 Sending email notification: $status"
        
        # Calculate build duration
        local build_end_time=$(date +%s)
        local build_duration=$((build_end_time - BUILD_START_TIME))
        local duration_formatted=$(printf "%02d:%02d" $((build_duration / 60)) $((build_duration % 60)))
        
        bash "$UTILS_DIR/email_notifications.sh" "$status" "$error_message" "$duration_formatted"
    else
        log_warning "Email notification script not found"
    fi
}

# Main execution
main() {
    log_info "🚀 Starting combined build process for $APP_NAME"
    
    # Send build start notification
    send_email_notification "start"
    
    # Validate environment
    validate_required_vars
    
    # Setup
    setup_directories
    generate_env_config
    
    # Build Android first
    build_android
    
    # Build iOS second
    build_ios
    
    # Generate combined summary
    generate_summary
    
    log_success "🎉 Combined build completed successfully!"
    log_info "📦 Android artifacts: $PROJECT_ROOT/output/android/"
    log_info "📦 iOS artifacts: $PROJECT_ROOT/output/ios/"
    
    # Send build success notification
    send_email_notification "success"
}

# Error handling wrapper
{
    main "$@"
} || {
    local exit_code=$?
    local error_message="Combined build failed with exit code: $exit_code"
    log_error "$error_message"
    send_email_notification "failed" "$error_message"
    exit $exit_code
} 