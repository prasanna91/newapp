#!/bin/bash

# 🎨 iOS Customization Script for QuikApp
# This script customizes the iOS app with bundle ID, app name, and icon

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

log_info "🎨 Starting iOS Customization"

# Update bundle ID in project.pbxproj
update_bundle_id() {
    log_info "📝 Updating bundle ID to: $BUNDLE_ID"
    
    local project_file="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"
    
    if [ -f "$project_file" ]; then
        # Backup original file
        cp "$project_file" "$project_file.backup"
        
        # Update PRODUCT_BUNDLE_IDENTIFIER
        sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$project_file"
        
        log_success "Bundle ID updated in project.pbxproj"
    else
        log_error "project.pbxproj file not found!"
        exit 1
    fi
}

# Update app name in Info.plist
update_app_name() {
    log_info "📝 Updating app name to: $APP_NAME"
    
    local info_plist_file="$PROJECT_ROOT/ios/Runner/Info.plist"
    
    if [ -f "$info_plist_file" ]; then
        # Backup original file
        cp "$info_plist_file" "$info_plist_file.backup"
        
        # Update CFBundleDisplayName
        sed -i.bak "s/<key>CFBundleDisplayName<\/key>.*<string>.*<\/string>/<key>CFBundleDisplayName<\/key>\n\t<string>$APP_NAME<\/string>/" "$info_plist_file"
        
        # Update CFBundleName
        sed -i.bak "s/<key>CFBundleName<\/key>.*<string>.*<\/string>/<key>CFBundleName<\/key>\n\t<string>$APP_NAME<\/string>/" "$info_plist_file"
        
        log_success "App name updated in Info.plist"
    else
        log_error "Info.plist file not found!"
        exit 1
    fi
}

# Update app icon
update_app_icon() {
    log_info "🎨 Updating app icon..."
    
    local icon_path="${APP_ICON_PATH:-assets/images/logo.png}"
    local source_icon="$PROJECT_ROOT/$icon_path"
    
    if [ -f "$source_icon" ]; then
        # Create Assets.xcassets/AppIcon.appiconset directory
        local app_icon_dir="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
        mkdir -p "$app_icon_dir"
        
        # Copy icon to AppIcon.appiconset
        cp "$source_icon" "$app_icon_dir/Icon-App-1024x1024@1x.png"
        
        # Create Contents.json for AppIcon
        cat > "$app_icon_dir/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        
        log_success "App icon updated"
    else
        log_warning "App icon not found at: $source_icon"
        log_info "Using default Flutter icon"
    fi
}

# Update version information
update_version() {
    log_info "📝 Updating version information..."
    
    local project_file="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"
    
    if [ -f "$project_file" ]; then
        # Update CURRENT_PROJECT_VERSION
        sed -i.bak "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $VERSION_CODE;/g" "$project_file"
        
        # Update MARKETING_VERSION
        sed -i.bak "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION_NAME;/g" "$project_file"
        
        log_success "Version information updated"
    else
        log_error "project.pbxproj file not found!"
        exit 1
    fi
}

# Main execution
main() {
    log_info "🎨 Starting iOS customization for $APP_NAME"
    
    # Validate required variables
    if [ -z "$BUNDLE_ID" ]; then
        log_error "BUNDLE_ID is required!"
        exit 1
    fi
    
    if [ -z "$APP_NAME" ]; then
        log_error "APP_NAME is required!"
        exit 1
    fi
    
    # Run customization steps
    update_bundle_id
    update_app_name
    update_app_icon
    update_version
    
    log_success "🎉 iOS customization completed successfully!"
}

# Run main function
main "$@" 