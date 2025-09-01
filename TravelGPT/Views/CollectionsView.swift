import SwiftUI

struct CollectionsView: View {
    @StateObject private var collectionStore = CollectionStore()
    @State private var showCreateCollection = false
    @State private var selectedCollection: Collection?
    @State private var showCollectionDetail = false
    
    var body: some View {
        NavigationStack {
            Group {
                if collectionStore.isLoading {
                    ProgressView("Loading collections...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if collectionStore.userCollections.isEmpty {
                    EmptyCollectionsView(showCreateCollection: $showCreateCollection)
                } else {
                    CollectionsListView(
                        collections: collectionStore.userCollections,
                        onCollectionTapped: { collection in
                            selectedCollection = collection
                            showCollectionDetail = true
                        },
                        onDeleteCollection: { collection in
                            Task {
                                try await collectionStore.deleteUserCollection(collection.id)
                            }
                        }
                    )
                }
            }
            .navigationTitle("My Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New") {
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
            .navigationDestination(isPresented: $showCollectionDetail) {
                if let collection = selectedCollection {
                    CollectionDetailView(collection: collection)
                }
            }
            .task {
                await collectionStore.fetchUserCollections()
            }
            .refreshable {
                if !collectionStore.isLoading {
                    await collectionStore.fetchUserCollections()
                }
            }
        }
    }
}

struct EmptyCollectionsView: View {
    @Binding var showCreateCollection: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("No Collections Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create collections to organize your favorite dog cards")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Create Your First Collection") {
                showCreateCollection = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
    }
}

struct CollectionsListView: View {
    let collections: [Collection]
    let onCollectionTapped: (Collection) -> Void
    let onDeleteCollection: (Collection) -> Void
    
    var body: some View {
        List {
            ForEach(collections) { collection in
                CollectionListItemView(
                    collection: collection,
                    onTap: { onCollectionTapped(collection) },
                    onDelete: { onDeleteCollection(collection) }
                )
            }
        }
    }
}

struct CollectionListItemView: View {
    let collection: Collection
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Collection icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Collection info
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(collection.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(collection.card_count) cards")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(collection.formattedCreatedDate)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .alert("Delete Collection", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(collection.name)'? This action cannot be undone.")
        }
    }
}

struct CollectionDetailView: View {
    let collection: Collection
    @StateObject private var collectionStore = CollectionStore()
    @StateObject private var cardStore = CardStore()
    @State private var showEditCollection = false
    @State private var collectionDetail: CollectionDetail?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading collection...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = collectionDetail {
                CollectionDetailContentView(
                    collection: detail.collection,
                    cards: detail.cards.results
                )
            } else {
                Text("Failed to load collection")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditCollection = true
                }
            }
        }
        .sheet(isPresented: $showEditCollection) {
            EditCollectionView(
                collection: collection,
                collectionStore: collectionStore,
                onCollectionUpdated: {
                    showEditCollection = false
                }
            )
        }
        .task {
            await loadCollectionDetail()
        }
    }
    
    private func loadCollectionDetail() async {
        isLoading = true
        do {
            collectionDetail = try await collectionStore.fetchUserCollectionDetail(collection.id)
        } catch {
            print("Error loading collection detail: \(error)")
        }
        isLoading = false
    }
}

struct CollectionDetailContentView: View {
    let collection: Collection
    let cards: [TravelCard]
    @StateObject private var cardStore = CardStore()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var commentStore = CommentStore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Collection header
            VStack(spacing: 16) {
                Text(collection.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    Label("\(collection.card_count) cards", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label(collection.formattedCreatedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            
            // Cards feed (same as main feed)
            if cards.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Cards Yet")
                        .font(.headline)
                    
                    Text("Add cards to this collection from the feed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cards) { card in
                            SimpleTravelCardView(card: card)
                                .environmentObject(cardStore)
                                .environmentObject(profileStore)
                                .environmentObject(commentStore)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}



struct EditCollectionView: View {
    let collection: Collection
    @ObservedObject var collectionStore: CollectionStore
    let onCollectionUpdated: () -> Void
    
    @State private var name: String
    @State private var description: String
    @State private var isUpdating = false
    @Environment(\.dismiss) private var dismiss
    
    init(collection: Collection, collectionStore: CollectionStore, onCollectionUpdated: @escaping () -> Void) {
        self.collection = collection
        self.collectionStore = collectionStore
        self.onCollectionUpdated = onCollectionUpdated
        self._name = State(initialValue: collection.name)
        self._description = State(initialValue: collection.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Collection Details") {
                    TextField("Collection Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: updateCollection) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Update Collection")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || isUpdating)
                }
            }
            .navigationTitle("Edit Collection")
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
    
    private func updateCollection() {
        Task {
            isUpdating = true
            
            do {
                let request = UpdateCollectionRequest(name: name, description: description)
                let _ = try await collectionStore.updateUserCollection(collection.id, request)
                await collectionStore.fetchUserCollections()
                onCollectionUpdated()
            } catch {
                print("Error updating collection: \(error)")
            }
            
            isUpdating = false
        }
    }
}

#Preview {
    CollectionsView()
}






