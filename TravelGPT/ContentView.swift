//
//  ContentView.swift
//  TravelGPT
//
//  Created by Rishi Gharpuray on 5/31/25.
//

import SwiftUI
import PhotosUI

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
    @State private var currentLocation = "Rome, Italy"
    @State private var selectedCategory = "All"
    @State private var selectedMood: TravelMood? = nil
    @State private var searchText = ""
    @State private var showAddCardSheet = false
    
    // Sample cards with categories for filtering
    private let sampleCards = [
        TravelCard(
            id: 1,
            destination_name: "Akihabara, Tokyo",
            image_url: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Akihabara is like if someone took all the anime and gaming dreams I had as a kid and turned them into a real place. The neon lights are so bright, I'm pretty sure they can see them from space.",
            created_at: "2025-01-15T10:30:00Z",
            updated_at: nil,
            like_count: 42,
            is_liked: false,
            is_owner: true,
            is_intrusive_mode: false,
            device_destination_name: "Akihabara",
            owner_destination_name: "Akihabara",
            rarity: "rare",
            collection_tags: ["Tokyo Adventures"],
            category: "Activities",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Alex", caption: "Amazing anime vibes!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Sarah", caption: "Found the perfect figurine"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Mike", caption: "Gaming paradise!")
            ]
        ),
        TravelCard(
            id: 2,
            destination_name: "Fushimi Inari, Kyoto",
            image_url: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Walking through thousands of torii gates felt like being in a real-life video game level. I half expected to find a save point or power-up around every corner.",
            created_at: "2025-01-14T15:45:00Z",
            updated_at: nil,
            like_count: 28,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Fushimi Inari",
            owner_destination_name: "Fushimi Inari",
            rarity: "common",
            collection_tags: ["Kyoto Temples"],
            category: "Activities",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Emma", caption: "Peaceful morning walk"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "David", caption: "Magical atmosphere")
            ]
        ),
        TravelCard(
            id: 3,
            destination_name: "Shibuya Crossing, Tokyo",
            image_url: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "This crossing is so chaotic and beautiful, it's like watching a perfectly choreographed dance where everyone forgot the routine but somehow it still works.",
            created_at: "2025-01-13T19:20:00Z",
            updated_at: nil,
            like_count: 67,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: true,
            device_destination_name: "Shibuya Crossing",
            owner_destination_name: "Shibuya Crossing",
            rarity: "legendary",
            collection_tags: ["Tokyo Life"],
            category: "Activities",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400", userName: "Lisa", caption: "The energy here is incredible!"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Tom", caption: "Perfect spot for people watching")
            ]
        ),
        TravelCard(
            id: 4,
            destination_name: "Sukiyabashi Jiro, Tokyo",
            image_url: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Legendary sushi restaurant that inspired Jiro Dreams of Sushi. Reservations required months in advance, but worth every yen!",
            created_at: "2025-01-12T18:00:00Z",
            updated_at: nil,
            like_count: 203,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Sukiyabashi Jiro",
            owner_destination_name: "Sukiyabashi Jiro",
            rarity: "legendary",
            collection_tags: ["Tokyo Food"],
            category: "Restaurants",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400", userName: "Chef Ken", caption: "Once in a lifetime experience"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "Foodie Anna", caption: "Worth every penny!")
            ]
        ),
        TravelCard(
            id: 5,
            destination_name: "Tokyo National Museum",
            image_url: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "Japan's oldest and largest museum houses over 110,000 artifacts. The samurai armor collection is absolutely breathtaking!",
            created_at: "2025-01-11T14:30:00Z",
            updated_at: nil,
            like_count: 67,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Tokyo National Museum",
            owner_destination_name: "Tokyo National Museum",
            rarity: "rare",
            collection_tags: ["Tokyo Culture"],
            category: "Museums",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400", userName: "History Buff", caption: "The samurai armor is incredible"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Art Lover", caption: "So many beautiful artifacts")
            ]
        ),
        TravelCard(
            id: 6,
            destination_name: "Tsukiji Outer Market",
            image_url: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop",
            is_valid_destination: true,
            thought: "The outer market is still bustling with food stalls and restaurants. Try the fresh sushi and tamago (egg) dishes!",
            created_at: "2025-01-10T12:00:00Z",
            updated_at: nil,
            like_count: 134,
            is_liked: true,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Tsukiji Outer Market",
            owner_destination_name: "Tsukiji Outer Market",
            rarity: "common",
            collection_tags: ["Tokyo Food"],
            category: "Restaurants",
            checkInPhotos: [
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400", userName: "Sushi Master", caption: "Fresh fish every morning"),
                CheckInPhoto(imageUrl: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400", userName: "Market Explorer", caption: "Best breakfast in Tokyo!")
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
                // Top bar with add card, location, and category
                HStack(spacing: 16) {
                    // Add card button
                    Button(action: {
                        showAddCardSheet = true
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                            
                            Text(selectedCategory == "All" ? "Add Card" : "Add \(selectedCategory)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 80, height: 80)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                    }
                    
                    // Location display
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            Text(currentLocation)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Tap to change location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onTapGesture {
                        showLocationPicker = true
                    }
                    
                    // Category selector
                    VStack(spacing: 4) {
                        Text("Show:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag("All")
                            Text("Restaurants").tag("Restaurants")
                            Text("Activities").tag("Activities")
                            Text("Museums").tag("Museums")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .font(.caption)
                        .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    Spacer()
                }
                
                // Mood and search filter bar
                HStack(spacing: 16) {
                    // Mood/feeling filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TravelMood.allCases, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = selectedMood == mood ? nil : mood
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: mood.icon)
                                            .font(.caption)
                                        Text(mood.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(selectedMood == mood ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedMood == mood ? mood.color : Color(.systemGray6))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Search box
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        TextField("Search experiences...", text: $searchText)
                            .font(.caption)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .frame(width: 150)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.horizontal, 20)
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
                ToolbarItem(placement: .principal) {
                    Text("TravelGPT")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9))
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
                        category: "Activities"
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
                    Text(card.destination_name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
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
                        .background(Color.green)
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
                category: category == "All" ? "Activities" : category,
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


