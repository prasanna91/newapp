# iOS Signing Fallback Logic Documentation

## 🔐 Overview

The iOS signing process now implements a robust fallback mechanism that prioritizes P12 certificates but gracefully falls back to CER+KEY certificate generation when needed. This ensures maximum compatibility and flexibility for different certificate formats.

## 🎯 Signing Priority Logic

### Method 1: Direct P12 Certificate (Primary)

**Priority: HIGHEST**

**Required Variables:**

- `CERT_P12_URL` - URL to the P12 certificate file
- `CERT_PASSWORD` - Password for the P12 certificate

**Process:**

1. Download P12 certificate from `CERT_P12_URL`
2. Verify P12 file integrity using `CERT_PASSWORD`
3. If verification fails, clean up and fall back to Method 2
4. If successful, proceed with signing

**Example Configuration:**

```yaml
CERT_P12_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.p12"
CERT_PASSWORD: "your_p12_password"
```

### Method 2: CER+KEY Certificate Generation (Fallback)

**Priority: FALLBACK**

**Required Variables:**

- `CERT_CER_URL` - URL to the certificate file (.cer)
- `CERT_KEY_URL` - URL to the private key file (.key)
- `CERT_PASSWORD` - Optional password (uses default if not provided)

**Process:**

1. Download CER and KEY files from respective URLs
2. Verify both files for integrity
3. Convert CER+KEY to P12 format using OpenSSL
4. Use provided password or default password (`quikapp_default_password_2024`)
5. Clean up temporary CER and KEY files
6. Proceed with signing using generated P12

**Example Configuration:**

```yaml
CERT_CER_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.cer"
CERT_KEY_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.key"
CERT_PASSWORD: "optional_password" # Optional, uses default if not provided
```

## 🔄 Fallback Flow

```
Start iOS Signing
       ↓
Check CERT_P12_URL + CERT_PASSWORD
       ↓
   [Available?] ──YES──→ Download & Verify P12
       ↓ NO                    ↓
   [Success?] ──YES──→ Use P12 for Signing
       ↓ NO                    ↓
   [Available?] ──YES──→ Download CER + KEY
       ↓ NO                    ↓
   [Success?] ──YES──→ Convert to P12
       ↓ NO                    ↓
   [Success?] ──YES──→ Use Generated P12
       ↓ NO                    ↓
   ❌ All Methods Failed
```

## 🛡️ Security Features

### Certificate Verification

- **P12 Verification**: Uses OpenSSL to verify P12 integrity and password
- **CER Verification**: Validates certificate format and structure
- **KEY Verification**: Checks private key validity and format
- **Profile Verification**: Validates provisioning profile using `security cms`

### Error Handling

- **Graceful Degradation**: Falls back to alternative methods on failure
- **Cleanup**: Removes temporary files on verification failures
- **Detailed Logging**: Comprehensive error messages for troubleshooting
- **Secure Defaults**: Uses secure default password for generated P12 files

## 📋 Required Environment Variables

### Always Required

```yaml
PROFILE_URL: "https://raw.githubusercontent.com/your-repo/profiles/app.mobileprovision"
APPLE_TEAM_ID: "YOUR_TEAM_ID"
BUNDLE_ID: "com.yourcompany.yourapp"
```

### Certificate Variables (Choose One Method)

**Method 1 - P12:**

```yaml
CERT_P12_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.p12"
CERT_PASSWORD: "your_p12_password"
```

**Method 2 - CER+KEY:**

```yaml
CERT_CER_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.cer"
CERT_KEY_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.key"
CERT_PASSWORD: "optional_password" # Optional
```

## 🔧 Implementation Details

### Script Location

- **Primary Script**: `lib/scripts/ios/signing.sh`
- **Used By**:
  - `lib/scripts/ios/main.sh` (iOS-only workflow)
  - `lib/scripts/combined/main.sh` (Combined workflow)

### Key Functions

1. `validate_signing_vars()` - Validates required environment variables
2. `setup_p12_certificate()` - Handles direct P12 certificate setup
3. `setup_cer_key_certificate()` - Handles CER+KEY to P12 conversion
4. `setup_provisioning_profile()` - Downloads and verifies provisioning profile
5. `configure_signing()` - Orchestrates the fallback logic

### Default Password

When using CER+KEY method without `CERT_PASSWORD`:

```
Default Password: quikapp_default_password_2024
```

## 🚀 Usage Examples

### Example 1: P12 Certificate (Recommended)

```yaml
# codemagic.yaml environment variables
CERT_P12_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.p12"
CERT_PASSWORD: "your_secure_password"
PROFILE_URL: "https://raw.githubusercontent.com/your-repo/profiles/app.mobileprovision"
APPLE_TEAM_ID: "ABC123DEF4"
BUNDLE_ID: "com.yourcompany.yourapp"
```

### Example 2: CER+KEY Certificate (Fallback)

```yaml
# codemagic.yaml environment variables
CERT_CER_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.cer"
CERT_KEY_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.key"
CERT_PASSWORD: "your_secure_password" # Optional
PROFILE_URL: "https://raw.githubusercontent.com/your-repo/profiles/app.mobileprovision"
APPLE_TEAM_ID: "ABC123DEF4"
BUNDLE_ID: "com.yourcompany.yourapp"
```

### Example 3: CER+KEY with Default Password

```yaml
# codemagic.yaml environment variables
CERT_CER_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.cer"
CERT_KEY_URL: "https://raw.githubusercontent.com/your-repo/certificates/app.key"
# CERT_PASSWORD not provided - will use default
PROFILE_URL: "https://raw.githubusercontent.com/your-repo/profiles/app.mobileprovision"
APPLE_TEAM_ID: "ABC123DEF4"
BUNDLE_ID: "com.yourcompany.yourapp"
```

## 🔍 Troubleshooting

### Common Issues

1. **P12 Download Failed**

   - Check `CERT_P12_URL` accessibility
   - Verify URL is publicly accessible
   - Ensure file exists at the specified location

2. **P12 Verification Failed**

   - Verify `CERT_PASSWORD` is correct
   - Check if P12 file is corrupted
   - Ensure P12 file contains valid certificate and private key

3. **CER/KEY Download Failed**

   - Check `CERT_CER_URL` and `CERT_KEY_URL` accessibility
   - Verify both URLs are publicly accessible
   - Ensure files exist at specified locations

4. **CER/KEY Verification Failed**

   - Verify CER file is a valid certificate
   - Check KEY file is a valid private key
   - Ensure CER and KEY files are a matching pair

5. **Provisioning Profile Issues**
   - Check `PROFILE_URL` accessibility
   - Verify profile is valid and not expired
   - Ensure profile matches `BUNDLE_ID` and `APPLE_TEAM_ID`

### Debug Commands

```bash
# Verify P12 file
openssl pkcs12 -info -in Runner.p12 -noout -passin pass:"your_password"

# Verify CER file
openssl x509 -in Runner.cer -text -noout

# Verify KEY file
openssl rsa -in Runner.key -check -noout

# Verify provisioning profile
security cms -D -i Runner.mobileprovision
```

## ✅ Benefits

1. **Maximum Compatibility**: Supports both P12 and CER+KEY formats
2. **Robust Fallback**: Graceful degradation when primary method fails
3. **Security**: Comprehensive verification of all certificate components
4. **Flexibility**: Works with various certificate sources and formats
5. **Reliability**: Detailed error handling and logging for troubleshooting
6. **Automation**: Fully automated process requiring minimal configuration

## 🎯 Best Practices

1. **Use P12 Method**: Prefer P12 certificates for simplicity and reliability
2. **Secure Storage**: Store certificates in private repositories with proper access controls
3. **Regular Updates**: Keep certificates and provisioning profiles up to date
4. **Testing**: Test both methods in development before production deployment
5. **Monitoring**: Monitor build logs for certificate-related issues
6. **Backup**: Maintain backup certificates and provisioning profiles

This fallback logic ensures your iOS builds are robust and can handle various certificate formats and configurations while maintaining security and reliability.
