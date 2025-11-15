import SwiftUI

// MARK: - Wishlist Buttons View

struct WishlistButtonsView: View {
    let card: TravelCard
    @ObservedObject var cardStore: CardStore
    @StateObject private var wishlistStore = WishlistStore()
    @State private var showingWishlistSheet = false
    @State private var selectedPriority: WishlistPriority?
    @State private var notes = ""
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 8) {
            if card.isInWishlist {
                // Show current wishlist status
                Button(action: {
                    showingWishlistSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: card.wishlistPriority?.icon ?? "bookmark.fill")
                            .font(.caption)
                        Text(card.wishlistPriority?.displayName ?? "Saved")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(card.wishlistPriority?.color ?? .blue)
                    )
                }
                .disabled(isProcessing)
            } else {
                // Show quick add buttons
                Menu {
                    ForEach(WishlistPriority.allCases, id: \.self) { priority in
                        Button(action: {
                            addToWishlist(priority: priority)
                        }) {
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .disabled(isProcessing)
            }
        }
        .sheet(isPresented: $showingWishlistSheet) {
            WishlistEditSheet(
                card: card,
                currentPriority: card.wishlistPriority,
                currentNotes: wishlistStore.getWishlistEntry(for: card.id)?.notes ?? "",
                onUpdate: { priority, notes in
                    await updateWishlist(priority: priority, notes: notes)
                },
                onRemove: {
                    await removeFromWishlist()
                }
            )
        }
        .onAppear {
            // Set up the connection between WishlistStore and CardStore
            wishlistStore.onWishlistChange = { [cardStore] cardId, isInWishlist, priority in
                cardStore.updateCardWishlistStatus(cardId: cardId, isInWishlist: isInWishlist, priority: priority)
            }
            
            Task {
                // Add a small delay to avoid race conditions with backend
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await wishlistStore.refreshWishlist()
            }
        }
    }
    
    private func addToWishlist(priority: WishlistPriority) {
        isProcessing = true
        
        Task {
            let success = await wishlistStore.addToWishlist(cardId: card.id, priority: priority)
            
            await MainActor.run {
                isProcessing = false
                if success {
                    // Show success feedback
                    print("✅ Added to wishlist: \(priority.displayName)")
                } else {
                    // Show error feedback
                    print("❌ Failed to add to wishlist")
                }
            }
        }
    }
    
    private func updateWishlist(priority: WishlistPriority?, notes: String) async {
        isProcessing = true
        
        if let wishlistEntry = wishlistStore.getWishlistEntry(for: card.id) {
            let success = await wishlistStore.updateWishlistEntry(
                wishlistId: wishlistEntry.id,
                priority: priority,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isProcessing = false
                if success {
                    print("✅ Updated wishlist entry")
                } else {
                    print("❌ Failed to update wishlist entry")
                }
            }
        }
    }
    
    private func removeFromWishlist() async {
        isProcessing = true
        
        let success = await wishlistStore.removeFromWishlist(cardId: card.id)
        
        await MainActor.run {
            isProcessing = false
            if success {
                print("✅ Removed from wishlist")
            } else {
                print("❌ Failed to remove from wishlist")
            }
        }
    }
}

// MARK: - Wishlist Edit Sheet

struct WishlistEditSheet: View {
    let card: TravelCard
    let currentPriority: WishlistPriority?
    let currentNotes: String
    let onUpdate: (WishlistPriority?, String) async -> Void
    let onRemove: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriority: WishlistPriority?
    @State private var notes: String
    @State private var isProcessing = false
    
    init(card: TravelCard, currentPriority: WishlistPriority?, currentNotes: String, onUpdate: @escaping (WishlistPriority?, String) async -> Void, onRemove: @escaping () async -> Void) {
        self.card = card
        self.currentPriority = currentPriority
        self.currentNotes = currentNotes
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        self._selectedPriority = State(initialValue: currentPriority)
        self._notes = State(initialValue: currentNotes)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Card preview
                HStack(spacing: 16) {
                    AsyncImageView(url: URL(string: card.image))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.destination_name ?? "Travel Destination")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                        
                        if let location = card.location {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Priority selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Priority Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ForEach(WishlistPriority.allCases, id: \.self) { priority in
                            Button(action: {
                                selectedPriority = priority
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: priority.icon)
                                        .font(.title3)
                                        .foregroundColor(priority.color)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(priority.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(priorityDescription(for: priority))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedPriority == priority {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(priority.color)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPriority == priority ? priority.color.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedPriority == priority ? priority.color : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Notes section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Notes (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Why do you want to visit this place?", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    // Update button
                    Button(action: {
                        Task {
                            await onUpdate(selectedPriority, notes)
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                            }
                            Text("Update Wishlist")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPriority?.color ?? .blue)
                        )
                    }
                    .disabled(isProcessing || selectedPriority == nil)
                    
                    // Remove button
                    Button(action: {
                        Task {
                            await onRemove()
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove from Wishlist")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Wishlist")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func priorityDescription(for priority: WishlistPriority) -> String {
        switch priority {
        case .mustDo:
            return "Essential stops for any trip"
        case .soundsFun:
            return "Great options if there's time"
        case .maybe:
            return "Nice-to-have if there's extra time"
        }
    }
}

// MARK: - Wishlist Profile View

struct WishlistProfileView: View {
    @StateObject private var wishlistStore = WishlistStore()
    @State private var selectedPriority: WishlistPriority? = nil
    @State private var showingEditSheet = false
    @State private var selectedEntry: WishlistEntry?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with statistics
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Wishlist")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(wishlistStore.totalCount) destinations saved")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await wishlistStore.refreshWishlist()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Priority filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All button
                            Button(action: {
                                selectedPriority = nil
                            }) {
                                HStack(spacing: 6) {
                                    Text("All")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(wishlistStore.totalCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(selectedPriority == nil ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedPriority == nil ? .blue : Color(.systemGray6))
                                )
                            }
                            
                            // Priority buttons
                            ForEach(WishlistPriority.allCases, id: \.self) { priority in
                                Button(action: {
                                    selectedPriority = priority
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: priority.icon)
                                            .font(.caption)
                                        Text(priority.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(priorityCount(for: priority))")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(selectedPriority == priority ? .white : priority.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedPriority == priority ? priority.color : priority.color.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
                
                // Wishlist content
                if wishlistStore.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading your wishlist...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No destinations saved")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Start exploring and save places you'd like to visit!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEntries) { entry in
                                WishlistCardView(entry: entry) {
                                    selectedEntry = entry
                                    showingEditSheet = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await wishlistStore.refreshWishlist()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let entry = selectedEntry {
                    WishlistEditSheet(
                        card: entry.card,
                        currentPriority: entry.priority,
                        currentNotes: entry.notes ?? "",
                        onUpdate: { priority, notes in
                            await wishlistStore.updateWishlistEntry(
                                wishlistId: entry.id,
                                priority: priority,
                                notes: notes.isEmpty ? nil : notes
                            )
                        },
                        onRemove: {
                            await wishlistStore.deleteWishlistEntry(wishlistId: entry.id)
                        }
                    )
                }
            }
        }
    }
    
    private var filteredEntries: [WishlistEntry] {
        if let priority = selectedPriority {
            return wishlistStore.getWishlistByPriority(priority)
        } else {
            return wishlistStore.wishlistEntries
        }
    }
    
    private func priorityCount(for priority: WishlistPriority) -> Int {
        switch priority {
        case .mustDo:
            return wishlistStore.mustDoCount
        case .soundsFun:
            return wishlistStore.soundsFunCount
        case .maybe:
            return wishlistStore.maybeCount
        }
    }
}

// MARK: - Wishlist Card View

struct WishlistCardView: View {
    let entry: WishlistEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Card image
                AsyncImageView(url: URL(string: entry.card.image))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                
                // Card details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.card.destination_name ?? "Travel Destination")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Priority indicator
                        HStack(spacing: 4) {
                            Image(systemName: entry.priority.icon)
                                .font(.caption)
                            Text(entry.priority.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(entry.priority.color)
                        )
                    }
                    
                    if let location = entry.card.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(entry.card.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Wishlist Preview View

struct WishlistPreviewView: View {
    @StateObject private var wishlistStore = WishlistStore()
    
    var body: some View {
        Group {
            if wishlistStore.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading wishlist...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if wishlistStore.totalCount == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No destinations saved yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start exploring and save places you'd like to visit!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 12) {
                    // Statistics row
                    HStack(spacing: 16) {
                        WishlistStatCard(
                            title: "Must Do",
                            count: wishlistStore.mustDoCount,
                            color: .red,
                            icon: "star.fill"
                        )
                        
                        WishlistStatCard(
                            title: "Sounds Fun",
                            count: wishlistStore.soundsFunCount,
                            color: .orange,
                            icon: "heart.fill"
                        )
                        
                        WishlistStatCard(
                            title: "Maybe",
                            count: wishlistStore.maybeCount,
                            color: .blue,
                            icon: "bookmark.fill"
                        )
                    }
                    
                    // Recent entries preview
                    if !wishlistStore.wishlistEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Additions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(wishlistStore.wishlistEntries.prefix(3)) { entry in
                                        WishlistPreviewCard(entry: entry)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.horizontal, -20)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await wishlistStore.refreshWishlist()
            }
        }
    }
}

// MARK: - Wishlist Stat Card

struct WishlistStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Wishlist Preview Card

struct WishlistPreviewCard: View {
    let entry: WishlistEntry
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImageView(url: URL(string: entry.card.image))
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(spacing: 2) {
                Text(entry.card.destination_name ?? "Destination")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: entry.priority.icon)
                        .font(.caption2)
                    Text(entry.priority.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(entry.priority.color)
            }
        }
        .frame(width: 80)
    }
}
