#!/bin/bash

# 🚀 Android Main Build Script for QuikApp
# This script orchestrates the complete Android build process

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
UTILS_DIR="$SCRIPT_DIR/../utils"

# Build start time for duration tracking
BUILD_START_TIME=$(date +%s)

log_info "🚀 Starting Android Build Process"
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
        "VERSION_NAME"
        "VERSION_CODE"
        "WEB_URL"
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

# Run customization script
run_customization() {
    log_info "🎨 Running customization..."
    
    if [ -f "$SCRIPT_DIR/customization.sh" ]; then
        bash "$SCRIPT_DIR/customization.sh"
        log_success "Customization completed"
    else
        log_warning "Customization script not found, skipping..."
    fi
}

# Run branding script
run_branding() {
    log_info "🎨 Running branding..."
    
    if [ -f "$SCRIPT_DIR/branding.sh" ]; then
        bash "$SCRIPT_DIR/branding.sh"
        log_success "Branding completed"
    else
        log_warning "Branding script not found, skipping..."
    fi
}

# Run permissions script
run_permissions() {
    log_info "🔐 Running permissions setup..."
    
    if [ -f "$SCRIPT_DIR/permissions.sh" ]; then
        bash "$SCRIPT_DIR/permissions.sh"
        log_success "Permissions setup completed"
    else
        log_warning "Permissions script not found, skipping..."
    fi
}

# Run Firebase script
run_firebase() {
    log_info "🔥 Running Firebase setup..."
    
    if [ -f "$SCRIPT_DIR/firebase.sh" ]; then
        bash "$SCRIPT_DIR/firebase.sh"
        log_success "Firebase setup completed"
    else
        log_warning "Firebase script not found, skipping..."
    fi
}

# Run keystore script
run_keystore() {
    log_info "🔐 Running keystore setup..."
    
    if [ -f "$SCRIPT_DIR/keystore.sh" ]; then
        bash "$SCRIPT_DIR/keystore.sh"
        log_success "Keystore setup completed"
    else
        log_warning "Keystore script not found, skipping..."
    fi
}

# Build the app
build_app() {
    log_info "🏗️ Building Android app..."
    
    cd "$PROJECT_ROOT"
    
    # Clean previous builds
    log_info "🧹 Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    log_info "📦 Getting dependencies..."
    flutter pub get
    
    # Build APK
    log_info "📱 Building APK..."
    flutter build apk --release
    
    # Build AAB if keystore is configured
    if [ -n "$KEY_STORE_URL" ] && [ -n "$CM_KEYSTORE_PASSWORD" ]; then
        log_info "📦 Building AAB..."
        flutter build appbundle --release
    else
        log_warning "Keystore not configured, skipping AAB build"
    fi
    
    log_success "Build completed"
}

# Copy artifacts
copy_artifacts() {
    log_info "📦 Copying artifacts..."
    
    # Create output directory
    mkdir -p "$PROJECT_ROOT/output/android"
    
    # Copy APK
    if [ -f "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" \
           "$PROJECT_ROOT/output/android/app-release.apk"
        log_success "APK copied to output/android/app-release.apk"
    fi
    
    # Copy AAB
    if [ -f "$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab" \
           "$PROJECT_ROOT/output/android/app-release.aab"
        log_success "AAB copied to output/android/app-release.aab"
    fi
    
    # Copy mapping file
    if [ -f "$PROJECT_ROOT/build/app/outputs/mapping/release/mapping.txt" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/mapping/release/mapping.txt" \
           "$PROJECT_ROOT/output/android/mapping.txt"
        log_success "Mapping file copied"
    fi
}

# Generate build summary
generate_summary() {
    log_info "📋 Generating build summary..."
    
    local summary_file="$PROJECT_ROOT/output/android/BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
# Android Build Summary

## Build Information
- App Name: ${APP_NAME}
- Package Name: ${PKG_NAME}
- Version Name: ${VERSION_NAME}
- Version Code: ${VERSION_CODE}
- Workflow: ${WORKFLOW_ID}

## Build Time
- Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Artifacts
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
    echo "## Features" >> "$summary_file"
    echo "- Push Notifications: ${PUSH_NOTIFY:-false}" >> "$summary_file"
    echo "- Firebase: ${FIREBASE_CONFIG_ANDROID:+true}" >> "$summary_file"
    echo "- Code Signing: ${KEY_STORE_URL:+true}" >> "$summary_file"
    echo "- Bottom Menu: ${IS_BOTTOMMENU:-false}" >> "$summary_file"
    echo "- Splash Screen: ${IS_SPLASH:-false}" >> "$summary_file"
    
    log_success "Build summary generated: $summary_file"
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
    log_info "🚀 Starting Android build process for $APP_NAME"
    
    # Send build start notification
    send_email_notification "start"
    
    # Validate environment
    validate_required_vars
    
    # Setup
    setup_directories
    generate_env_config
    
    # Run build steps
    run_customization
    run_branding
    run_permissions
    run_firebase
    run_keystore
    
    # Build
    build_app
    
    # Finalize
    copy_artifacts
    generate_summary
    
    log_success "🎉 Android build completed successfully!"
    log_info "📦 Artifacts available in: $PROJECT_ROOT/output/android/"
    
    # Send build success notification
    send_email_notification "success"
}

# Error handling wrapper
{
    main "$@"
} || {
    local exit_code=$?
    local error_message="Android build failed with exit code: $exit_code"
    log_error "$error_message"
    send_email_notification "failed" "$error_message"
    exit $exit_code
} 