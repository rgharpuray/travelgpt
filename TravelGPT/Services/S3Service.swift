import Foundation
import AWSS3

class S3Service {
    static let shared = S3Service()
    private let bucketName = Config.s3BucketName
    
    private init() {
        // Configure AWS
        let credentialsProvider = AWSStaticCredentialsProvider(
            accessKey: Config.awsAccessKey,
            secretKey: Config.awsSecretKey
        )
        
        let configuration = AWSServiceConfiguration(
            region: .USEast1,
            credentialsProvider: credentialsProvider
        )
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        let transferUtility = AWSS3TransferUtility.default()
        
        return try await withCheckedThrowingContinuation { continuation in
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = { _, _ in }
            
            transferUtility.uploadData(
                imageData,
                bucket: bucketName,
                key: fileName,
                contentType: "image/jpeg",
                expression: expression
            ) { task, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let url = "https://\(self.bucketName).s3.amazonaws.com/\(fileName)"
                continuation.resume(returning: url)
            }
        }
    }
} 