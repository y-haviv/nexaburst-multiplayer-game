# Security Policy

## Overview

NexaBurst is a **portfolio/educational project** designed to demonstrate professional development practices, including security-conscious design patterns.

## Security Principles

### What We Protect

✅ **Never Committed to Repository:**
- Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`)
- API keys and secrets (OpenAI, translation services, etc.)
- Local build artifacts and cache
- IDE and OS-specific files
- Keystores and signing credentials
- Database credentials
- Environment-specific configurations

✅ **Security Best Practices Implemented:**
- Environment variables for sensitive configuration (`.env` files)
- `.gitignore` properly configured for all sensitive paths
- Firebase security rules (when deployed)
- Input validation and sanitization
- Secure storage of user credentials (`flutter_secure_storage`)
- OAuth-based authentication where applicable

### Configuration Files

The repository requires these files to run fully with Firebase:

**Android** (`nexaburst/android/app/google-services.json`):
```json
// Download from Firebase Console for your Android project
// Place in: nexaburst/android/app/
```

**iOS** (`nexaburst/ios/Runner/GoogleService-Info.plist`):
```
// Download from Firebase Console for your iOS project
// Place in: nexaburst/ios/Runner/
```

**Python Scripts** (`appendices/helper_scripts/.env`):
```env
OPENAI_API_KEY=your_openai_api_key_here
# Add other service keys as needed
```

## Reporting Security Issues

### Do Not Open Public Issues

If you discover a security vulnerability:
1. **Do NOT** create a public GitHub issue
2. **Do NOT** discuss the vulnerability publicly
3. **Do NOT** include sensitive information in communications

### How to Report

**Option 1: GitHub Security Advisory**
- If available on this repository, use the "Report a vulnerability" feature
- This creates a private security advisory

**Option 2: Direct Contact**
- Contact through the GitHub profile associated with this project
- Include:
  - Description of the vulnerability
  - Steps to reproduce (if applicable)
  - Potential impact
  - Suggested fix (if you have one)
  - Your name and contact info

## Security Considerations for Users

### If Using Code from This Project

⚠️ **Important Notes:**

1. **Credentials Management**
   - Never commit real credentials
   - Always use environment variables
   - Use `.env.example` templates for setup instructions

2. **Firebase Setup**
   - Each deployment should use its own Firebase project
   - Configure appropriate security rules
   - Enable two-factor authentication on Firebase Console

3. **API Integration**
   - OpenAI API keys should never be exposed on frontend
   - Consider backend API wrapper for external service calls
   - Implement rate limiting on API endpoints

4. **Mobile Security**
   - Use secure storage for sensitive app data
   - Validate SSL certificates
   - Implement proper authentication flows

5. **Production Deployment**
   - Don't use debug certificates
   - Enable ProGuard/R8 for Android obfuscation
   - Strip debug symbols from iOS builds
   - Implement proper error logging without sensitive data

## Testing & Validation

This project includes security-conscious patterns:

```dart
// Example: Secure credential storage
final secureStorage = FlutterSecureStorage();
await secureStorage.write(key: 'auth_token', value: token);

// Example: Environment-based configuration
String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
```

## Dependencies & Updates

### Regular Updates
We recommend keeping dependencies updated:

```bash
# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Check for security vulnerabilities
flutter pub audit
```

### Known Issues
- None currently documented

If you identify a vulnerable dependency, please report it privately.

## Compliance & Standards

This project follows:
- **OWASP Mobile Security** guidelines
- **Flutter Security Best Practices**
- **Firebase Security Recommendations**
- **PEP 8** for Python code

## Contact

For security matters, please use the **GitHub Security Advisory** feature on this repository if available, or contact through the GitHub profile associated with this project.

**Note:** This is a portfolio project. While security best practices are demonstrated, do not use for production without thorough security audits and proper credential management setup specific to your deployment environment.
