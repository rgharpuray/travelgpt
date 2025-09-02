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
    @State private var selectedCategory = "All"
    @State private var selectedMood: TravelMood? = nil
    @State private var searchText = ""
    @State private var showAddCardSheet = false
    @State private var showCardCreationForm = false
    
    // Sample cards with categories for filtering
    private let sampleCards = [
        TravelCard(
            id: 1,
            destination_name: "Montserrat, Barcelona",
            image_url: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400", userName: "Carlos", caption: "Incredible hike to the top!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Maria", caption: "The monastery is magical"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Javier", caption: "Best views in Catalonia!")
            ]
        ),
        TravelCard(
            id: 2,
            destination_name: "Montjuïc Olympic Stadium '92",
            image_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Ana", caption: "Olympic history right here!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Pablo", caption: "The stadium is massive")
            ]
        ),
        TravelCard(
            id: 3,
            destination_name: "La Tomatina Festival, Buñol",
            image_url: "https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&h=600&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Sofia", caption: "Most fun I've ever had!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Diego", caption: "Tomato stains everywhere!")
            ]
        ),
        TravelCard(
            id: 4,
            destination_name: "Sagrada Familia, Barcelona",
            image_url: "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=800&h=600&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400", userName: "Elena", caption: "The light inside is magical"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Miguel", caption: "Gaudí was a genius!")
            ]
        ),
        TravelCard(
            id: 5,
            destination_name: "La Boqueria Market, Barcelona",
            image_url: "https://lp-cms-production.imgix.net/2025-02/shutterstock1238252371.jpg?auto=format,compress&q=72&w=1440&h=810&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Carmen", caption: "Best tapas in the city!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Luis", caption: "Fresh seafood everywhere")
            ]
        ),
        TravelCard(
            id: 6,
            destination_name: "Park Güell, Barcelona",
            image_url: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600&fit=crop",
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
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400", userName: "Isabella", caption: "The mosaics are incredible"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Roberto", caption: "Perfect for photos!")
            ]
        )
    ]
    
    // Filtered cards based on category, mood, and search
    private var filteredCards: [TravelCard] {
        var filtered = sampleCards
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by mood (if selected)
        if let selectedMood = selectedMood {
            filtered = filtered.filter { card in
                // For now, we'll filter based on the card's thought content
                // In a real app, cards would have mood tags
                let thought = card.thought.lowercased()
                switch selectedMood {
                case .excited:
                    return thought.contains("amazing") || thought.contains("incredible") || thought.contains("thrilling")
                case .relaxed:
                    return thought.contains("peaceful") || thought.contains("quiet") || thought.contains("calm")
                case .adventurous:
                    return thought.contains("hiking") || thought.contains("trail") || thought.contains("adventure")
                case .curious:
                    return thought.contains("museum") || thought.contains("historical") || thought.contains("cultural")
                case .hungry:
                    return thought.contains("restaurant") || thought.contains("food") || thought.contains("sushi")
                case .energetic:
                    return thought.contains("crossing") || thought.contains("busy") || thought.contains("vibrant")
                case .romantic:
                    return thought.contains("beautiful") || thought.contains("scenic") || thought.contains("romantic")
                case .social:
                    return thought.contains("market") || thought.contains("crowd") || thought.contains("people")
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.destination_name.lowercased().contains(searchText.lowercased()) ||
                card.thought.lowercased().contains(searchText.lowercased())
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
                        
                        // Category selector
                        Menu {
                            ForEach(["All", "Restaurants", "Activities", "Museums"], id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Text(category)
                                        if selectedCategory == category {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(selectedCategory)
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
                SimpleMapView(cards: sampleCards)
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
            }
        }
        .navigationViewStyle(.stack)
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
                        image_url: imageUrl,
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
                        category: "Activities", isVerified: false
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
            AsyncImageView(url: URL(string: card.image_url))
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                .clipped()
            
            // Content section
            VStack(alignment: .leading, spacing: 16) {
                // Location and thought
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(card.destination_name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if card.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text(card.thought)
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
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showCheckInSheet) {
            CheckInView(card: card)
        }
        .sheet(isPresented: $showPhotoGallery) {
            PhotoGalleryView(card: card)
        }
    }
}

// MARK: - Simple Map View

struct SimpleMapView: View {
    let cards: [TravelCard]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🗺️ Travel Map")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Map view coming soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
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
    
    init(imageUrl: String, userName: String, caption: String? = nil) {
        self.id = UUID()
        self.imageUrl = imageUrl
        self.userName = userName
        self.timestamp = Date()
        self.caption = caption
    }
}

// MARK: - Check-in View

struct CheckInView: View {
    let card: TravelCard
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var isUploading = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Check In at \(card.destination_name)")
                    .font(.title2)
                    .fontWeight(.bold)
                
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
                
                TextField("Add a caption (optional)", text: $caption, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Button(action: uploadCheckIn) {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Check In!")
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(selectedImage != nil ? Color.green : Color.gray)
                    .cornerRadius(20)
                }
                .disabled(selectedImage == nil || isUploading)
                
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
    
    private func uploadCheckIn() {
        guard let selectedImage = selectedImage else { return }
        
        isUploading = true
        
        // Simulate upload
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // In a real app, you'd upload to your backend
            // For now, we'll just dismiss
            isUploading = false
            dismiss()
        }
    }
}

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let card: TravelCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Check-ins at \(card.destination_name)")
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
                image_url: "https://example.com/placeholder.jpg", // In real app, upload image
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
                category: category == "All" ? "Activities" : category, isVerified: false,
                checkInPhotos: []
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
    @State private var destinationName = ""
    @State private var thought = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    
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
                                Text("📍 Where are you?")
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
                            
                            // What's happening
                            VStack(alignment: .leading, spacing: 8) {
                                Text("💭 What's happening?")
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
                    
                    // Send button
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
        }
    }
    
    private var canSubmit: Bool {
        !destinationName.isEmpty && 
        !thought.isEmpty && 
        selectedImage != nil
    }
    
    private func submitCard() {
        isSubmitting = true
        
        // Simulate submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            dismiss()
        }
    }
}


