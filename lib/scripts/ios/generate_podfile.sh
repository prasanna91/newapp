#!/bin/bash

# 📦 iOS Podfile Generator Script for QuikApp
# This script generates a dynamic Podfile for iOS

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

log_info "📦 Starting iOS Podfile Generation"

# Generate Podfile
generate_podfile() {
    log_info "📝 Generating Podfile..."
    
    local podfile_path="$PROJECT_ROOT/ios/Podfile"
    local deployment_target="${IOS_DEPLOYMENT_TARGET:-14.0}"
    
    # Backup existing Podfile if it exists
    if [ -f "$podfile_path" ]; then
        log_info "📋 Backing up existing Podfile..."
        cp "$podfile_path" "$podfile_path.backup"
    fi
    
    log_info "📝 Creating new Podfile with iOS $deployment_target deployment target..."
    
    # Generate Podfile content
    cat > "$podfile_path" << EOF
# Uncomment this line to define a global platform for your project
platform :ios, '$deployment_target'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '$deployment_target'
      
      # Enable arm64 for simulator builds
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
EOF
    
    log_success "Podfile generated successfully"
    log_info "📋 Podfile location: $podfile_path"
    log_info "📱 iOS Deployment Target: $deployment_target"
    
    # Display Podfile content for verification
    log_info "📋 Podfile content:"
    echo "----------------------------------------"
    cat "$podfile_path"
    echo "----------------------------------------"
}

# Verify Podfile
verify_podfile() {
    log_info "🔍 Verifying generated Podfile..."
    
    local podfile_path="$PROJECT_ROOT/ios/Podfile"
    
    if [ ! -f "$podfile_path" ]; then
        log_error "Podfile was not created"
        return 1
    fi
    
    # Check for required elements
    local has_platform=false
    local has_target=false
    local has_post_install=false
    
    if grep -q "platform :ios" "$podfile_path"; then
        has_platform=true
        log_info "✅ Platform configuration found"
    else
        log_warning "Platform configuration not found"
    fi
    
    if grep -q "target 'Runner'" "$podfile_path"; then
        has_target=true
        log_info "✅ Runner target found"
    else
        log_warning "Runner target not found"
    fi
    
    if grep -q "post_install" "$podfile_path"; then
        has_post_install=true
        log_info "✅ Post-install hook found"
    else
        log_warning "Post-install hook not found"
    fi
    
    if [ "$has_platform" = true ] && [ "$has_target" = true ] && [ "$has_post_install" = true ]; then
        log_success "✅ Podfile verification passed"
        return 0
    else
        log_warning "⚠️ Podfile verification incomplete"
        return 1
    fi
}

# Main execution
main() {
    log_info "📦 Starting Podfile generation for $APP_NAME"
    
    # Generate Podfile
    generate_podfile
    
    # Verify Podfile
    if verify_podfile; then
        log_success "✅ Podfile generation completed successfully"
    else
        log_warning "⚠️ Podfile generation completed with warnings"
    fi
    
    return 0
}

# Run main function
main "$@" 