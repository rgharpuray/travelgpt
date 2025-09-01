import SwiftUI

// MARK: - Comment Button Component

struct CommentButton: View {
    let cardId: String
    let commentCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 16, weight: .medium))
                
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comment Input Component

struct CommentInputView: View {
    let cardId: String
    @State private var commentText = ""
    @State private var isSubmitting = false
    @EnvironmentObject var commentStore: CommentStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Add Comment")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Comment input
            VStack(alignment: .leading, spacing: 8) {
                Text("Your comment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $commentText)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    )
                    .overlay(
                        Group {
                            if commentText.isEmpty {
                                Text("Share your thoughts about this dog's thoughts...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .padding(.horizontal)
            
            // Submit button
            Button(action: submitComment) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Post Comment")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(commentText.isEmpty ? Color.gray : Color.blue)
                )
                .foregroundColor(.white)
            }
            .disabled(commentText.isEmpty || isSubmitting)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        
        // Add comment to store
        Task {
            await commentStore.addComment(to: cardId, content: commentText.trimmingCharacters(in: .whitespacesAndNewlines), parentId: nil)
            
            await MainActor.run {
                // Reset and dismiss
                commentText = ""
                isSubmitting = false
                dismiss()
            }
        }
    }
}

// MARK: - Comment List Component

struct CommentListView: View {
    let cardId: String
    @EnvironmentObject var commentStore: CommentStore
    @State private var showCommentInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Add Comment") {
                    showCommentInput = true
                }
                .foregroundColor(.blue)
                .font(.system(size: 14, weight: .medium))
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Comments list
            ScrollView {
                LazyVStack(spacing: 0) {
                    let topLevelComments = commentStore.getTopLevelComments(for: cardId)
                    
                    if commentStore.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading comments...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if let errorMessage = commentStore.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Error Loading Comments")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button("Retry") {
                                Task {
                                    await commentStore.fetchComments(for: cardId)
                                }
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 40)
                    } else if topLevelComments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No comments yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Be the first to share your thoughts!")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(topLevelComments) { comment in
                            CommentRowView(comment: comment, cardId: cardId)
                            
                            if comment.id != topLevelComments.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showCommentInput) {
            CommentInputView(cardId: cardId)
                .environmentObject(commentStore)
        }
        .onAppear {
            // Fetch comments when view appears
            Task {
                await commentStore.fetchComments(for: cardId)
            }
        }
        .alert("Error", isPresented: .constant(commentStore.errorMessage != nil)) {
            Button("OK") {
                commentStore.errorMessage = nil
            }
        } message: {
            if let errorMessage = commentStore.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Comment Row Component

struct CommentRowView: View {
    let comment: Comment
    let cardId: String
    @EnvironmentObject var commentStore: CommentStore
    @State private var showReportSheet = false
    

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(userInitials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    )
                
                // Comment content
                VStack(alignment: .leading, spacing: 8) {
                    // User info
                    HStack {
                        Text(userDisplayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if comment.isGuest {
                            Text("Guest")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                )
                        }
                        
                        Spacer()
                        
                        Text(timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Comment text
                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Like button
                        Button(action: {
                            Task {
                                await commentStore.toggleLike(for: comment.id, cardId: cardId)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                    .foregroundColor(comment.isLiked ? .red : .secondary)
                                Text("\(comment.likeCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Report button
                        Button(action: {
                            showReportSheet = true
                        }) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .actionSheet(isPresented: $showReportSheet) {
            ActionSheet(
                title: Text("Report Comment"),
                message: Text("Why are you reporting this comment?"),
                buttons: [
                    .destructive(Text("Inappropriate Content")) {
                        Task {
                            await commentStore.reportComment(commentId: comment.id, reason: "Inappropriate Content")
                        }
                    },
                    .destructive(Text("Spam")) {
                        Task {
                            await commentStore.reportComment(commentId: comment.id, reason: "Spam")
                        }
                    },
                    .destructive(Text("Harassment")) {
                        Task {
                            await commentStore.reportComment(commentId: comment.id, reason: "Harassment")
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var userDisplayName: String {
        // For logged-in users (not guests), show pet name if available
        if !comment.isGuest {
            if let petName = comment.userPetName, !petName.isEmpty {
                return petName
            } else if let email = comment.userEmail {
                return email.components(separatedBy: "@").first ?? "User"
            }
        }
        // For guest users, show "Guest User"
        return "Guest User"
    }
    
    private var userInitials: String {
        let name = userDisplayName
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: comment.createdAt) else {
            // Try alternative date formats if ISO8601 fails
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let formatter3 = DateFormatter()
            formatter3.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let alternativeFormatters = [formatter1, formatter2, formatter3]
            
            for formatter in alternativeFormatters {
                if let date = formatter.date(from: comment.createdAt) {
                    return formatTimeAgo(from: date)
                }
            }
            
            // If all parsing fails, return a fallback
            return "Recently"
        }
        
        return formatTimeAgo(from: date)
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}



#Preview {
    CommentListView(cardId: "mock_card_1")
        .environmentObject(CommentStore())
}
