//
//  ContentView.swift
//  TravelGPT
//
//  Created by Rishi Gharpuray on 5/31/25.
//

import SwiftUI
import PhotosUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @StateObject private var cardStore = CardStore()
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isGeneratingThought = false
    @State private var showProfile = false
    @State private var showOnboarding = true
    @State private var showIntrusiveTutorial = false
    @State private var showPremiumUpgrade = false
    @State private var showDailyLimitAlert = false
    @State private var showSubscriptionExpirationAlert = false
    @Namespace private var brainIconNamespace
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showCardCreationError = false
    @State private var cardCreationErrorMessage: String? = nil
    @State private var showMapView = false
    @State private var showLocationPicker = false
    @State private var currentLocation = "Barcelona, Spain"
    @State private var selectedCategory = "all"
    @State private var selectedMood: TravelMood? = nil
    @State private var searchText = ""
    @State private var showAddCardSheet = false
    @State private var showCardCreationForm = false
    
    // Sample cards with categories for filtering
    private let sampleCards = [
        TravelCard(
            id: 1,
            destination_name: "Montserrat, Barcelona",
            image: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Great hike up to the monastery. The views of Catalonia from the top are impressive - you can see all the way to the Mediterranean.",
            created_at: "2025-01-15T10:30:00Z",
            updated_at: nil,
            like_count: 89,
            is_liked: false,
            is_owner: true,
            is_intrusive_mode: false,
            device_destination_name: "Montserrat",
            owner_destination_name: "Montserrat",
            rarity: "epic",
            collection_tags: ["Barcelona Mountains"],
            category: "Activities",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400", userName: "Carlos", caption: "Incredible hike to the top!"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Maria", caption: "The monastery is magical"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Javier", caption: "Best views in Catalonia!")
            ],
            s3_url: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
            location: "Barcelona, Spain",
            coordinates: "41.5917,1.8353",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-15T11:00:00Z",
            admin_notes: "Great photo and description",
            check_in_count: 15,
            comment_count: 8,
            is_liked_by_user: false,
            is_checked_in_by_user: false,
            moods: ["Adventure", "Nature", "Excited"],
            user: UserResponse(id: 1, username: "traveler123", first_name: "John", last_name: "Doe", email: "john@example.com"),
            theme_color: "#4ECDC4"
        ),
        TravelCard(
            id: 2,
            destination_name: "Montjuïc Olympic Stadium '92",
            image: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Standing in the Olympic Stadium where the '92 Games happened is impressive. You can feel the Olympic spirit that transformed Barcelona.",
            created_at: "2025-01-14T15:45:00Z",
            updated_at: nil,
            like_count: 156,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Montjuïc Olympic Stadium",
            owner_destination_name: "Montjuïc Olympic Stadium",
            rarity: "legendary",
            collection_tags: ["Barcelona Olympics"],
            category: "Activities",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Ana", caption: "Olympic history right here!"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Pablo", caption: "The stadium is massive")
            ],
            s3_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop",
            location: "Barcelona, Spain",
            coordinates: "41.3633,2.1522",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-14T16:00:00Z",
            admin_notes: "Excellent historical content",
            check_in_count: 23,
            comment_count: 12,
            is_liked_by_user: true,
            is_checked_in_by_user: false,
            moods: ["History", "Sports", "Energetic"],
            user: UserResponse(id: 2, username: "olympicfan", first_name: "Sarah", last_name: "Smith", email: "sarah@example.com"),
            theme_color: "#FF6B6B"
        ),
        TravelCard(
            id: 3,
            destination_name: "La Tomatina Festival, Buñol",
            image: "https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "The world's biggest food fight is as chaotic and fun as it sounds. Getting pelted with tomatoes while thousands of people laugh and dance - it's pure Spanish fun.",
            created_at: "2025-01-13T19:20:00Z",
            updated_at: nil,
            like_count: 234,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: true,
            device_destination_name: "La Tomatina",
            owner_destination_name: "La Tomatina",
            rarity: "legendary",
            collection_tags: ["Spanish Festivals"],
            category: "Activities",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Sofia", caption: "Most fun I've ever had!"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Diego", caption: "Tomato stains everywhere!")
            ],
            s3_url: "https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&h=600&fit=crop",
            location: "Buñol, Spain",
            coordinates: "39.4183,-0.7903",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-13T20:00:00Z",
            admin_notes: "Fun festival content",
            check_in_count: 45,
            comment_count: 18,
            is_liked_by_user: false,
            is_checked_in_by_user: false,
            moods: ["festival", "fun"],
            user: UserResponse(id: 3, username: "festivallover", first_name: "Maria", last_name: "Garcia", email: "maria@example.com"),
            theme_color: "#FF8E53"
        ),
        TravelCard(
            id: 4,
            destination_name: "Sagrada Familia, Barcelona",
            image: "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Gaudí's masterpiece is impressive. The stained glass creates a beautiful cathedral effect that makes you feel like you're inside a living work of art.",
            created_at: "2025-01-12T18:00:00Z",
            updated_at: nil,
            like_count: 312,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Sagrada Familia",
            owner_destination_name: "Sagrada Familia",
            rarity: "legendary",
            collection_tags: ["Barcelona Architecture"],
            category: "Museums",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400", userName: "Elena", caption: "The light inside is magical"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Miguel", caption: "Gaudí was a genius!")
            ],
            s3_url: "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=800&h=600&fit=crop",
            location: "Barcelona, Spain",
            coordinates: "41.4036,2.1744",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-12T19:00:00Z",
            admin_notes: "Beautiful architectural content",
            check_in_count: 67,
            comment_count: 25,
            is_liked_by_user: true,
            is_checked_in_by_user: false,
            moods: ["architecture", "culture"],
            user: UserResponse(id: 4, username: "architectfan", first_name: "Carlos", last_name: "Lopez", email: "carlos@example.com")
        ),
        TravelCard(
            id: 5,
            destination_name: "La Boqueria Market, Barcelona",
            image: "https://lp-cms-production.imgix.net/2025-02/shutterstock1238252371.jpg?auto=format,compress&q=72&w=1440&h=810&fit=crop",
            is_valid_destination: true,
            thought: "This market is great for food lovers. Fresh seafood, colorful fruits, and the best jamón ibérico. The energy and smells make you want to try everything.",
            created_at: "2025-01-11T14:30:00Z",
            updated_at: nil,
            like_count: 178,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "La Boqueria",
            owner_destination_name: "La Boqueria",
            rarity: "rare",
            collection_tags: ["Barcelona Food"],
            category: "Restaurants",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Carmen", caption: "Best tapas in the city!"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Luis", caption: "Fresh seafood everywhere")
            ],
            s3_url: "https://lp-cms-production.imgix.net/2025-02/shutterstock1238252371.jpg?auto=format,compress&q=72&w=1440&h=810&fit=crop",
            location: "Barcelona, Spain",
            coordinates: "41.3819,2.1716",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-11T15:00:00Z",
            admin_notes: "Great food market content",
            check_in_count: 34,
            comment_count: 15,
            is_liked_by_user: false,
            is_checked_in_by_user: false,
            moods: ["food", "culture"],
            user: UserResponse(id: 5, username: "foodie", first_name: "Isabella", last_name: "Martinez", email: "isabella@example.com")
        ),
        TravelCard(
            id: 6,
            destination_name: "Park Güell, Barcelona",
            image: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Walking through Park Güell feels like stepping into a fairy tale. The mosaic benches, dragon fountain, and whimsical architecture are impressive.",
            created_at: "2025-01-10T12:00:00Z",
            updated_at: nil,
            like_count: 245,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Park Güell",
            owner_destination_name: "Park Güell",
            rarity: "epic",
            collection_tags: ["Barcelona Parks"],
            category: "Activities",
            isVerified: true,
            checkInPhotos: [
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Antonio", caption: "The mosaics are incredible!"),
                CheckInPhoto(id: UUID(), imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Lucia", caption: "Perfect for a sunny day")
            ],
            s3_url: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
            location: "Barcelona, Spain",
            coordinates: "41.4145,2.1527",
            admin_review_status: "approved",
            admin_reviewer_id: 1,
            admin_reviewed_at: "2025-01-10T13:00:00Z",
            admin_notes: "Beautiful park content",
            check_in_count: 56,
            comment_count: 22,
            is_liked_by_user: true,
            is_checked_in_by_user: false,
            moods: ["nature", "architecture"],
            user: UserResponse(id: 6, username: "parklover", first_name: "David", last_name: "Rodriguez", email: "david@example.com")
        )
    ]
    
    // Filtered cards based on category and search (mood filtering is now handled by API)
    private var filteredCards: [TravelCard] {
        var filtered = cardStore.cards
        
        // Filter by category
        if selectedCategory != "all" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                (card.destination_name ?? "").lowercased().contains(searchText.lowercased()) ||
                (card.thought ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered
    }
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemGroupedBackground
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().backgroundColor = .systemGroupedBackground
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar with location and category - Unified pill design
                HStack(spacing: 0) {
                    // Location + Category unified pill
                    HStack(spacing: 0) {
                        // Location section
                        Button(action: {
                            showLocationPicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.black)
                                    .font(.title3)
                                
                                Text(currentLocation)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Divider
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 1, height: 24)
                        
                        // Map button
                        Button(action: {
                            showMapView = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                    .font(.title3)
                                
                                Text("Map")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Divider
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 1, height: 24)
                        
                        // Category selector
                        Menu {
                            ForEach(["all", "restaurant", "museum", "adventure", "culture", "nature", "city", "beach", "mountain", "park", "shopping", "countryside", "other"], id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Text(category.capitalized)
                                        if selectedCategory == category {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(selectedCategory.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    
                }
                .padding(.top, 8)
                

                .padding(.leading, 20)
                
                // Mood filter bar - Clean chip design
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TravelMood.allCases, id: \.self) { mood in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMood = selectedMood == mood ? nil : mood
                                        // Update CardStore with selected moods
                                        if let selectedMood = selectedMood {
                                            cardStore.selectedMoods = [selectedMood.rawValue]
                                        } else {
                                            cardStore.selectedMoods = []
                                        }
                                        // Refresh feed with new mood filter
                                        Task {
                                            await cardStore.refreshFeed()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: mood.icon)
                                            .font(.caption)
                                            .foregroundColor(selectedMood == mood ? .white : .black)
                                        Text(mood.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedMood == mood ? .white : .primary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedMood == mood ? Color.black : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedMood == mood ? Color.black : Color(.systemGray4), 
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
                
                // Simple feed
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredCards) { card in
                            SimpleTravelCardView(card: card)
                        }
                        
                        if filteredCards.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("No \(selectedCategory.lowercased()) found")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Try selecting a different category or location")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showCardCreationForm = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("PostcardGPT")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "083242"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage, onImageSelected: { image in
                    generateThought(for: image)
                })
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showMapView) {
                LocationMapView(currentLocation: $currentLocation)
                    .onDisappear {
                        // Update CardStore location and refresh feed when location changes
                        if cardStore.selectedLocation != currentLocation {
                            cardStore.selectedLocation = currentLocation
                            Task {
                                await cardStore.refreshFeed()
                            }
                        }
                    }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedLocation: $currentLocation)
            }
            .sheet(isPresented: $showAddCardSheet) {
                AddCardView(
                    location: currentLocation,
                    category: selectedCategory,
                    onCardCreated: { newCard in
                        // Add the new card to the sample cards
                        // In a real app, this would be added to the backend
                    }
                )
            }
            .sheet(isPresented: $showCardCreationForm) {
                CardCreationFormView()
                    .environmentObject(cardStore)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Initialize CardStore location with current location
            cardStore.selectedLocation = currentLocation
            Task {
                await cardStore.refreshFeed()
            }
        }
    }
    
    private func generateThought(for image: UIImage) {
        isGeneratingThought = true
        
        Task {
            do {
                let (thought, imageUrl) = try await BackendService.shared.uploadImageAndGetThought(image, isIntrusiveMode: false)
                
                await MainActor.run {
                    let newCard = TravelCard(
                        id: Int.random(in: 1000...9999),
                        destination_name: "Travel Destination",
                        image: imageUrl,
                        is_valid_destination: true,
                        thought: thought,
                        created_at: ISO8601DateFormatter().string(from: Date()),
                        updated_at: nil,
                        like_count: 0,
                        is_liked: false,
                        is_owner: true,
                        is_intrusive_mode: false,
                        device_destination_name: "Travel Destination",
                        owner_destination_name: "Travel Destination",
                        rarity: "common",
                        collection_tags: [],
                        category: "Activities",
                        isVerified: false,
                        s3_url: imageUrl,
                        location: "Unknown Location",
                        coordinates: nil,
                        admin_review_status: "pending",
                        admin_reviewer_id: nil,
                        admin_reviewed_at: nil,
                        admin_notes: nil,
                        check_in_count: 0,
                        comment_count: 0,
                        is_liked_by_user: false,
                        is_checked_in_by_user: false,
                        moods: [],
                        user: nil
                    )
                    
                    cardStore.addCard(newCard)
                    isGeneratingThought = false
                    selectedImage = nil
                }
            } catch {
                await MainActor.run {
                    cardCreationErrorMessage = error.localizedDescription
                    showCardCreationError = true
                    isGeneratingThought = false
                    selectedImage = nil
                }
            }
        }
    }
}

// MARK: - Simple Travel Card View

struct SimpleTravelCardView: View {
    let card: TravelCard
    @State var isLiked: Bool
    @State var likeCount: Int
    @State private var showCheckInSheet = false
    @State private var showPhotoGallery = false
    
    init(card: TravelCard) {
        self.card = card
        _isLiked = State(initialValue: card.is_liked)
        _likeCount = State(initialValue: card.like_count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main image section
                            AsyncImageView(url: URL(string: card.image))
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                .clipped()
            
            // Content section with theme color background
            VStack(alignment: .leading, spacing: 16) {
                // Location and thought
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(card.destination_name ?? "Unknown Location")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if card.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    // Mood tags - non-intrusive display
                    if !card.moods.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(card.moods.prefix(3), id: \.self) { mood in
                                Text(mood)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            
                            if card.moods.count > 3 {
                                Text("+\(card.moods.count - 3)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                        }
                    }
                    
                    Text(card.thought ?? "No description available")
                        .font(.body)
                        .italic()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Check-in photos preview
                if !card.checkInPhotos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Check-ins")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("View All") {
                                showPhotoGallery = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(card.checkInPhotos.prefix(5), id: \.id) { photo in
                                    AsyncImageView(url: URL(string: photo.imageUrl))
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            Text(photo.userName)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.7))
                                                .cornerRadius(4)
                                                .padding(4),
                                            alignment: .bottomLeading
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action bar
                HStack(spacing: 20) {
                    // Check-in button
                    Button(action: {
                        showCheckInSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                            Text("Check In")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    // Like button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                            likeCount += isLiked ? 1 : -1
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                            Text("\(likeCount)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Comments button
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.gray)
                            Text("\(card.checkInPhotos.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Share button
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(card.themeColor?.opacity(0.1) ?? Color.white)
        }
        .background(card.themeColor?.opacity(0.1) ?? Color.white)
        .cornerRadius(16)
        .shadow(color: card.themeColor?.opacity(0.2) ?? Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showCheckInSheet) {
            CheckInView(card: card)
        }
        .sheet(isPresented: $showPhotoGallery) {
            PhotoGalleryView(card: card)
        }
    }
}

// MARK: - Featured City Model

struct FeaturedCity: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Location Map View

import MapKit
import CoreLocation

struct LocationMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLocation: String
    @Binding var currentLocation: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0), // Japan center
        span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0) // Japan view
    )
    @State private var showingLocationPermissionAlert = false
    
    init(currentLocation: Binding<String>) {
        self._currentLocation = currentLocation
        self._selectedLocation = State(initialValue: currentLocation.wrappedValue)
    }
    
    // Top 12 Japanese cities with coordinates and Japanese names
    private let featuredCities: [FeaturedCity] = [
        FeaturedCity(name: "Tokyo (東京)", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)),
        FeaturedCity(name: "Osaka (大阪)", coordinate: CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023)),
        FeaturedCity(name: "Kyoto (京都)", coordinate: CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7681)),
        FeaturedCity(name: "Yokohama (横浜)", coordinate: CLLocationCoordinate2D(latitude: 35.4437, longitude: 139.6380)),
        FeaturedCity(name: "Nagoya (名古屋)", coordinate: CLLocationCoordinate2D(latitude: 35.1815, longitude: 136.9066)),
        FeaturedCity(name: "Sapporo (札幌)", coordinate: CLLocationCoordinate2D(latitude: 43.0642, longitude: 141.3469)),
        FeaturedCity(name: "Fukuoka (福岡)", coordinate: CLLocationCoordinate2D(latitude: 33.5904, longitude: 130.4017)),
        FeaturedCity(name: "Kobe (神戸)", coordinate: CLLocationCoordinate2D(latitude: 34.6901, longitude: 135.1956)),
        FeaturedCity(name: "Hiroshima (広島)", coordinate: CLLocationCoordinate2D(latitude: 34.3853, longitude: 132.4553)),
        FeaturedCity(name: "Sendai (仙台)", coordinate: CLLocationCoordinate2D(latitude: 38.2682, longitude: 140.8694)),
        FeaturedCity(name: "Nara (奈良)", coordinate: CLLocationCoordinate2D(latitude: 34.6851, longitude: 135.8050)),
        FeaturedCity(name: "Kanazawa (金沢)", coordinate: CLLocationCoordinate2D(latitude: 36.5613, longitude: 136.6562))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Map
                Map(coordinateRegion: $region, annotationItems: featuredCities) { city in
                    MapAnnotation(coordinate: city.coordinate) {
                        Button(action: {
                            selectedLocation = city.name
                            withAnimation(.easeInOut(duration: 0.5)) {
                                region.center = city.coordinate
                                region.span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
                            }
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    // Clean outer ring for selected city
                                    if selectedLocation == city.name {
                                        Circle()
                                            .stroke(Color.red.opacity(0.4), lineWidth: 3)
                                            .frame(width: 50, height: 50)
                                            .scaleEffect(1.2)
                                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: selectedLocation)
                                    }
                                    
                                    // Clean Japanese-style pin
                                    Circle()
                                        .fill(selectedLocation == city.name ? Color.red : Color.white)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.red, lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    // Simple dot for selected, circle for unselected
                                    Circle()
                                        .fill(selectedLocation == city.name ? Color.white : Color.red)
                                        .frame(width: selectedLocation == city.name ? 8 : 6, height: selectedLocation == city.name ? 8 : 6)
                                }
                                
                                // Clean city label - only show when selected to avoid overlap
                                if selectedLocation == city.name {
                                    Text(city.name.components(separatedBy: " (").first ?? "")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.red)
                                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    // Zoom controls
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                // Clean zoom in button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // Limit minimum zoom in to prevent crashes
                                        let minSpan: Double = 0.5
                                        region.span.latitudeDelta = max(region.span.latitudeDelta * 0.5, minSpan)
                                        region.span.longitudeDelta = max(region.span.longitudeDelta * 0.5, minSpan)
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(region.span.latitudeDelta <= 0.5 ? .gray : .white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(region.span.latitudeDelta <= 0.5 ? 
                                                      Color.gray.opacity(0.3) : 
                                                      Color.red)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                                        )
                                }
                                .disabled(region.span.latitudeDelta <= 0.5)
                                
                                // Clean zoom out button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // Limit maximum zoom out to prevent crashes
                                        let maxSpan: Double = 30.0
                                        region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, maxSpan)
                                        region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, maxSpan)
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(region.span.latitudeDelta >= 30.0 ? .gray : .white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(region.span.latitudeDelta >= 30.0 ? 
                                                      Color.gray.opacity(0.3) : 
                                                      Color.red)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                                        )
                                }
                                .disabled(region.span.latitudeDelta >= 30.0)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 100) // Above the bottom panel
                        }
                    }
                )
                
                // Clean white/red bottom panel
                VStack(spacing: 0) {
                    // Clean white background
                    Color.white
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 20) {
                                // Clean selected location card
                                VStack(spacing: 12) {
                                    HStack {
                                        // Clean location icon
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                            .overlay(
                                                Image(systemName: "location.fill")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Selected Location")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.gray)
                                            
                                            Text(selectedLocation.components(separatedBy: " (").first ?? "")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        // Clean select button
                                        Button(action: {
                                            currentLocation = selectedLocation
                                            dismiss()
                                        }) {
                                            HStack(spacing: 6) {
                                                Text("Select")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                Image(systemName: "checkmark")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.red)
                                                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Clean action buttons
                                HStack(spacing: 12) {
                                    // Current location button
                                    Button(action: {
                                        if locationManager.authorizationStatus == .authorizedWhenInUse || 
                                           locationManager.authorizationStatus == .authorizedAlways {
                                            locationManager.requestLocation()
                                        } else {
                                            showingLocationPermissionAlert = true
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("My Location")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.blue)
                                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                    
                                    // Show all Japan button
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            region.center = CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0)
                                            region.span = MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "globe")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("All Japan")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.red)
                                                .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Cancel")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Choose Location")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Select your destination")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                // Start with Japan view showing all Japanese cities
                region.center = CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0)
                region.span = MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
            }
            .onChange(of: locationManager.currentLocation) { location in
                if let location = location {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region.center = location.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    }
                    
                    // Find the closest featured city
                    let closestCity = featuredCities.min { city1, city2 in
                        let distance1 = location.distance(from: CLLocation(latitude: city1.coordinate.latitude, longitude: city1.coordinate.longitude))
                        let distance2 = location.distance(from: CLLocation(latitude: city2.coordinate.latitude, longitude: city2.coordinate.longitude))
                        return distance1 < distance2
                    }
                    
                    if let closestCity = closestCity {
                        selectedLocation = closestCity.name
                    }
                }
            }
            .alert("Location Permission Required", isPresented: $showingLocationPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location services in Settings to use your current location.")
            }
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.image = image
                            self.parent.onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Location Picker View

struct LocationPickerView: View {
    @Binding var selectedLocation: String
    @Environment(\.dismiss) private var dismiss
    
    private let popularCities = [
        "Rome, Italy", "Paris, France", "Tokyo, Japan", "New York, USA",
        "London, UK", "Barcelona, Spain", "Amsterdam, Netherlands", "Prague, Czech Republic"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Destination")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(popularCities, id: \.self) { city in
                        Button(action: {
                            selectedLocation = city
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                
                                Text(city)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedLocation == city ? Color.blue.opacity(0.2) : Color(.systemGray6))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}





// MARK: - Check-in Photo Model

struct CheckInPhoto: Identifiable, Codable {
    let id: UUID
    let imageUrl: String
    let userName: String
    let timestamp: Date
    let caption: String?
    
    init(id: UUID = UUID(), imageUrl: String, userName: String, caption: String? = nil) {
        self.id = id
        self.imageUrl = imageUrl
        self.userName = userName
        self.timestamp = Date()
        self.caption = caption
    }
}

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let card: TravelCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Check-ins at \(card.destination_name ?? "Unknown Location")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                if card.checkInPhotos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No check-ins yet")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Be the first to check in!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(card.checkInPhotos) { photo in
                                VStack(spacing: 4) {
                                    AsyncImageView(url: URL(string: photo.imageUrl))
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                    
                                    Text(photo.userName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Card View

struct AddCardView: View {
    let location: String
    let category: String
    let onCardCreated: (TravelCard) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var personalThought = ""
    @State private var isGenerating = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Add \(category == "All" ? "Card" : category)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Photo upload
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add a photo of your experience")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("Take Photo")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Personal thought
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's on your mind?")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Share your thoughts about this experience...", text: $personalThought, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Create card button
                Button(action: createCard) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create \(category == "All" ? "Card" : category)")
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(selectedImage != nil ? Color.blue : Color.gray)
                    .cornerRadius(20)
                }
                .disabled(selectedImage == nil || isGenerating)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, onImageSelected: { _ in })
            }
        }
    }
    
    private func createCard() {
        guard let selectedImage = selectedImage else { return }
        
        isGenerating = true
        
        // Simulate card creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newCard = TravelCard(
                id: Int.random(in: 1000...9999),
                destination_name: "New Experience in \(location)",
                image: "https://example.com/placeholder.jpg", // In real app, upload image
                is_valid_destination: true,
                thought: personalThought.isEmpty ? "Amazing experience in \(location)!" : personalThought,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: nil,
                like_count: 0,
                is_liked: false,
                is_owner: true,
                is_intrusive_mode: false,
                device_destination_name: "New Experience",
                owner_destination_name: "New Experience",
                rarity: "common",
                collection_tags: ["Personal Experience"],
                category: category == "All" ? "Activities" : category,
                isVerified: false,
                s3_url: "https://example.com/placeholder.jpg",
                location: location,
                coordinates: nil,
                admin_review_status: "pending",
                admin_reviewer_id: nil,
                admin_reviewed_at: nil,
                admin_notes: nil,
                check_in_count: 0,
                comment_count: 0,
                is_liked_by_user: false,
                is_checked_in_by_user: false,
                moods: [],
                user: nil
            )
            
            onCardCreated(newCard)
            isGenerating = false
            dismiss()
        }
    }
}

// MARK: - Travel Mood Enum

enum TravelMood: String, CaseIterable {
    case excited, relaxed, adventurous, curious, hungry, energetic, romantic, social
    
    var displayName: String {
        switch self {
        case .excited: return "Excited"
        case .relaxed: return "Relaxed"
        case .adventurous: return "Adventurous"
        case .curious: return "Curious"
        case .hungry: return "Hungry"
        case .energetic: return "Energetic"
        case .romantic: return "Romantic"
        case .social: return "Social"
        }
    }
    
    var icon: String {
        switch self {
        case .excited: return "star.fill"
        case .relaxed: return "leaf.fill"
        case .adventurous: return "mountain.2.fill"
        case .curious: return "questionmark.circle.fill"
        case .hungry: return "fork.knife"
        case .energetic: return "bolt.fill"
        case .romantic: return "heart.fill"
        case .social: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .excited: return .orange
        case .relaxed: return .green
        case .adventurous: return .purple
        case .curious: return .blue
        case .hungry: return .red
        case .energetic: return .yellow
        case .romantic: return .pink
        case .social: return .indigo
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CardStore())
}

// MARK: - Card Creation Form View

struct CardCreationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardStore: CardStore
    @State private var destinationName = ""
    @State private var thought = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    @State private var selectedCategory = "adventure"
    @State private var location = "Barcelona, Spain"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    
    private let categories = ["adventure", "culture", "nature", "city", "beach", "mountain", "museum", "restaurant", "hotel", "park", "shopping", "countryside", "other"]
    
    private var displayCategories: [(value: String, display: String)] {
        return categories.map { category in
            (value: category, display: category.capitalized)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Postcard background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Postcard header
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Write Your Postcard")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Share a moment from your journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // Postcard content area
                    VStack(spacing: 0) {
                        // Image section (top half of postcard)
                        VStack(spacing: 0) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                                    .overlay(
                                        Button(action: {
                                            self.selectedImage = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.7))
                                                .clipShape(Circle())
                                        }
                                        .padding(12),
                                        alignment: .topTrailing
                                    )
                            } else {
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    VStack(spacing: 16) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)
                                        
                                        Text("Add Your Photo")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        Text("Capture the moment")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(.systemGray6), Color(.systemGray5)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Writing section (bottom half of postcard)
                        VStack(spacing: 20) {
                            // Where you are
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📍 Where are you? (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("e.g., Sagrada Familia, Barcelona", text: $destinationName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            // Category selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🏷️ Category (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(displayCategories, id: \.value) { category in
                                        Text(category.display).tag(category.value)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // What's happening
                            VStack(alignment: .leading, spacing: 8) {
                                Text("💭 What's happening? (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("Tell us about your experience...", text: $thought, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.body)
                                    .lineLimit(4...8)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(Color(.systemBackground))
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: submitCard) {
                        HStack(spacing: 12) {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Send Postcard")
                            }
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canSubmit ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, onImageSelected: { _ in })
            }
            .alert("Error Creating Card", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Card Created!", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Your postcard has been sent and is pending admin review.")
            }
        }
    }
    
    private var canSubmit: Bool {
        selectedImage != nil
    }
    
    private func submitCard() {
        guard let image = selectedImage else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let response = try await TravelCardAPIService.shared.createCard(
                    image: image,
                    destinationName: destinationName.isEmpty ? nil : destinationName,
                    thought: thought.isEmpty ? nil : thought,
                    location: location.isEmpty ? nil : location,
                    coordinates: nil,
                    category: selectedCategory.isEmpty ? nil : selectedCategory
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
                
                // Convert response to TravelCard and add to store
                let newCard = TravelCard(
                    id: Int.random(in: 1000...9999), // Generate local ID since API doesn't return one
                    destination_name: response.destination_name ?? (destinationName.isEmpty ? nil : destinationName), // Use form value as fallback
                    image: response.image ?? "placeholder_image", // Use fallback image URL
                    is_valid_destination: true,
                    thought: response.thought ?? (thought.isEmpty ? nil : thought), // Use form value as fallback
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: nil,
                    like_count: 0,
                    is_liked: false,
                    is_owner: true,
                    is_intrusive_mode: false,
                    device_destination_name: response.destination_name ?? destinationName,
                    owner_destination_name: response.destination_name ?? destinationName,
                    rarity: "common",
                    collection_tags: [],
                    category: response.category ?? selectedCategory.lowercased(),
                    isVerified: false, // New cards start as unverified
                    s3_url: response.s3_url ?? response.image ?? "placeholder_s3_url",
                    location: response.location ?? location, // Use form value as fallback
                    coordinates: response.coordinates,
                    admin_review_status: "pending", // New cards are pending review
                    admin_reviewer_id: nil,
                    admin_reviewed_at: nil,
                    admin_notes: nil,
                    check_in_count: 0,
                    comment_count: 0,
                    is_liked_by_user: false,
                    is_checked_in_by_user: false,
                    moods: [],
                    user: nil
                )
                
                // Add to store and refresh feed
                cardStore.addCard(newCard)
                await cardStore.refreshFeed()
                
                // Show success message
                showSuccessAlert = true
                
                print("Card created successfully with local ID: \(newCard.id)")
                
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    // Handle error - show alert or error message
                    print("Error creating card: \(error)")
                }
            }
        }
    }
}


