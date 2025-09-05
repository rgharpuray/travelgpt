import SwiftUI

struct AdminReviewView: View {
    @StateObject private var adminStore = AdminReviewStore()
    @State private var selectedStatus: String = "pending"
    @State private var currentPage = 1
    @State private var showReviewSheet = false
    @State private var selectedCard: TravelCard?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status filter
                Picker("Status", selection: $selectedStatus) {
                    Text("Pending").tag("pending")
                    Text("Approved").tag("approved")
                    Text("Rejected").tag("rejected")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Cards list
                if adminStore.isLoading {
                    Spacer()
                    ProgressView("Loading cards...")
                    Spacer()
                } else if adminStore.cards.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("No \(selectedStatus) cards")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("All caught up!")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(adminStore.cards) { card in
                        AdminCardRow(card: card) {
                            selectedCard = card
                            showReviewSheet = true
                        }
                    }
                    .refreshable {
                        await adminStore.loadCards(status: selectedStatus, page: 1)
                    }
                }
            }
            .navigationTitle("Admin Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stats") {
                        Task {
                            await adminStore.loadStats()
                        }
                    }
                }
            }
            .onChange(of: selectedStatus) { _ in
                Task {
                    await adminStore.loadCards(status: selectedStatus, page: 1)
                }
            }
            .onAppear {
                Task {
                    await adminStore.loadCards(status: selectedStatus, page: 1)
                }
            }
            .sheet(isPresented: $showReviewSheet) {
                if let card = selectedCard {
                    AdminCardReviewSheet(card: card) { action, notes in
                        Task {
                            await adminStore.reviewCard(cardId: card.id, action: action, notes: notes)
                            await adminStore.loadCards(status: selectedStatus, page: 1)
                        }
                    }
                }
            }
        }
    }
}

struct AdminCardRow: View {
    let card: TravelCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: card.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.destination_name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(card.thought ?? "No description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                       /* Text(card.user?.displayName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)*/
                        
                        Spacer()
                        
                        Text(card.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminCardReviewSheet: View {
    let card: TravelCard
    let onReview: (String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                                    // Card image
                AsyncImage(url: URL(string: card.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Card details
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Destination")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(card.destination_name ?? "Unknown Location")
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Thought")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(card.thought ?? "No description")
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(card.category ?? "Unknown")
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("User")
                                .font(.headline)
                                .fontWeight(.semibold)
                           /* Text(card.user?.displayName ?? "Unknown")
                                .font(.body)*/
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextField("Add review notes...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Reject") {
                            submitReview(action: "reject")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(isSubmitting)
                        
                        Button("Approve") {
                            submitReview(action: "approve")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isSubmitting)
                    }
                    .padding()
                }
            }
            .navigationTitle("Review Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReview(action: String) {
        isSubmitting = true
        onReview(action, notes.isEmpty ? nil : notes)
        dismiss()
    }
}

@MainActor
class AdminReviewStore: ObservableObject {
    @Published var cards: [TravelCard] = []
    @Published var isLoading = false
    @Published var stats: AdminStatsResponse?
    
    func loadCards(status: String, page: Int) async {
        isLoading = true
        do {
            let response = try await TravelCardAPIService.shared.getCardsForReview(
                status: status,
                page: page,
                pageSize: Config.defaultPageSize
            )
            cards = response.results
        } catch {
            print("Error loading admin cards: \(error)")
        }
        isLoading = false
    }
    
    func reviewCard(cardId: Int, action: String, notes: String?) async {
        do {
            try await TravelCardAPIService.shared.reviewCard(
                cardId: cardId,
                action: action,
                notes: notes
            )
        } catch {
            print("Error reviewing card: \(error)")
        }
    }
    
    func loadStats() async {
        do {
            stats = try await TravelCardAPIService.shared.getAdminStats()
        } catch {
            print("Error loading admin stats: \(error)")
        }
    }
}

#Preview {
    AdminReviewView()
}
