import Foundation

struct Config {
    // MARK: - API Configuration
    static let apiBaseURL = "https://yourdomain.com/api/travel"
    static let apiTimeout: TimeInterval = 30.0
    
    // MARK: - AWS S3 Configuration
    static let s3BucketName = "your-s3-bucket-name"
    static let awsAccessKey = "your-aws-access-key"
    static let awsSecretKey = "your-aws-secret-key"
    static let s3Region = "us-east-1"
    
    // MARK: - Subscription Configuration
    static let premiumMonthlyProductID = "com.travelgpt.premium.monthly"
    static let premiumYearlyProductID = "com.travelgpt.premium.yearly"
    static let isDevelopmentMode = true
    
    // MARK: - Image Configuration
    static let imageCompressionQuality: CGFloat = 0.8
    static let maxImageSize: Int = 10 * 1024 * 1024 // 10MB
    
    // MARK: - Pagination
    static let defaultPageSize = 20
    static let maxPageSize = 100
    
    // MARK: - Retry Configuration
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 2.0
    
    // MARK: - Cache Configuration
    static let imageCacheSize = 100 * 1024 * 1024 // 100MB
    static let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // MARK: - Feature Flags
    static let enableAdminReview = true
    static let enableCollections = true
    static let enableCheckIns = true
    static let enableComments = true
    
    // MARK: - Environment
    static let isDevelopment = true
    static let isProduction = false
    
    // MARK: - Debug Configuration
    static let enableAPILogging = true
    static let enableNetworkLogging = true
}
