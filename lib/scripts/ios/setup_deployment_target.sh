#!/usr/bin/env bash

set -e

log() {
    echo "ℹ️  🎯 $1"
}

error() {
    echo "❌ 🎯 Error: $1" >&2
}

log "Setting up iOS deployment target..."

# Default deployment target for Firebase compatibility
DEFAULT_DEPLOYMENT_TARGET="14.0"
DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-$DEFAULT_DEPLOYMENT_TARGET}"

log "Using iOS deployment target: $DEPLOYMENT_TARGET"

# Update Podfile to ensure correct deployment target
if [ -f "ios/Podfile" ]; then
    log "Updating Podfile deployment target..."
    
    # Ensure platform is uncommented and set correctly
    if grep -q "# platform :ios" ios/Podfile; then
        sed -i '' "s/# platform :ios.*/platform :ios, '$DEPLOYMENT_TARGET'/" ios/Podfile
        log "Updated Podfile platform to iOS $DEPLOYMENT_TARGET"
    elif grep -q "platform :ios" ios/Podfile; then
        sed -i '' "s/platform :ios.*/platform :ios, '$DEPLOYMENT_TARGET'/" ios/Podfile
        log "Updated existing Podfile platform to iOS $DEPLOYMENT_TARGET"
    else
        # Add platform line after the first comment
        sed -i '' "2i\\
platform :ios, '$DEPLOYMENT_TARGET'\\
" ios/Podfile
        log "Added platform :ios, '$DEPLOYMENT_TARGET' to Podfile"
    fi
    
    # Ensure post_install hook sets deployment target for all pods
    if ! grep -q "config.build_settings\['IPHONEOS_DEPLOYMENT_TARGET'\]" ios/Podfile; then
        log "Adding deployment target enforcement to post_install hook..."
        
        # Find the post_install block and add deployment target setting
        if grep -q "post_install do |installer|" ios/Podfile; then
            # Add to existing post_install
            sed -i '' '/flutter_additional_ios_build_settings(target)/a\
    target.build_configurations.each do |config|\
      config.build_settings['\''IPHONEOS_DEPLOYMENT_TARGET'\''] = '\'''"$DEPLOYMENT_TARGET"''\''\
    end
' ios/Podfile
            log "Added deployment target setting to existing post_install hook"
        else
            # Create post_install hook
            cat >> ios/Podfile << EOF

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '$DEPLOYMENT_TARGET'
    end
  end
end
EOF
            log "Created post_install hook with deployment target setting"
        fi
    else
        log "Deployment target enforcement already present in post_install hook"
    fi
else
    error "Podfile not found at ios/Podfile"
    exit 1
fi

# Clean CocoaPods cache and derived data to ensure fresh installation
log "Cleaning CocoaPods cache..."
cd ios

# Remove Podfile.lock and Pods directory
if [ -f "Podfile.lock" ]; then
    rm -f Podfile.lock
    log "Removed Podfile.lock"
fi

if [ -d "Pods" ]; then
    rm -rf Pods
    log "Removed Pods directory"
fi

# Clean CocoaPods cache
if command -v pod >/dev/null 2>&1; then
    pod cache clean --all 2>/dev/null || true
    log "Cleaned CocoaPods cache"
fi

# Clean derived data
if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
    rm -rf "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null || true
    log "Cleaned Xcode derived data"
fi

cd ..

log "iOS deployment target setup completed successfully!"
log "Next step: Run 'flutter clean && flutter pub get' to regenerate iOS project files" 