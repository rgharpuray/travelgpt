import Foundation

// MARK: - Comment Models

struct Comment: Codable, Identifiable {
    let id: String
    let cardId: String
    let userId: String
    let userEmail: String?
    let userPetName: String?
    let content: String
    let createdAt: String
    let isGuest: Bool
    let likeCount: Int
    let isLiked: Bool
    let replyCount: Int
    let parentId: String? // For replies
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardId
        case userId
        case userEmail
        case userPetName
        case content
        case createdAt
        case isGuest
        case likeCount
        case isLiked
        case replyCount
        case parentId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(String.self, forKey: .id)
        } catch {
            print("❌ Failed to decode 'id' field")
            throw error
        }
        
        do {
            cardId = try container.decode(String.self, forKey: .cardId)
        } catch {
            print("❌ Failed to decode 'cardId' field")
            throw error
        }
        
        do {
            userId = try container.decode(String.self, forKey: .userId)
        } catch {
            print("❌ Failed to decode 'userId' field")
            throw error
        }
        
        do {
            userEmail = try container.decodeIfPresent(String.self, forKey: .userEmail)
        } catch {
            print("❌ Failed to decode 'userEmail' field")
            throw error
        }
        
        do {
            userPetName = try container.decodeIfPresent(String.self, forKey: .userPetName)
        } catch {
            print("❌ Failed to decode 'userPetName' field")
            throw error
        }
        
        do {
            content = try container.decode(String.self, forKey: .content)
        } catch {
            print("❌ Failed to decode 'content' field")
            throw error
        }
        
        do {
            createdAt = try container.decode(String.self, forKey: .createdAt)
        } catch {
            print("❌ Failed to decode 'createdAt' field")
            throw error
        }
        
        do {
            // Handle boolean as integer (0/1) from backend
            if let intValue = try? container.decode(Int.self, forKey: .isGuest) {
                isGuest = intValue == 1
            } else {
                isGuest = try container.decode(Bool.self, forKey: .isGuest)
            }
        } catch {
            print("❌ Failed to decode 'isGuest' field")
            throw error
        }
        
        do {
            likeCount = try container.decode(Int.self, forKey: .likeCount)
        } catch {
            print("❌ Failed to decode 'likeCount' field")
            throw error
        }
        
        do {
            // Handle boolean as integer (0/1) from backend
            if let intValue = try? container.decode(Int.self, forKey: .isLiked) {
                isLiked = intValue == 1
            } else {
                isLiked = try container.decode(Bool.self, forKey: .isLiked)
            }
        } catch {
            print("❌ Failed to decode 'isLiked' field")
            throw error
        }
        
        do {
            replyCount = try container.decode(Int.self, forKey: .replyCount)
        } catch {
            print("❌ Failed to decode 'replyCount' field")
            throw error
        }
        
        do {
            parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        } catch {
            print("❌ Failed to decode 'parentId' field")
            throw error
        }
    }
    
    // Regular initializer for creating Comment objects manually
    init(id: String, cardId: String, userId: String, userEmail: String?, userPetName: String?, content: String, createdAt: String, isGuest: Bool, likeCount: Int, isLiked: Bool, replyCount: Int, parentId: String?) {
        self.id = id
        self.cardId = cardId
        self.userId = userId
        self.userEmail = userEmail
        self.userPetName = userPetName
        self.content = content
        self.createdAt = createdAt
        self.isGuest = isGuest
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.replyCount = replyCount
        self.parentId = parentId
    }
}

struct CreateCommentRequest: Codable {
    let cardId: String
    let content: String
    let parentId: String? // For replies
    
    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case content
        case parentId = "parent_id"
    }
}

// Backend returns the comment directly, not wrapped
struct CommentCreateResponse: Codable {
    let id: String
    let cardId: String
    let userId: String
    let userEmail: String?
    let userPetName: String?
    let content: String
    let createdAt: String
    let isGuest: Bool
    let likeCount: Int
    let isLiked: Bool
    let replyCount: Int
    let parentId: String?
    let barkbuxEarned: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardId
        case userId
        case userEmail
        case userPetName
        case content
        case createdAt
        case isGuest
        case likeCount
        case isLiked
        case replyCount
        case parentId
        case barkbuxEarned = "barkbux_earned"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        cardId = try container.decode(String.self, forKey: .cardId)
        userId = try container.decode(String.self, forKey: .userId)
        userEmail = try container.decodeIfPresent(String.self, forKey: .userEmail)
        userPetName = try container.decodeIfPresent(String.self, forKey: .userPetName)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Handle boolean as integer (0/1) from backend
        if let intValue = try? container.decode(Int.self, forKey: .isGuest) {
            isGuest = intValue == 1
        } else {
            isGuest = try container.decode(Bool.self, forKey: .isGuest)
        }
        
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        
        // Handle boolean as integer (0/1) from backend
        if let intValue = try? container.decode(Int.self, forKey: .isLiked) {
            isLiked = intValue == 1
        } else {
            isLiked = try container.decode(Bool.self, forKey: .isLiked)
        }
        
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        barkbuxEarned = try container.decodeIfPresent(Int.self, forKey: .barkbuxEarned)
    }
}

struct CommentsResponse: Codable {
    let comments: [Comment]
    let count: Int
    let next: String?
    let previous: String?
    
    // Computed property to maintain compatibility
    var total: Int { count }
    var hasMore: Bool { next != nil }
}

struct CommentReportRequest: Codable {
    let commentId: String
    let reason: String
    
    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case reason
    }
}

struct CommentReportResponse: Codable {
    let message: String
}

// MARK: - Additional Response Models

struct CommentLikeResponse: Codable {
    let liked: Bool
    let likeCount: Int
    let barkbuxEarned: Int?
    
    enum CodingKeys: String, CodingKey {
        case liked
        case likeCount
        case barkbuxEarned = "barkbux_earned"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        print("🔍 Decoding CommentLikeResponse...")
        
        // Handle boolean as integer (0/1) from backend
        do {
            if let intValue = try? container.decode(Int.self, forKey: .liked) {
                liked = intValue == 1
                print("✅ Decoded 'liked' as integer: \(intValue) -> \(liked)")
            } else {
                liked = try container.decode(Bool.self, forKey: .liked)
                print("✅ Decoded 'liked' as boolean: \(liked)")
            }
        } catch {
            print("❌ Failed to decode 'liked' field: \(error)")
            throw error
        }
        
        do {
            likeCount = try container.decode(Int.self, forKey: .likeCount)
            print("✅ Decoded 'likeCount' (like_count): \(likeCount)")
        } catch {
            print("❌ Failed to decode 'likeCount' field: \(error)")
            throw error
        }
        
        do {
            barkbuxEarned = try container.decodeIfPresent(Int.self, forKey: .barkbuxEarned)
            print("✅ Decoded 'barkbuxEarned': \(barkbuxEarned ?? 0)")
        } catch {
            print("❌ Failed to decode 'barkbuxEarned' field: \(error)")
            barkbuxEarned = nil
        }
        
        print("✅ CommentLikeResponse decoded successfully")
    }
}

struct CommentDeleteResponse: Codable {
    let message: String
}

struct CommentCountResponse: Codable {
    let count: Int
}

// MARK: - Comment Store

class CommentStore: ObservableObject {
    @Published var comments: [String: [Comment]] = [:] // cardId -> comments
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var commentCounts: [String: Int] = [:] // cardId -> count

    
    // Cache for API responses
    private var commentCache: [String: [Comment]] = [:]
    private var countCache: [String: Int] = [:]
    
    init() {
        // No longer loading mock data - will load from API when needed
    }
    
    @MainActor
    func addComment(to cardId: String, content: String, parentId: String? = nil) async {
        guard let cardIdInt = Int(cardId) else {
            errorMessage = "Invalid card ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await BackendService.shared.createComment(for: cardIdInt, content: content, parentId: parentId)
            
            // Convert CommentCreateResponse to Comment
            let newComment = Comment(
                id: response.id,
                cardId: response.cardId,
                userId: response.userId,
                userEmail: response.userEmail,
                userPetName: response.userPetName,
                content: response.content,
                createdAt: response.createdAt,
                isGuest: response.isGuest,
                likeCount: response.likeCount,
                isLiked: response.isLiked,
                replyCount: response.replyCount,
                parentId: response.parentId
            )
            
            // Add the new comment to our cache
            if commentCache[cardId] == nil {
                commentCache[cardId] = []
            }
            commentCache[cardId]?.append(newComment)
            
            // Update the published property
            comments[cardId] = commentCache[cardId] ?? []
            
            // Refresh comment count
            await refreshCommentCount(for: cardId)
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error adding comment: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func toggleLike(for commentId: String, cardId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Toggling like for comment \(commentId) on card \(cardId)")
            let response = try await BackendService.shared.toggleCommentLike(commentId: commentId)
            print("✅ Like response received: liked=\(response.liked), count=\(response.likeCount)")
            
            // Update the comment in our cache
            if let commentIndex = commentCache[cardId]?.firstIndex(where: { $0.id == commentId }) {
                let updatedComment = commentCache[cardId]![commentIndex]
                let newComment = Comment(
                    id: updatedComment.id,
                    cardId: updatedComment.cardId,
                    userId: updatedComment.userId,
                    userEmail: updatedComment.userEmail,
                    userPetName: updatedComment.userPetName,
                    content: updatedComment.content,
                    createdAt: updatedComment.createdAt,
                    isGuest: updatedComment.isGuest,
                    likeCount: response.likeCount,
                    isLiked: response.liked,
                    replyCount: updatedComment.replyCount,
                    parentId: updatedComment.parentId
                )
                
                print("🔄 Updating comment in cache: old likeCount=\(updatedComment.likeCount), new likeCount=\(response.likeCount)")
                print("🔄 Old isLiked=\(updatedComment.isLiked), new isLiked=\(response.liked)")
                
                commentCache[cardId]?[commentIndex] = newComment
                comments[cardId] = commentCache[cardId] ?? []
                
                print("✅ Comment updated successfully in UI")
            } else {
                print("⚠️ Comment not found in cache for card \(cardId)")
                // Refresh comments to get updated state
                await fetchComments(for: cardId)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error toggling comment like: \(error)")
            print("❌ Error details: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func reportComment(commentId: String, reason: String) async {
        print("📝 Reporting comment \(commentId) with reason: \(reason)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await BackendService.shared.reportComment(commentId: commentId, reason: reason)
            print("✅ Comment report submitted successfully: \(response.message)")
            errorMessage = "Report submitted successfully"
        } catch {
            print("❌ Error reporting comment: \(error)")
            errorMessage = error.localizedDescription
        }
        
        // Clear the message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.errorMessage = nil
        }
        
        isLoading = false
    }
    
    func getComments(for cardId: String) -> [Comment] {
        return commentCache[cardId] ?? []
    }
    
    func getTopLevelComments(for cardId: String) -> [Comment] {
        return getComments(for: cardId).filter { $0.parentId == nil }
    }
    

    
    @MainActor
    func fetchComments(for cardId: String, page: Int = 1, limit: Int = 20) async {
        guard let cardIdInt = Int(cardId) else {
            errorMessage = "Invalid card ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await BackendService.shared.fetchComments(for: cardIdInt, page: page, limit: limit)
            
            // Cache the comments
            commentCache[cardId] = response.comments
            comments[cardId] = response.comments
            
            // Update comment count
            commentCounts[cardId] = response.total
            
            // Clear any previous error since we successfully loaded comments
            errorMessage = nil
            
        } catch {
            // Show the actual error so we can debug what's happening
            errorMessage = error.localizedDescription
            print("❌ Error fetching comments: \(error)")
            
            // Log more details for debugging
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error description: \(nsError.localizedDescription)")
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshCommentCount(for cardId: String) async {
        guard let cardIdInt = Int(cardId) else { return }
        
        do {
            let response = try await BackendService.shared.getCommentCount(for: cardIdInt)
            commentCounts[cardId] = response.count
        } catch {
            // Silently handle comment count errors - don't show to user
            // Just log for debugging
            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain {
                    print("🌐 Comment count - backend not available yet: \(error)")
                } else {
                    print("❌ Error fetching comment count: \(error)")
                }
            } else {
                print("❌ Error fetching comment count: \(error)")
            }
        }
    }
    
    func getCommentCount(for cardId: String) -> Int {
        return commentCounts[cardId] ?? 0
    }
}
