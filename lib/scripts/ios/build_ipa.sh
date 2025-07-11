#!/bin/bash
set -euo pipefail

# 📱 iOS Build IPA Script for QuikApp
# This script handles the actual iOS build and IPA export process

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

log_info "📱 Starting iOS Build and IPA Export Process"

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
    if ! pod install --repo-update; then
        log_error "CocoaPods installation failed!"
        exit 1
    fi
    cd ..
    
    # Create ExportOptions.plist BEFORE building
    log_info "📋 Creating ExportOptions.plist for build..."
    create_export_options
    
    # Build IPA with error handling
    log_info "📱 Building iOS IPA..."
    
    # Verify ExportOptions.plist exists
    if [ ! -f "$PROJECT_ROOT/ios/ExportOptions.plist" ]; then
        log_error "ExportOptions.plist not found at $PROJECT_ROOT/ios/ExportOptions.plist"
        exit 1
    fi
    
    # Verify certificates are available
    log_info "🔍 Verifying certificates before build..."
    log_info "📋 Checking for valid code signing identities..."
    
    # Get detailed certificate information
    local cert_output=$(security find-identity -v -p codesigning 2>&1 || true)
    log_info "Certificate check output:"
    echo "$cert_output"
    
    if echo "$cert_output" | grep -q "valid identities found"; then
        log_success "Valid code signing certificates found"
    else
        log_error "No valid code signing certificates found in keychain"
        log_error "This indicates that the signing setup failed or certificates were not properly imported"
        log_error "Please check the signing script output above for any errors"
        exit 1
    fi
    
    log_info "Using ExportOptions.plist: $PROJECT_ROOT/ios/ExportOptions.plist"
    if ! flutter build ipa --release --export-options-plist="$PROJECT_ROOT/ios/ExportOptions.plist"; then
        log_error "Flutter build failed!"
        exit 1
    fi
    
    log_success "Build completed"
}

# Export IPA
export_ipa() {
    log_info "📦 Exporting IPA..."
    
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
            log_success "IPA exported successfully"
            log_info "📊 IPA size: $(du -h output/ios/Runner.ipa | cut -f1)"
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
            # Add App Store Connect API authentication if available
            if [ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] && [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ] && [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
                cat >> "$export_options_file" << EOF
    <key>uploadToAppStore</key>
    <true/>
    <key>appStoreConnectKeyIdentifier</key>
    <string>$APP_STORE_CONNECT_KEY_IDENTIFIER</string>
    <key>appStoreConnectKeyPath</key>
    <string>$APP_STORE_CONNECT_API_KEY_PATH</string>
    <key>appStoreConnectIssuerId</key>
    <string>$APP_STORE_CONNECT_ISSUER_ID</string>
EOF
            fi
            ;;
        "ad-hoc")
            cat >> "$export_options_file" << EOF
    <key>distributionBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
EOF
            # Add manifest for OTA installation if URL provided
            if [ -n "${INSTALL_URL:-}" ]; then
                cat >> "$export_options_file" << EOF
    <key>manifest</key>
    <dict>
        <key>appURL</key>
        <string>$INSTALL_URL</string>
EOF
                if [ -n "${DISPLAY_IMAGE_URL:-}" ]; then
                    cat >> "$export_options_file" << EOF
        <key>displayImageURL</key>
        <string>$DISPLAY_IMAGE_URL</string>
EOF
                fi
                if [ -n "${FULL_SIZE_IMAGE_URL:-}" ]; then
                    cat >> "$export_options_file" << EOF
        <key>fullSizeImageURL</key>
        <string>$FULL_SIZE_IMAGE_URL</string>
EOF
                fi
                cat >> "$export_options_file" << EOF
    </dict>
EOF
            fi
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

# Main execution
main() {
    log_info "📱 Starting iOS build and IPA export for $APP_NAME"
    
    # Build the app
    build_app
    
    # Export IPA
    export_ipa
    
    # Copy artifacts
    copy_artifacts
    
    log_success "🎉 iOS build and IPA export completed successfully!"
}

# Run main function
main "$@" 