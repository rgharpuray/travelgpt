import SwiftUI

struct AddToCollectionView: View {
    let card: TravelCard
    @StateObject private var collectionStore = CollectionStore()
    @State private var showCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    @State private var isCreatingCollection = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with card preview
                VStack(spacing: 16) {
                    Text("Add to Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Card preview
                    CardPreviewView(card: card)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Collections list
                if collectionStore.isLoading {
                    Spacer()
                    ProgressView("Loading collections...")
                    Spacer()
                } else if collectionStore.userCollections.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("No Collections Yet")
                            .font(.headline)
                        
                        Text("Create your first collection to organize your favorite cards")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Create Collection") {
                            showCreateCollection = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    List {
                        Section("Your Collections") {
                            ForEach(collectionStore.userCollections) { collection in
                                CollectionRowView(
                                    collection: collection,
                                    card: card,
                                    collectionStore: collectionStore
                                )
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Collection") {
                        showCreateCollection = true
                    }
                    .disabled(collectionStore.isLoading)
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                CreateCollectionView(
                    collectionStore: collectionStore,
                    onCollectionCreated: {
                        showCreateCollection = false
                    }
                )
            }
            .task {
                await collectionStore.fetchUserCollections()
            }
        }
    }
}

struct CardPreviewView: View {
    let card: TravelCard
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
            
            VStack(spacing: 8) {
                AsyncImageView(url: URL(string: card.image))
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
                Text(card.thought ?? "No description")
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(8)
        }
    }
}

struct CollectionRowView: View {
    let collection: Collection
    let card: TravelCard
    @ObservedObject var collectionStore: CollectionStore
    @State private var isAdding = false
    @State private var isInCollection = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                
                Text(collection.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(collection.card_count) cards")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            if isAdding {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: toggleCollection) {
                    Image(systemName: isInCollection ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(isInCollection ? .green : .blue)
                        .font(.title2)
                }
                .disabled(isAdding)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // Check if card is already in this collection
            // This would need to be implemented based on your data structure
            isInCollection = false
        }
    }
    
    private func toggleCollection() {
        Task {
            isAdding = true
            
            do {
                if isInCollection {
                    try await collectionStore.removeCardFromCollection(card.id, collection.id)
                    isInCollection = false
                } else {
                    try await collectionStore.addCardToCollection(card.id, collection.id)
                    isInCollection = true
                }
            } catch {
                print("Error toggling collection: \(error)")
            }
            
            isAdding = false
        }
    }
}

struct CreateCollectionView: View {
    @ObservedObject var collectionStore: CollectionStore
    let onCollectionCreated: () -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Collection Details") {
                    TextField("Collection Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: createCollection) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Collection")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
            .navigationTitle("New Collection")
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
    
    private func createCollection() {
        Task {
            isCreating = true
            
            do {
                let request = CreateCollectionRequest(name: name, description: description)
                let _ = try await collectionStore.createUserCollection(request)
                await collectionStore.fetchUserCollections()
                onCollectionCreated()
                dismiss()
            } catch {
                print("Error creating collection: \(error)")
            }
            
            isCreating = false
        }
    }
}

#Preview {
    AddToCollectionView(card: TravelCard(
        id: 1,
        destination_name: "Paris",
                    image: "https://example.com/image.jpg",
        is_valid_destination: true,
        thought: "I wonder if the Eiffel Tower gets lonely at night...",
        created_at: "2025-01-01T00:00:00Z",
        updated_at: nil,
        like_count: 5,
        is_liked: false,
        is_owner: true,
        is_intrusive_mode: false,
        device_destination_name: "Paris",
        owner_destination_name: "Paris",
        rarity: "rare",
        collection_tags: ["European Adventures"],
        category: "Activities",
        isVerified: false,
        s3_url: "https://example.com/image.jpg",
        location: "Paris, France",
        coordinates: "48.8566,2.3522",
        admin_review_status: "approved",
        admin_reviewer_id: 1,
        admin_reviewed_at: "2025-01-01T00:00:00Z",
        admin_notes: "Great photo",
        check_in_count: 0,
        comment_count: 0,
        is_liked_by_user: false,
        is_checked_in_by_user: false,
        moods: ["romantic", "cultural"],
        user: UserResponse(id: 1, username: "traveler", first_name: "John", last_name: "Doe", email: "john@example.com")
    ))
}





