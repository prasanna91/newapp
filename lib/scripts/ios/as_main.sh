#!/bin/bash

# 🍎 iOS App Store Build Script for QuikApp
# This script builds iOS apps specifically for App Store distribution

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

log_info "🍎 Starting iOS App Store Build Process"
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
        "APPLE_TEAM_ID"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required variable $var is not set!"
            exit 1
        fi
    done
    
    # Validate profile type is app-store
    if [ "$PROFILE_TYPE" != "app-store" ]; then
        log_error "Invalid PROFILE_TYPE: $PROFILE_TYPE. Must be 'app-store' for this workflow."
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
    log_info "🏗️ Building iOS app for App Store..."
    
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
    
    # Create ExportOptions.plist BEFORE building
    log_info "📋 Creating ExportOptions.plist for build..."
    create_export_options
    
    # Build archive
    log_info "📱 Building iOS archive for App Store..."
    flutter build ios --release --no-codesign
    
    log_success "Build completed"
}

# Export IPA for App Store
export_ipa() {
    log_info "📦 Exporting IPA for App Store..."
    
    cd "$PROJECT_ROOT"
    
    # ExportOptions.plist should already exist from build_app
    if [ ! -f "ios/ExportOptions.plist" ]; then
        log_error "ExportOptions.plist not found. Creating it now..."
        create_export_options
    fi
    
    # Export IPA
    if [ -d "build/ios/archive/Runner.xcarchive" ]; then
        log_info "🔧 Exporting IPA from archive..."
        
        xcodebuild -exportArchive \
            -archivePath build/ios/archive/Runner.xcarchive \
            -exportPath output/ios \
            -exportOptionsPlist ios/ExportOptions.plist \
            -allowProvisioningUpdates
        
        if [ -f "output/ios/Runner.ipa" ]; then
            log_success "IPA exported successfully for App Store"
        else
            log_error "IPA export failed"
            exit 1
        fi
    else
        log_error "Archive not found at build/ios/archive/Runner.xcarchive"
        exit 1
    fi
}

# Create ExportOptions.plist for App Store
create_export_options() {
    log_info "📋 Creating ExportOptions.plist for App Store..."
    
    local export_options_file="$PROJECT_ROOT/ios/ExportOptions.plist"
    
    cat > "$export_options_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
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
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
</dict>
</plist>
EOF

    log_success "ExportOptions.plist created for App Store distribution"
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
    
    local summary_file="$PROJECT_ROOT/output/ios/ARTIFACTS_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
# iOS App Store Build Summary

## Build Information
- App Name: ${APP_NAME}
- Bundle ID: ${BUNDLE_ID}
- Version Name: ${VERSION_NAME}
- Version Code: ${VERSION_CODE}
- Workflow: ${WORKFLOW_ID}
- Profile Type: app-store
- Team ID: ${APPLE_TEAM_ID}

## Build Time
- Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Artifacts
EOF

    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        local ipa_size=$(du -h "$PROJECT_ROOT/output/ios/Runner.ipa" | cut -f1)
        echo "- IPA: Runner.ipa (${ipa_size}) - Ready for App Store Connect" >> "$summary_file"
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
    
    echo "" >> "$summary_file"
    echo "## Next Steps" >> "$summary_file"
    echo "1. Upload the IPA to App Store Connect" >> "$summary_file"
    echo "2. Configure app metadata and screenshots" >> "$summary_file"
    echo "3. Submit for review" >> "$summary_file"
    
    log_success "Build summary generated: $summary_file"
}

# Main execution
main() {
    log_info "🍎 Starting iOS App Store build process for $APP_NAME"
    
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
    
    # Build
    build_app
    
    # Export
    export_ipa
    
    # Finalize
    copy_artifacts
    generate_summary
    
    log_success "🎉 iOS App Store build completed successfully!"
    log_info "📦 Artifacts available in: $PROJECT_ROOT/output/ios/"
    log_info "📱 IPA ready for App Store Connect upload"
}

# Run main function
main "$@" 