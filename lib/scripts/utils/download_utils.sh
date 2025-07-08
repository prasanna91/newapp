#!/bin/bash

# Download Utilities Script
# Provides common download functions for assets, certificates, and configuration files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOWNLOAD_MAX_RETRIES=${DOWNLOAD_MAX_RETRIES:-3}
DOWNLOAD_RETRY_DELAY=${DOWNLOAD_RETRY_DELAY:-5}

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "SUCCESS" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    elif [ "$status" = "ERROR" ]; then
        echo -e "${RED}❌ $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

# Function to download file with retry logic
download_file() {
    local url=$1
    local output_path=$2
    local description=${3:-"file"}
    
    echo "📥 Downloading $description from: $url"
    echo "📁 Output path: $output_path"
    
    # Create output directory if it doesn't exist
    local output_dir=$(dirname "$output_path")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo "📁 Created directory: $output_dir"
    fi
    
    local retry_count=0
    local success=false
    
    while [ $retry_count -lt $DOWNLOAD_MAX_RETRIES ] && [ "$success" = false ]; do
        echo "🔄 Download attempt $((retry_count + 1)) of $DOWNLOAD_MAX_RETRIES"
        
        if curl -L -f -o "$output_path" "$url" 2>/dev/null; then
            success=true
            print_status "SUCCESS" "$description downloaded successfully"
            
            # Verify file size
            local file_size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "0")
            if [ "$file_size" -gt 0 ]; then
                echo "📊 File size: ${file_size} bytes"
            else
                print_status "WARNING" "Downloaded file appears to be empty"
            fi
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $DOWNLOAD_MAX_RETRIES ]; then
                print_status "WARNING" "Download failed, retrying in $DOWNLOAD_RETRY_DELAY seconds..."
                sleep $DOWNLOAD_RETRY_DELAY
            else
                print_status "ERROR" "Failed to download $description after $DOWNLOAD_MAX_RETRIES attempts"
                return 1
            fi
        fi
    done
    
    return 0
}

# Function to download and validate image file
download_image() {
    local url=$1
    local output_path=$2
    local description=${3:-"image"}
    
    echo "🖼️  Downloading $description..."
    
    if download_file "$url" "$output_path" "$description"; then
        # Validate image file
        if file "$output_path" | grep -q "image"; then
            print_status "SUCCESS" "$description is a valid image file"
            return 0
        else
            print_status "WARNING" "$description may not be a valid image file"
            return 0
        fi
    else
        return 1
    fi
}

# Function to download and validate certificate file
download_certificate() {
    local url=$1
    local output_path=$2
    local cert_type=${3:-"certificate"}
    
    echo "🔐 Downloading $cert_type..."
    
    if download_file "$url" "$output_path" "$cert_type"; then
        # Validate certificate file
        local file_extension=$(echo "$output_path" | grep -o '\.[^.]*$' | tr '[:upper:]' '[:lower:]')
        
        case "$file_extension" in
            ".p12"|".pem"|".cer"|".crt"|".key")
                print_status "SUCCESS" "$cert_type appears to be a valid certificate file"
                ;;
            *)
                print_status "WARNING" "$cert_type may not be a valid certificate file (extension: $file_extension)"
                ;;
        esac
        
        return 0
    else
        return 1
    fi
}

# Function to download and validate provisioning profile
download_provisioning_profile() {
    local url=$1
    local output_path=$2
    
    echo "📱 Downloading provisioning profile..."
    
    if download_file "$url" "$output_path" "provisioning profile"; then
        # Validate provisioning profile
        if file "$output_path" | grep -q "XML\|plist\|binary"; then
            print_status "SUCCESS" "Provisioning profile appears to be valid"
            return 0
        else
            print_status "WARNING" "Provisioning profile may not be valid"
            return 0
        fi
    else
        return 1
    fi
}

# Function to download and validate Firebase configuration
download_firebase_config() {
    local url=$1
    local output_path=$2
    local platform=${3:-"unknown"}
    
    echo "🔥 Downloading Firebase configuration for $platform..."
    
    if download_file "$url" "$output_path" "Firebase configuration"; then
        # Validate Firebase configuration
        if file "$output_path" | grep -q "XML\|plist\|JSON"; then
            print_status "SUCCESS" "Firebase configuration appears to be valid"
            return 0
        else
            print_status "WARNING" "Firebase configuration may not be valid"
            return 0
        fi
    else
        return 1
    fi
}

# Function to download and validate keystore file
download_keystore() {
    local url=$1
    local output_path=$2
    
    echo "🔑 Downloading keystore file..."
    
    if download_file "$url" "$output_path" "keystore"; then
        # Validate keystore file
        if file "$output_path" | grep -q "Java\|JKS\|PKCS"; then
            print_status "SUCCESS" "Keystore appears to be valid"
            return 0
        else
            print_status "WARNING" "Keystore may not be valid"
            return 0
        fi
    else
        return 1
    fi
}

# Function to download and validate JSON configuration
download_json_config() {
    local url=$1
    local output_path=$2
    local description=${3:-"JSON configuration"}
    
    echo "📄 Downloading $description..."
    
    if download_file "$url" "$output_path" "$description"; then
        # Validate JSON file
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$output_path" 2>/dev/null; then
                print_status "SUCCESS" "$description is valid JSON"
                return 0
            else
                print_status "WARNING" "$description is not valid JSON"
                return 0
            fi
        else
            print_status "WARNING" "jq not available, skipping JSON validation"
            return 0
        fi
    else
        return 1
    fi
}

# Function to download and validate base64 encoded file
download_base64_file() {
    local url=$1
    local output_path=$2
    local description=${3:-"base64 file"}
    
    echo "📄 Downloading $description..."
    
    if download_file "$url" "$output_path" "$description"; then
        # Validate base64 content
        if base64 -d "$output_path" >/dev/null 2>&1; then
            print_status "SUCCESS" "$description appears to be valid base64"
            return 0
        else
            print_status "WARNING" "$description may not be valid base64"
            return 0
        fi
    else
        return 1
    fi
}

# Function to check if URL is accessible
check_url_accessibility() {
    local url=$1
    local description=${2:-"URL"}
    
    echo "🔍 Checking accessibility of $description..."
    
    if curl -I -f "$url" >/dev/null 2>&1; then
        print_status "SUCCESS" "$description is accessible"
        return 0
    else
        print_status "ERROR" "$description is not accessible"
        return 1
    fi
}

# Function to get file size from URL
get_remote_file_size() {
    local url=$1
    
    local size=$(curl -I -s "$url" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    if [ -n "$size" ]; then
        echo "$size"
    else
        echo "unknown"
    fi
}

# Function to download with progress bar
download_with_progress() {
    local url=$1
    local output_path=$2
    local description=${3:-"file"}
    
    echo "📥 Downloading $description with progress..."
    
    # Create output directory if it doesn't exist
    local output_dir=$(dirname "$output_path")
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
    
    # Get file size for progress
    local file_size=$(get_remote_file_size "$url")
    
    if [ "$file_size" != "unknown" ]; then
        echo "📊 Expected file size: ${file_size} bytes"
    fi
    
    # Download with progress
    if curl -L -f -# -o "$output_path" "$url"; then
        print_status "SUCCESS" "$description downloaded successfully"
        
        # Verify file size
        local actual_size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "0")
        if [ "$actual_size" -gt 0 ]; then
            echo "📊 Actual file size: ${actual_size} bytes"
        fi
        
        return 0
    else
        print_status "ERROR" "Failed to download $description"
        return 1
    fi
}

# Function to download multiple files
download_multiple_files() {
    local files_array=("$@")
    local success_count=0
    local total_count=${#files_array[@]}
    
    echo "📦 Downloading $total_count files..."
    
    for ((i=0; i<${#files_array[@]}; i+=2)); do
        local url="${files_array[i]}"
        local output_path="${files_array[i+1]}"
        
        if download_file "$url" "$output_path" "file $((i/2 + 1))"; then
            ((success_count++))
        fi
    done
    
    echo "📊 Download summary: $success_count/$total_count files downloaded successfully"
    
    if [ $success_count -eq $total_count ]; then
        print_status "SUCCESS" "All files downloaded successfully"
        return 0
    else
        print_status "WARNING" "Some files failed to download"
        return 1
    fi
}

# Function to clean up downloaded files
cleanup_downloads() {
    local files=("$@")
    
    echo "🧹 Cleaning up downloaded files..."
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "🗑️  Removed: $file"
        fi
    done
    
    print_status "SUCCESS" "Cleanup completed"
}

# Export functions for use in other scripts
export -f download_file
export -f download_image
export -f download_certificate
export -f download_provisioning_profile
export -f download_firebase_config
export -f download_keystore
export -f download_json_config
export -f download_base64_file
export -f check_url_accessibility
export -f get_remote_file_size
export -f download_with_progress
export -f download_multiple_files
export -f cleanup_downloads
export -f print_status

echo "📦 Download utilities loaded successfully" 