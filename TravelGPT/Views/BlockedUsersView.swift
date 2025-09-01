import SwiftUI

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showUnblockAlert = false
    @State private var userToUnblock: BlockedUser?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading blocked users...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Blocked Users")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            loadBlockedUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("No Blocked Users")
                            .font(.headline)
                        
                        Text("You haven't blocked any users yet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(Array(blockedUsers.enumerated()), id: \.element.device_id) { index, user in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(getUserDisplayName(user, index: index))
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                Button("Unblock") {
                                    userToUnblock = user
                                    showUnblockAlert = true
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadBlockedUsers()
        }
        .alert("Unblock User", isPresented: $showUnblockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unblock", role: .destructive) {
                if let user = userToUnblock {
                    unblockUser(user)
                }
            }
        } message: {
            if let user = userToUnblock {
                if let index = blockedUsers.firstIndex(where: { $0.device_id == user.device_id }) {
                    Text("Are you sure you want to unblock \(getUserDisplayName(user, index: index))? You will start seeing their posts again.")
                } else {
                    Text("Are you sure you want to unblock this user? You will start seeing their posts again.")
                }
            }
        }
    }
    
    private func formatPetName(_ petName: String) -> String {
        if petName.isEmpty {
            return "Unknown User"
        }
        
        let lettersToShow = min(3, petName.count)
        let visibleLetters = String(petName.prefix(lettersToShow))
        let asterisks = String(repeating: "*", count: 3)
        return visibleLetters + asterisks
    }
    
    private func getUserDisplayName(_ user: BlockedUser, index: Int) -> String {
        if user.destination_name.isEmpty {
            return "User \(index + 1)"
        }
        return formatPetName(user.destination_name)
    }
    
    private func loadBlockedUsers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await BackendService.shared.getBlockedUsers()
                await MainActor.run {
                    self.blockedUsers = response.blocked_users
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func unblockUser(_ user: BlockedUser) {
        Task {
            do {
                let response = try await BackendService.shared.unblockUser(blockedUserId: user.device_id)
                print("✅ User unblocked successfully: \(response.message)")
                
                // Remove the user from the local list
                await MainActor.run {
                    blockedUsers.removeAll { $0.device_id == user.device_id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to unblock user: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    BlockedUsersView()
} 