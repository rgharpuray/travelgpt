# BarkGPT Authentication System

## Overview

BarkGPT now supports a comprehensive authentication system that allows users to optionally register and login while maintaining the existing device-based functionality. The system supports both device ID and token-based authentication seamlessly.

## Features

### 🔐 Authentication Methods
- **Device ID Authentication**: Default method for guest users
- **Token Authentication**: For registered users with accounts
- **Automatic Fallback**: Seamless switching between authentication methods

### 👤 User Management
- **Guest Mode**: Users can continue using the app without registration
- **Account Registration**: Email/password registration with optional pet name
- **Account Login**: Secure login with token-based authentication
- **Session Persistence**: Tokens stored securely in Keychain
- **Automatic Token Refresh**: Handles expired tokens automatically

### 💎 Premium Features
- **Premium Status**: Track user premium subscription status
- **Unlimited Generations**: Premium users get unlimited daily generations
- **Premium UI Indicators**: Crown icon for premium users
- **Upgrade Prompts**: Non-premium users see upgrade options

## Architecture

### Core Components

#### 1. AuthService (`BarkGPT/Services/AuthService.swift`)
- Singleton service managing authentication state
- Handles login, registration, logout, and token refresh
- Secure token storage using KeychainWrapper
- Observable authentication state management

#### 2. NetworkManager (`BarkGPT/Utilities/NetworkManager.swift`)
- Enhanced to support both authentication methods
- Automatic fallback from token to device ID authentication
- Three request creation methods:
  - `createRequest()`: Automatic authentication method selection
  - `createAuthenticatedRequest()`: Token-only requests
  - `createDeviceRequest()`: Device ID-only requests

#### 3. BackendService (`BarkGPT/Services/BackendService.swift`)
- Updated profile methods to support both authentication methods
- Automatic token refresh on 401 responses
- Seamless switching between auth methods

#### 4. Authentication Models (`BarkGPT/Models/AuthModels.swift`)
- Request/response models for authentication
- User model with premium status
- Authentication state and error handling

### Authentication Flow

```
1. App Launch
   ├── Check for stored tokens
   ├── If tokens exist → Load user session
   └── If no tokens → Guest mode

2. API Requests
   ├── Try token authentication first
   ├── If 401 → Attempt token refresh
   ├── If refresh fails → Fallback to device ID
   └── If device ID fails → Show error

3. User Registration/Login
   ├── Validate credentials
   ├── Store tokens securely
   ├── Update authentication state
   └── Refresh UI
```

## API Endpoints

### Authentication Endpoints
```
POST /auth/register/     - User registration
POST /auth/login/        - User login
POST /auth/logout/       - User logout
POST /auth/refresh/      - Token refresh
```

### Profile Endpoints (Dual Auth Support)
```
GET  /barkgpt/profile/           - Get profile (token or device_id)
POST /barkgpt/profile/update/    - Update profile (token or device_id)
POST /barkgpt/profile/upload_image/ - Upload image (token or device_id)
```

## UI Components

### Authentication Views
- **LoginView**: Clean login interface with guest option
- **RegisterView**: Registration form with validation
- **AccountManagementView**: Account settings and premium upgrade

### Profile Integration
- **ProfileView**: Updated to show authentication status
- **Premium Indicators**: Crown icon for premium users
- **Upgrade Prompts**: Premium feature promotion

## Security Features

### Token Management
- **Secure Storage**: Tokens stored in iOS Keychain
- **Automatic Refresh**: Handles token expiration
- **Session Cleanup**: Proper logout and token removal

### Data Protection
- **HTTPS Only**: All API calls use secure connections
- **Token Validation**: Server-side token verification
- **Error Handling**: Graceful fallback on auth failures

## Premium Features

### Premium Status
- **Unlimited Generations**: No daily limits for premium users
- **Priority Processing**: Faster image processing
- **Premium Themes**: Enhanced UI themes
- **Ad-Free Experience**: No advertisements

### Premium UI
- **Crown Icon**: Visual indicator for premium users
- **Unlimited Counter**: Shows "999" instead of daily count
- **Upgrade Prompts**: Strategic placement of upgrade options

## Implementation Notes

### Dependencies
```swift
// Added to Package.swift
.package(url: "https://github.com/jrendel/SwiftKeychainWrapper", from: "4.0.1")
```

### Key Features
1. **Backward Compatibility**: Existing device-based users continue working
2. **Seamless Migration**: Users can register without losing data
3. **Flexible Authentication**: Supports both auth methods simultaneously
4. **Premium Integration**: Ready for subscription management

### Error Handling
- **Network Errors**: Graceful fallback to device authentication
- **Token Expiration**: Automatic refresh with user notification
- **Invalid Credentials**: Clear error messages
- **Server Errors**: Appropriate error states

## Future Enhancements

### Planned Features
- **Social Login**: Apple, Google, Facebook integration
- **Password Reset**: Email-based password recovery
- **Account Deletion**: User account removal
- **Subscription Management**: In-app purchase integration
- **Data Migration**: Device to account data transfer

### Backend Requirements
- **JWT Tokens**: Secure token generation and validation
- **User Database**: User account storage and management
- **Premium Tracking**: Subscription status management
- **Data Association**: Link device data to user accounts

## Testing

### Authentication Scenarios
1. **Guest Mode**: Verify device ID authentication works
2. **Registration**: Test new account creation
3. **Login**: Verify existing account access
4. **Token Refresh**: Test automatic token renewal
5. **Logout**: Verify session cleanup
6. **Premium Features**: Test premium status integration

### Edge Cases
- **Network Failures**: Test offline behavior
- **Token Expiration**: Verify refresh flow
- **Invalid Tokens**: Test error handling
- **Concurrent Requests**: Verify thread safety

## Usage Examples

### Basic Authentication Check
```swift
if AuthService.shared.isAuthenticated {
    // User is logged in
    let user = AuthService.shared.currentUser
    if user?.is_premium == true {
        // Premium user - unlimited access
    }
} else {
    // Guest user - daily limits apply
}
```

### Making Authenticated Requests
```swift
// NetworkManager automatically handles authentication
let request = NetworkManager.shared.createRequest(url: url, method: "GET")
// Uses token if available, falls back to device ID
```

### Premium Feature Check
```swift
if AuthService.shared.isPremium {
    // Show unlimited UI
    return 999 // Unlimited generations
} else {
    // Show daily limit UI
    return dailyLimit - usedCount
}
```

This authentication system provides a solid foundation for user management while maintaining the simplicity and accessibility of the original device-based approach. 