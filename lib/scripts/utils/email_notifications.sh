#!/bin/bash

# 📧 Email Notification System for QuikApp Build System
# This script handles email notifications for all build workflows

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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Email configuration
EMAIL_ENABLED="${ENABLE_EMAIL_NOTIFICATIONS:-false}"
SMTP_SERVER="${EMAIL_SMTP_SERVER:-smtp.gmail.com}"
SMTP_PORT="${EMAIL_SMTP_PORT:-587}"
SMTP_USER="${EMAIL_SMTP_USER:-}"
SMTP_PASS="${EMAIL_SMTP_PASS:-}"
RECIPIENT_EMAIL="${EMAIL_ID:-}"

# Build information
BUILD_STATUS="${1:-unknown}" # start, success, failed
BUILD_ERROR="${2:-}"
BUILD_DURATION="${3:-}"

# Check if email notifications are enabled
check_email_config() {
    if [ "$EMAIL_ENABLED" != "true" ]; then
        log_info "Email notifications disabled"
        return 1
    fi
    
    if [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] || [ -z "$RECIPIENT_EMAIL" ]; then
        log_warning "Email configuration incomplete"
        return 1
    fi
    
    return 0
}

# Get feature status (enabled/disabled)
get_feature_status() {
    local feature_value="$1"
    if [ "$feature_value" = "true" ]; then
        echo "✅ Enabled"
    else
        echo "❌ Disabled"
    fi
}

# Get permission status
get_permission_status() {
    local permission_value="$1"
    local permission_name="$2"
    if [ "$permission_value" = "true" ]; then
        echo "✅ $permission_name"
    else
        echo "❌ $permission_name"
    fi
}

# Get integration status
get_integration_status() {
    local integration_name="$1"
    local config_value="$2"
    local feature_flag="$3"
    
    if [ "$feature_flag" = "true" ] && [ -n "$config_value" ]; then
        echo "✅ $integration_name"
    elif [ "$feature_flag" = "true" ] && [ -z "$config_value" ]; then
        echo "⚠️ $integration_name (Config Missing)"
    else
        echo "❌ $integration_name"
    fi
}

# Get build artifacts
get_build_artifacts() {
    local artifacts=""
    
    # Android artifacts
    if [ -f "$PROJECT_ROOT/output/android/app-release.apk" ]; then
        local apk_size=$(du -h "$PROJECT_ROOT/output/android/app-release.apk" | cut -f1)
        artifacts="$artifacts<li>📱 Android APK: app-release.apk ($apk_size)</li>"
    fi
    
    if [ -f "$PROJECT_ROOT/output/android/app-release.aab" ]; then
        local aab_size=$(du -h "$PROJECT_ROOT/output/android/app-release.aab" | cut -f1)
        artifacts="$artifacts<li>📦 Android AAB: app-release.aab ($aab_size)</li>"
    fi
    
    # iOS artifacts
    if [ -f "$PROJECT_ROOT/output/ios/Runner.ipa" ]; then
        local ipa_size=$(du -h "$PROJECT_ROOT/output/ios/Runner.ipa" | cut -f1)
        artifacts="$artifacts<li>🍎 iOS IPA: Runner.ipa ($ipa_size)</li>"
    fi
    
    if [ -d "$PROJECT_ROOT/output/ios/Runner.xcarchive" ]; then
        local archive_size=$(du -sh "$PROJECT_ROOT/output/ios/Runner.xcarchive" | cut -f1)
        artifacts="$artifacts<li>📦 iOS Archive: Runner.xcarchive ($archive_size)</li>"
    fi
    
    if [ -z "$artifacts" ]; then
        artifacts="<li>⚠️ No artifacts generated</li>"
    fi
    
    echo "$artifacts"
}

# Generate email HTML content
generate_email_content() {
    local status="$1"
    local error_message="$2"
    
    # Status-specific styling
    local status_color=""
    local status_icon=""
    local status_text=""
    
    case "$status" in
        "start")
            status_color="#667eea"
            status_icon="🚀"
            status_text="Build Started"
            ;;
        "success")
            status_color="#11998e"
            status_icon="🎉"
            status_text="Build Successful"
            ;;
        "failed")
            status_color="#ff6b6b"
            status_icon="❌"
            status_text="Build Failed"
            ;;
        *)
            status_color="#6c757d"
            status_icon="ℹ️"
            status_text="Build Status"
            ;;
    esac
    
    # Get build artifacts
    local artifacts=$(get_build_artifacts)
    
    # Generate HTML email
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QuikApp Build Notification</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, $status_color 0%, ${status_color}dd 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 10px;
        }
        
        .header .status {
            font-size: 18px;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .section h2 {
            color: #2d3748;
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .info-item {
            background: #f7fafc;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .info-label {
            font-size: 12px;
            color: #718096;
            text-transform: uppercase;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .info-value {
            font-size: 14px;
            color: #2d3748;
            font-weight: 500;
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        
        .status-item {
            padding: 10px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 500;
        }
        
        .status-enabled {
            background: #c6f6d5;
            color: #22543d;
            border: 1px solid #9ae6b4;
        }
        
        .status-disabled {
            background: #fed7d7;
            color: #742a2a;
            border: 1px solid #feb2b2;
        }
        
        .status-warning {
            background: #fef5e7;
            color: #744210;
            border: 1px solid #fbd38d;
        }
        
        .artifacts {
            background: #f7fafc;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
        }
        
        .artifacts h3 {
            color: #2d3748;
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 15px;
        }
        
        .artifacts ul {
            list-style: none;
        }
        
        .artifacts li {
            padding: 8px 0;
            border-bottom: 1px solid #e2e8f0;
            font-size: 14px;
        }
        
        .artifacts li:last-child {
            border-bottom: none;
        }
        
        .error-message {
            background: #fed7d7;
            color: #742a2a;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #feb2b2;
            margin-bottom: 20px;
        }
        
        .actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }
        
        .btn {
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            text-align: center;
            flex: 1;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-secondary {
            background: #e2e8f0;
            color: #4a5568;
        }
        
        .footer {
            background: #f7fafc;
            padding: 20px 30px;
            text-align: center;
            border-top: 1px solid #e2e8f0;
        }
        
        .footer p {
            color: #718096;
            font-size: 14px;
            margin-bottom: 10px;
        }
        
        .footer-links {
            display: flex;
            justify-content: center;
            gap: 20px;
        }
        
        .footer-links a {
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
        }
        
        @media (max-width: 600px) {
            .info-grid, .status-grid {
                grid-template-columns: 1fr;
            }
            
            .actions {
                flex-direction: column;
            }
            
            .footer-links {
                flex-direction: column;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$status_icon $status_text</h1>
            <div class="status">QuikApp Build System</div>
        </div>
        
        <div class="content">
            <!-- App Information -->
            <div class="section">
                <h2>📱 App Information</h2>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">App Name</div>
                        <div class="info-value">${APP_NAME:-N/A}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Version</div>
                        <div class="info-value">${VERSION_NAME:-N/A} (${VERSION_CODE:-N/A})</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Bundle ID</div>
                        <div class="info-value">${BUNDLE_ID:-N/A}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Package Name</div>
                        <div class="info-value">${PKG_NAME:-N/A}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Workflow</div>
                        <div class="info-value">${WORKFLOW_ID:-N/A}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Build Duration</div>
                        <div class="info-value">${BUILD_DURATION:-N/A}</div>
                    </div>
                </div>
            </div>
            
            <!-- Customization Status -->
            <div class="section">
                <h2>🎨 Customization Features</h2>
                <div class="status-grid">
                    <div class="status-item $(get_feature_status "${IS_SPLASH:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_SPLASH:-false}")
                    </div>
                    <div class="status-item $(get_feature_status "${IS_BOTTOMMENU:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_BOTTOMMENU:-false}")
                    </div>
                    <div class="status-item $(get_feature_status "${IS_PULLDOWN:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_PULLDOWN:-false}")
                    </div>
                    <div class="status-item $(get_feature_status "${IS_LOAD_IND:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_LOAD_IND:-false}")
                    </div>
                </div>
            </div>
            
            <!-- Permissions Status -->
            <div class="section">
                <h2>🔐 Permissions</h2>
                <div class="status-grid">
                    <div class="status-item $(get_permission_status "${IS_CAMERA:-false}" "Camera" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_CAMERA:-false}" "Camera")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_LOCATION:-false}" "Location" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_LOCATION:-false}" "Location")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_MIC:-false}" "Microphone" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_MIC:-false}" "Microphone")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_NOTIFICATION:-false}" "Notifications" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_NOTIFICATION:-false}" "Notifications")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_CONTACT:-false}" "Contacts" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_CONTACT:-false}" "Contacts")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_BIOMETRIC:-false}" "Biometric" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_BIOMETRIC:-false}" "Biometric")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_CALENDAR:-false}" "Calendar" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_CALENDAR:-false}" "Calendar")
                    </div>
                    <div class="status-item $(get_permission_status "${IS_STORAGE:-false}" "Storage" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_permission_status "${IS_STORAGE:-false}" "Storage")
                    </div>
                </div>
            </div>
            
            <!-- Integration Status -->
            <div class="section">
                <h2>🔗 Integrations</h2>
                <div class="status-grid">
                    <div class="status-item $(get_integration_status "Firebase" "${FIREBASE_CONFIG_ANDROID:-}${FIREBASE_CONFIG_IOS:-}" "${PUSH_NOTIFY:-false}" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_integration_status "Firebase" "${FIREBASE_CONFIG_ANDROID:-}${FIREBASE_CONFIG_IOS:-}" "${PUSH_NOTIFY:-false}")
                    </div>
                    <div class="status-item $(get_feature_status "${IS_CHATBOT:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_CHATBOT:-false}")
                    </div>
                    <div class="status-item $(get_feature_status "${IS_DOMAIN_URL:-false}" | grep -q "Enabled" && echo "status-enabled" || echo "status-disabled")">
                        $(get_feature_status "${IS_DOMAIN_URL:-false}")
                    </div>
                    <div class="status-item $(get_integration_status "Code Signing" "${KEY_STORE_URL:-}${CERT_PASSWORD:-}" "true" | grep -q "✅" && echo "status-enabled" || echo "status-disabled")">
                        $(get_integration_status "Code Signing" "${KEY_STORE_URL:-}${CERT_PASSWORD:-}" "true")
                    </div>
                </div>
            </div>
            
            <!-- Error Message (if failed) -->
            $(if [ "$status" = "failed" ] && [ -n "$error_message" ]; then
                echo '<div class="error-message">
                    <strong>Error Details:</strong><br>
                    '"$error_message"'
                </div>'
            fi)
            
            <!-- Build Artifacts -->
            <div class="section">
                <h2>📦 Build Artifacts</h2>
                <div class="artifacts">
                    <h3>Generated Files:</h3>
                    <ul>
                        $artifacts
                    </ul>
                </div>
            </div>
            
            <!-- Action Buttons -->
            <div class="actions">
                <a href="https://codemagic.io/apps" class="btn btn-primary">View Build Logs</a>
                <a href="https://quikapp.co" class="btn btn-secondary">QuikApp Portal</a>
            </div>
        </div>
        
        <div class="footer">
            <p>This is an automated notification from QuikApp Build System</p>
            <div class="footer-links">
                <a href="https://quikapp.co">Website</a>
                <a href="https://app.quikapp.co">Portal</a>
                <a href="https://quikapp.co/docs">Documentation</a>
                <a href="https://quikapp.co/support">Support</a>
            </div>
            <p style="margin-top: 15px; font-size: 12px; color: #a0aec0;">
                © 2024 QuikApp. All rights reserved.
            </p>
        </div>
    </div>
</body>
</html>
EOF
}

# Send email using curl (SMTP)
send_email() {
    local subject="$1"
    local html_content="$2"
    
    # Create temporary files
    local email_file=$(mktemp)
    local html_file=$(mktemp)
    
    # Write HTML content to file
    echo "$html_content" > "$html_file"
    
    # Create email headers
    cat > "$email_file" << EOF
From: QuikApp Build System <$SMTP_USER>
To: $RECIPIENT_EMAIL
Subject: $subject
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: 7bit

EOF
    
    # Append HTML content
    cat "$html_file" >> "$email_file"
    
    # Send email using curl
    if curl --mail-from "$SMTP_USER" \
            --mail-rcpt "$RECIPIENT_EMAIL" \
            --upload-file "$email_file" \
            --ssl-reqd \
            --user "$SMTP_USER:$SMTP_PASS" \
            "smtp://$SMTP_SERVER:$SMTP_PORT" > /dev/null 2>&1; then
        log_success "Email sent successfully to $RECIPIENT_EMAIL"
    else
        log_error "Failed to send email"
        return 1
    fi
    
    # Cleanup
    rm -f "$email_file" "$html_file"
}

# Main notification function
send_notification() {
    if ! check_email_config; then
        return 0
    fi
    
    local status="$1"
    local error_message="$2"
    
    # Generate subject line
    local subject=""
    case "$status" in
        "start")
            subject="🚀 QuikApp Build Started - ${APP_NAME:-App}"
            ;;
        "success")
            subject="🎉 QuikApp Build Successful - ${APP_NAME:-App}"
            ;;
        "failed")
            subject="❌ QuikApp Build Failed - ${APP_NAME:-App}"
            ;;
        *)
            subject="ℹ️ QuikApp Build Status - ${APP_NAME:-App}"
            ;;
    esac
    
    # Generate email content
    local html_content=$(generate_email_content "$status" "$error_message")
    
    # Send email
    send_email "$subject" "$html_content"
}

# Main execution
main() {
    log_info "📧 Email notification system initialized"
    
    # Send notification based on status
    case "$BUILD_STATUS" in
        "start")
            log_info "📧 Sending build start notification..."
            send_notification "start"
            ;;
        "success")
            log_info "📧 Sending build success notification..."
            send_notification "success"
            ;;
        "failed")
            log_info "📧 Sending build failure notification..."
            send_notification "failed" "$BUILD_ERROR"
            ;;
        *)
            log_warning "Unknown build status: $BUILD_STATUS"
            ;;
    esac
}

# Run main function
main "$@" 