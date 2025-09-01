import Foundation

enum Config {
    static let openAIApiKey = "YOUR_OPENAI_API_KEY"
    static let awsAccessKey = "YOUR_AWS_ACCESS_KEY"
    static let awsSecretKey = "YOUR_AWS_SECRET_KEY"
    static let s3BucketName = "YOUR_S3_BUCKET_NAME"
    
    // S3 Configuration
    static let s3Region = "us-east-1"
    
    // In-App Purchase Configuration
    static let premiumMonthlyProductID = "com.argosventures.travelgpt.premium.monthly"
    
    // Development Mode (set to false for production with real subscriptions)
    static let isDevelopmentMode = false
}
