# 🚀 TravelGPT iOS Backend Integration

## 📱 **Overview**

This document explains how the iOS app integrates with the new TravelGPT backend API. The app has been updated to use the new API specification while maintaining backward compatibility.

## 🔌 **New API Service**

### **TravelCardAPIService**
- **Location**: `TravelGPT/Services/TravelCardAPIService.swift`
- **Purpose**: Handles all communication with the new backend API
- **Features**: 
  - Travel card CRUD operations
  - Check-ins
  - Comments and likes
  - Collections
  - Admin review system
  - Travel moods

## 🏗 **Updated Models**

### **TravelCard Model**
The `TravelCard` model has been extended with new fields from the API:

```swift
// New fields added:
let s3_url: String?
let location: String?
let coordinates: String?
let admin_review_status: String?
let admin_reviewer_id: Int?
let admin_reviewed_at: String?
let admin_notes: String?
let check_in_count: Int?
let comment_count: Int?
let is_liked_by_user: Bool?
let is_checked_in_by_user: Bool?
let moods: [String]?
let user: UserResponse?
```

### **New Models Created**
- `UserResponse`: User information from API
- `CheckInResponse`: Check-in data
- `CommentResponse`: Comment data
- `CollectionResponse`: Collection data
- `TravelMoodResponse`: Travel mood data
- `AdminStatsResponse`: Admin statistics

## 🔄 **Updated CardStore**

The `CardStore` has been updated to use the new API service:

- **Feed Loading**: Now uses `TravelCardAPIService.shared.getCards()`
- **My Cards**: Uses `TravelCardAPIService.shared.getMyCards()`
- **Pagination**: Supports the new paginated response format
- **Error Handling**: Improved error handling for API responses

## ✨ **New Features**

### **1. Card Creation**
- **Location**: `TravelGPT/ContentView.swift` - `CardCreationFormView`
- **Features**:
  - Photo upload with compression
  - Category selection
  - Location and coordinates
  - Admin review workflow
- **API**: `POST /api/travel/cards/`

### **2. Check-ins**
- **Location**: `TravelGPT/Views/CheckInView.swift`
- **Features**:
  - Photo upload (optional)
  - Caption (optional)
  - Coordinates (optional)
- **API**: `POST /api/travel/cards/{id}/check-in/`

### **3. Admin Review System**
- **Location**: `TravelGPT/Views/AdminReviewView.swift`
- **Features**:
  - View pending/approved/rejected cards
  - Approve or reject cards with notes
  - Admin statistics
- **API**: 
  - `GET /api/travel/admin/cards/review/`
  - `PUT /api/travel/admin/cards/{id}/review/`
  - `GET /api/travel/admin/stats/`

## ⚙️ **Configuration**

### **Config.swift**
Updated configuration file with API settings:

```swift
struct Config {
    static let apiBaseURL = "https://yourdomain.com/api/travel"
    static let apiTimeout: TimeInterval = 30.0
    static let imageCompressionQuality: CGFloat = 0.8
    static let defaultPageSize = 20
    // ... more settings
}
```

## 🔐 **Authentication**

The API service supports two authentication methods:

1. **JWT Token**: Primary method for authenticated users
2. **Device ID**: Fallback for guest users

```swift
private func getAuthHeaders() async -> [String: String] {
    var headers: [String: String] = [:]
    
    if let token = AuthService.shared.accessToken {
        headers["Authorization"] = "Bearer \(token)"
    } else if let deviceID = DeviceIDService.shared.deviceID {
        headers["X-Device-ID"] = deviceID
    }
    
    return headers
}
```

## 📊 **Data Flow**

### **Card Creation Flow**
1. User selects photo and fills form
2. App uploads to `POST /api/travel/cards/`
3. Card gets `admin_review_status: "pending"`
4. Admin reviews in `AdminReviewView`
5. Once approved, card appears in public feed

### **Feed Loading Flow**
1. App calls `GET /api/travel/cards/` with filters
2. Receives paginated response
3. Updates `CardStore.cards` array
4. UI refreshes with new data

### **Check-in Flow**
1. User taps check-in on a card
2. App shows `CheckInView`
3. User optionally adds photo and caption
4. App calls `POST /api/travel/cards/{id}/check-in/`
5. Check-in appears on the card

## 🚨 **Error Handling**

The API service includes comprehensive error handling with custom error types for network and server issues.

## 🔧 **Testing**

### **Sample Data**
The app includes updated sample cards with all new fields for testing:

- Barcelona locations (Montserrat, Sagrada Familia, etc.)
- Admin review statuses
- User information
- Coordinates and categories

### **Preview Support**
All new views include SwiftUI previews for development.

## 📱 **UI Updates**

### **Card Display**
- Shows admin review status
- Displays user information
- Shows check-in and comment counts
- Supports new mood system

### **Navigation**
- Card creation accessible from navbar
- Check-in accessible from card actions
- Admin review accessible from settings (if admin)

## 🚀 **Next Steps**

1. **Update Base URL**: Change `Config.apiBaseURL` to your actual backend URL
2. **Test API Endpoints**: Verify all endpoints work with your backend
3. **Admin Access**: Implement admin user detection
4. **Real-time Updates**: Add push notifications for admin approvals
5. **Offline Support**: Implement card caching for offline viewing

## 📚 **API Documentation**

For complete API documentation, see the main `README.md` file in the project root.

## 🐛 **Troubleshooting**

### **Common Issues**
1. **Compilation Errors**: Ensure all new files are added to the Xcode project
2. **API Errors**: Check the base URL in `Config.swift`
3. **Authentication**: Verify JWT token or device ID is available
4. **Image Upload**: Check image compression and size limits

### **Debug Mode**
Enable API logging in `Config.swift`:
```swift
static let enableAPILogging = true
static let enableNetworkLogging = true
```

---

**Ready to test?** Update the base URL and start creating travel cards! 🎉

