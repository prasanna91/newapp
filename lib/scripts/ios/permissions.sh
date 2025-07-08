#!/bin/bash

# 🔐 iOS Permissions Script for QuikApp
# This script configures iOS permissions based on feature flags

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

log_info "🔐 Starting iOS Permissions Configuration"

# Configure permissions based on feature flags
configure_permissions() {
    log_info "🔧 Configuring iOS permissions..."
    
    local info_plist_file="$PROJECT_ROOT/ios/Runner/Info.plist"
    
    if [ ! -f "$info_plist_file" ]; then
        log_error "Info.plist not found!"
        exit 1
    fi
    
    # Backup original file
    cp "$info_plist_file" "$info_plist_file.backup"
    
    # Add usage descriptions based on feature flags
    local usage_descriptions=""
    
    # Camera permission
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSCameraUsageDescription</key>
	<string>This app needs camera access to take photos and videos.</string>"
        log_info "📷 Camera permission added"
    fi
    
    # Location permissions
    if [ "${IS_LOCATION:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This app needs location access to provide location-based services.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>This app needs location access to provide location-based services.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>This app needs location access to provide location-based services.</string>"
        log_info "📍 Location permissions added"
    fi
    
    # Microphone permission
    if [ "${IS_MIC:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSMicrophoneUsageDescription</key>
	<string>This app needs microphone access to record audio.</string>"
        log_info "🎤 Microphone permission added"
    fi
    
    # Contact permissions
    if [ "${IS_CONTACT:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSContactsUsageDescription</key>
	<string>This app needs contacts access to manage your contacts.</string>"
        log_info "👥 Contact permissions added"
    fi
    
    # Biometric permission
    if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSFaceIDUsageDescription</key>
	<string>This app uses Face ID for secure authentication.</string>"
        log_info "🔐 Biometric permission added"
    fi
    
    # Calendar permissions
    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSCalendarsUsageDescription</key>
	<string>This app needs calendar access to manage your events.</string>"
        log_info "📅 Calendar permissions added"
    fi
    
    # Storage permissions
    if [ "${IS_STORAGE:-false}" = "true" ]; then
        usage_descriptions="$usage_descriptions
	<key>NSPhotoLibraryUsageDescription</key>
	<string>This app needs photo library access to save and manage photos.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>This app needs photo library access to save photos.</string>"
        log_info "💾 Storage permissions added"
    fi
    
    # Always add network security (required for Flutter apps)
    usage_descriptions="$usage_descriptions
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>"
    log_info "🌐 Network security configured"
    
    # Insert usage descriptions before the closing </dict> tag
    if [ -n "$usage_descriptions" ]; then
        # Find the last </dict> and insert before it
        sed -i.bak "/<\/dict>/i\\$usage_descriptions" "$info_plist_file"
        log_success "Permissions configured successfully"
    else
        log_warning "No permissions to add"
    fi
}

# Main execution
main() {
    log_info "🔐 Starting iOS permissions configuration for $APP_NAME"
    
    # Configure permissions
    configure_permissions
    
    log_success "🎉 iOS permissions configuration completed successfully!"
}

# Run main function
main "$@" 