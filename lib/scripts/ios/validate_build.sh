#!/bin/bash
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# Validate build artifacts
validate_build_artifacts() {
    log_info "🔍 Validating build artifacts..."
    
    local has_ipa=false
    local has_archive=false
    local has_export_options=false
    
    # Check for IPA
    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        local ipa_size=$(du -h "$PROJECT_ROOT/output/ios/Runner.ipa" | cut -f1)
        log_success "IPA found: output/ios/Runner.ipa (${ipa_size})"
        has_ipa=true
    else
        log_error "IPA not found: output/ios/Runner.ipa"
    fi
    
    # Check for archive
    if [ -d "$PROJECT_ROOT/output/ios/Runner.xcarchive" ]; then
        local archive_size=$(du -sh "$PROJECT_ROOT/output/ios/Runner.xcarchive" | cut -f1)
        log_success "Archive found: output/ios/Runner.xcarchive (${archive_size})"
        has_archive=true
    else
        log_warning "Archive not found: output/ios/Runner.xcarchive"
    fi
    
    # Check for ExportOptions.plist
    if [ -f "$PROJECT_ROOT/output/ios/ExportOptions.plist" ]; then
        log_success "ExportOptions.plist found: output/ios/ExportOptions.plist"
        has_export_options=true
    else
        log_warning "ExportOptions.plist not found: output/ios/ExportOptions.plist"
    fi
    
    # Check for build summary
    if [ -f "$PROJECT_ROOT/output/ios/BUILD_SUMMARY.txt" ]; then
        log_success "Build summary found: output/ios/BUILD_SUMMARY.txt"
    else
        log_warning "Build summary not found: output/ios/BUILD_SUMMARY.txt"
    fi
    
    # Determine build success
    if [ "$has_ipa" = true ]; then
        log_success "✅ Build validation passed - IPA generated successfully"
        return 0
    elif [ "$has_archive" = true ]; then
        log_warning "⚠️  Archive generated but no IPA - export may have failed"
        return 1
    else
        log_error "❌ Build validation failed - no IPA or archive generated"
        return 1
    fi
}

# Validate IPA file
validate_ipa_file() {
    if [ ! -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        log_error "IPA file not found for validation"
        return 1
    fi
    
    log_info "🔍 Validating IPA file..."
    
    local ipa_file="$PROJECT_ROOT/output/ios/Runner.ipa"
    local ipa_size=$(du -h "$ipa_file" | cut -f1)
    
    # Check file size (should be reasonable for an iOS app)
    local size_bytes=$(du -b "$ipa_file" | cut -f1)
    if [ "$size_bytes" -lt 1000000 ]; then  # Less than 1MB
        log_warning "IPA file seems very small (${ipa_size}) - may be corrupted"
    else
        log_success "IPA file size looks reasonable (${ipa_size})"
    fi
    
    # Check if it's a valid zip file (IPAs are zip files)
    if file "$ipa_file" | grep -q "Zip archive"; then
        log_success "IPA file format is valid (Zip archive)"
    else
        log_warning "IPA file may not be a valid zip archive"
    fi
    
    # Check for required contents
    if unzip -l "$ipa_file" | grep -q "Payload/Runner.app"; then
        log_success "IPA contains Runner.app"
    else
        log_error "IPA does not contain Runner.app"
        return 1
    fi
    
    log_success "✅ IPA file validation passed"
    return 0
}

# Check for build errors in logs
check_build_errors() {
    log_info "🔍 Checking for build errors..."
    
    local error_found=false
    
    # Check for common build errors
    if [ -f "$PROJECT_ROOT/build/ios/logs/build.log" ]; then
        if grep -i "error\|failed\|exception" "$PROJECT_ROOT/build/ios/logs/build.log" >/dev/null 2>&1; then
            log_warning "Build errors found in logs"
            error_found=true
        fi
    fi
    
    # Check for CocoaPods errors
    if [ -f "$PROJECT_ROOT/ios/Podfile.lock" ]; then
        if grep -i "could not find compatible versions" "$PROJECT_ROOT/ios/Podfile.lock" >/dev/null 2>&1; then
            log_error "CocoaPods compatibility errors detected"
            error_found=true
        fi
    fi
    
    if [ "$error_found" = true ]; then
        return 1
    else
        log_success "No build errors detected in logs"
        return 0
    fi
}

# Main validation
main() {
    log_info "🔍 Starting build validation..."
    
    local validation_passed=true
    
    # Validate build artifacts
    if ! validate_build_artifacts; then
        validation_passed=false
    fi
    
    # Validate IPA file if it exists
    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        if ! validate_ipa_file; then
            validation_passed=false
        fi
    fi
    
    # Check for build errors
    if ! check_build_errors; then
        validation_passed=false
    fi
    
    # Final result
    if [ "$validation_passed" = true ]; then
        log_success "🎉 Build validation completed successfully!"
        exit 0
    else
        log_error "❌ Build validation failed!"
        exit 1
    fi
}

# Run validation
main "$@" 