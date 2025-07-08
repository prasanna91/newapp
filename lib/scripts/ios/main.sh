#!/bin/bash

# 🚀 iOS Main Build Script for QuikApp
# This script orchestrates the complete iOS build process

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

log_info "🚀 Starting iOS Build Process"
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
    
    # Validate profile type
    local valid_profile_types=("app-store" "ad-hoc" "enterprise" "development")
    local is_valid=false
    
    for valid_type in "${valid_profile_types[@]}"; do
        if [ "$PROFILE_TYPE" = "$valid_type" ]; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = false ]; then
        log_error "Invalid PROFILE_TYPE: $PROFILE_TYPE. Must be one of: ${valid_profile_types[*]}"
        exit 1
    fi
    
    log_success "All required variables validated"
}

# Create output directories
setup_directories() {
    log_info "📁 Setting up output directories..."
    
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

# Run signing script
run_signing() {
    log_info "🔐 Running signing setup..."
    
    if [ -f "$SCRIPT_DIR/signing.sh" ]; then
        bash "$SCRIPT_DIR/signing.sh"
        log_success "Signing setup completed"
    else
        log_warning "Signing script not found, skipping..."
    fi
}

# Generate Podfile
generate_podfile() {
    log_info "📦 Generating Podfile..."
    
    if [ -f "$SCRIPT_DIR/generate_podfile.sh" ]; then
        bash "$SCRIPT_DIR/generate_podfile.sh"
        log_success "Podfile generated"
    else
        log_warning "Podfile generator not found, using default..."
    fi
}

# Build the app
build_app() {
    log_info "🏗️ Building iOS app..."
    
    cd "$PROJECT_ROOT"
    
    # Clean previous builds
    log_info "🧹 Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    log_info "📦 Getting dependencies..."
    flutter pub get
    
    # Install pods
    log_info "📦 Installing CocoaPods..."
    cd ios
    pod install --repo-update
    cd ..
    
    # Build archive
    log_info "📱 Building iOS archive..."
    flutter build ios --release --no-codesign
    
    log_success "Build completed"
}

# Export IPA
export_ipa() {
    log_info "📦 Exporting IPA..."
    
    cd "$PROJECT_ROOT"
    
    # Create ExportOptions.plist
    create_export_options
    
    # Export IPA
    if [ -d "build/ios/archive/Runner.xcarchive" ]; then
        log_info "🔧 Exporting IPA from archive..."
        
        xcodebuild -exportArchive \
            -archivePath build/ios/archive/Runner.xcarchive \
            -exportPath output/ios \
            -exportOptionsPlist ios/ExportOptions.plist \
            -allowProvisioningUpdates
        
        if [ -f "output/ios/Runner.ipa" ]; then
            log_success "IPA exported successfully"
        else
            log_error "IPA export failed"
            exit 1
        fi
    else
        log_error "Archive not found at build/ios/archive/Runner.xcarchive"
        exit 1
    fi
}

# Create ExportOptions.plist
create_export_options() {
    log_info "📋 Creating ExportOptions.plist..."
    
    local export_options_file="$PROJECT_ROOT/ios/ExportOptions.plist"
    
    cat > "$export_options_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$PROFILE_TYPE</string>
    <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>none</string>
EOF

    # Add distribution-specific options
    case "$PROFILE_TYPE" in
        "app-store")
            cat >> "$export_options_file" << EOF
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
EOF
            ;;
        "ad-hoc")
            cat >> "$export_options_file" << EOF
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>manifest</key>
    <dict>
        <key>appURL</key>
        <string>$INSTALL_URL</string>
        <key>displayImageURL</key>
        <string>$DISPLAY_IMAGE_URL</string>
        <key>fullSizeImageURL</key>
        <string>$FULL_SIZE_IMAGE_URL</string>
    </dict>
EOF
            ;;
        "enterprise")
            cat >> "$export_options_file" << EOF
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
EOF
            ;;
        "development")
            cat >> "$export_options_file" << EOF
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
EOF
            ;;
    esac
    
    cat >> "$export_options_file" << EOF
</dict>
</plist>
EOF

    log_success "ExportOptions.plist created for $PROFILE_TYPE distribution"
}

# Copy artifacts
copy_artifacts() {
    log_info "📦 Copying artifacts..."
    
    # Create output directory
    mkdir -p "$PROJECT_ROOT/output/ios"
    
    # Copy IPA
    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        log_success "IPA available at output/ios/Runner.ipa"
    fi
    
    # Copy archive if IPA export failed
    if [ -d "$PROJECT_ROOT/build/ios/archive/Runner.xcarchive" ]; then
        cp -r "$PROJECT_ROOT/build/ios/archive/Runner.xcarchive" \
              "$PROJECT_ROOT/output/ios/"
        log_success "Archive copied to output/ios/Runner.xcarchive"
    fi
    
    # Copy ExportOptions.plist
    if [ -f "$PROJECT_ROOT/ios/ExportOptions.plist" ]; then
        cp "$PROJECT_ROOT/ios/ExportOptions.plist" \
           "$PROJECT_ROOT/output/ios/"
        log_success "ExportOptions.plist copied"
    fi
}

# Generate build summary
generate_summary() {
    log_info "📋 Generating build summary..."
    
    local summary_file="$PROJECT_ROOT/output/ios/BUILD_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
# iOS Build Summary

## Build Information
- App Name: ${APP_NAME}
- Bundle ID: ${BUNDLE_ID}
- Version Name: ${VERSION_NAME}
- Version Code: ${VERSION_CODE}
- Workflow: ${WORKFLOW_ID}
- Profile Type: ${PROFILE_TYPE}

## Build Time
- Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Artifacts
EOF

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
    echo "- Firebase: ${FIREBASE_CONFIG_IOS:+true}" >> "$summary_file"
    echo "- Code Signing: ${CERT_PASSWORD:+true}" >> "$summary_file"
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
    log_info "🚀 Starting iOS build process for $APP_NAME"
    
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
    run_signing
    generate_podfile
    
    # Build and export using the dedicated script
    if [ -f "$SCRIPT_DIR/build_ipa.sh" ]; then
        bash "$SCRIPT_DIR/build_ipa.sh"
    else
        # Fallback to built-in build process
        build_app
        export_ipa
    fi
    
    # Finalize
    copy_artifacts
    generate_summary
    
    log_success "🎉 iOS build completed successfully!"
    log_info "📦 Artifacts available in: $PROJECT_ROOT/output/ios/"
    
    # Send build success notification
    send_email_notification "success"
}

# Error handling wrapper
{
    main "$@"
} || {
    local exit_code=$?
    local error_message="iOS build failed with exit code: $exit_code"
    log_error "$error_message"
    send_email_notification "failed" "$error_message"
    exit $exit_code
} 