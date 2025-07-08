#!/bin/bash

# 🎨 Android Branding Script for QuikApp
# This script downloads and applies branding assets

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

log_info "🎨 Starting Android Branding"

# Download logo if URL is provided
download_logo() {
    if [ -n "$LOGO_URL" ]; then
        log_info "📥 Downloading logo from: $LOGO_URL"
        
        local logo_dir="$PROJECT_ROOT/assets/images"
        mkdir -p "$logo_dir"
        
        if curl -fsSL -o "$logo_dir/logo.png" "$LOGO_URL"; then
            log_success "Logo downloaded successfully"
        else
            log_warning "Failed to download logo, using default"
        fi
    else
        log_info "No logo URL provided, using default"
    fi
}

# Download splash screen if URL is provided
download_splash() {
    if [ -n "$SPLASH_URL" ]; then
        log_info "📥 Downloading splash screen from: $SPLASH_URL"
        
        local splash_dir="$PROJECT_ROOT/assets/images"
        mkdir -p "$splash_dir"
        
        if curl -fsSL -o "$splash_dir/splash.png" "$SPLASH_URL"; then
            log_success "Splash screen downloaded successfully"
        else
            log_warning "Failed to download splash screen, using default"
        fi
    else
        log_info "No splash URL provided, using default"
    fi
}

# Download splash background if URL is provided
download_splash_bg() {
    if [ -n "$SPLASH_BG_URL" ]; then
        log_info "📥 Downloading splash background from: $SPLASH_BG_URL"
        
        local splash_dir="$PROJECT_ROOT/assets/images"
        mkdir -p "$splash_dir"
        
        if curl -fsSL -o "$splash_dir/splash_bg.png" "$SPLASH_BG_URL"; then
            log_success "Splash background downloaded successfully"
        else
            log_warning "Failed to download splash background, using default"
        fi
    else
        log_info "No splash background URL provided, using default"
    fi
}

# Main execution
main() {
    log_info "🎨 Starting Android branding for $APP_NAME"
    
    # Download branding assets
    download_logo
    download_splash
    download_splash_bg
    
    log_success "🎉 Android branding completed successfully!"
}

# Run main function
main "$@" 