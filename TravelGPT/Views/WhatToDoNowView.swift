import SwiftUI
import CoreLocation

struct WhatToDoNowView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @StateObject private var locationService = TokiLocationService.shared
    @State private var currentTime = Date()
    @State private var showingAccommodationBooking = false
    @State private var hasCheckedAccommodation = false
    @State private var nearbyPlaces: [NearbyPlace] = []
    @State private var isLoadingNearby = false
    @State private var isDiscoveringWithGPT = false
    @State private var selectedCategory: NearbyPlace.PlaceCategory = .restaurant
    @State private var showingAPIKeyAlert = false
    @State private var showingAISettings = false
    @State private var destinationSuggestions: [AttractionSuggestion] = []
    @State private var isLoadingDestinationSuggestions = false
    @State private var uniqueTopActivities: [RichActivitySuggestion] = []
    @State private var isLoadingTopActivities = false
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("What to do now?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(timeGreeting)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Destination Tips Section
                destinationTipsSection
                
                // Unique Top Activities in [City] - Prominent horizontal scrolling section
                uniqueTopActivitiesSection
                
                // Accommodation Prompt (if no hotel reservation)
                if !hasHotelReservation && !hasCheckedAccommodation {
                    AccommodationPromptCard {
                        showingAccommodationBooking = true
                    } onDismiss: {
                        hasCheckedAccommodation = true
                    }
                }
                
                // Upcoming Reservations
                if !upcomingReservations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Upcoming")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        ForEach(upcomingReservations) { reservation in
                            ReservationCard(reservation: reservation)
                        }
                    }
                }
                
                // Today's Cards
                if !todayCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("Today")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        ForEach(todayCards) { card in
                            CardRow(card: card)
                        }
                    }
                }
                
                // Next Scheduled Activity
                if let nextCard = nextScheduledCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.green)
                            Text("Next Up")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        CardRow(card: nextCard)
                    }
                }
                
                // Quick "What's Next?" Action
                if let lastCard = todayCards.last, lastCard.placeId != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("What's Next?")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                discoverNearbyWithGPT()
                            }) {
                                HStack(spacing: 6) {
                                    if isDiscoveringWithGPT {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text("Discover Nearby")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(hasOpenAIKey() ? Color.purple : Color.gray)
                                .cornerRadius(10)
                            }
                            .disabled(isDiscoveringWithGPT || !hasOpenAIKey())
                        }
                        .padding(.horizontal)
                        
                        if let placeId = lastCard.placeId, let place = storage.getPlace(placeId) {
                            Text("Based on: \(place.label ?? "your last activity")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Nearby Places
                nearbyPlacesSection
                
                // Suggestions based on current time
                if !contextualSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Suggestions for now")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        ForEach(contextualSuggestions) { suggestion in
                            SuggestionCard(suggestion: suggestion, trip: trip)
                        }
                    }
                } else if isLoadingSuggestions {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Loading suggestions...")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        ProgressView()
                            .padding()
                    }
                }
                
                // Empty state - only show if truly nothing is happening
                if upcomingReservations.isEmpty && todayCards.isEmpty && nextScheduledCard == nil && nearbyPlaces.isEmpty && contextualSuggestions.isEmpty && !isLoadingNearby && !isLoadingSuggestions {
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("Ready to explore?")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Add cards, check nearby places, or let us suggest activities")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                Label("Add a card", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                Label("Check map", systemImage: "map.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 60)
                }
            }
            .padding()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showingAccommodationBooking) {
            AccommodationBookingView(trip: trip)
        }
        .onAppear {
            // Check if they already have a hotel reservation
            checkAccommodationStatus()
            // Start location updates
            locationService.startUpdatingLocation()
            // Try loading nearby places and suggestions after a short delay to allow location to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loadUniqueTopActivities()
                loadNearbyPlaces()
                loadContextualSuggestions()
            }
        }
        .onChange(of: trip.reservations.count) { _ in
            checkAccommodationStatus()
        }
        .onChange(of: selectedCategory) { _ in
            loadNearbyPlaces()
        }
        .onChange(of: locationService.currentLocation) { _ in
            // Reload nearby places when location updates
            if nearbyPlaces.isEmpty {
                loadNearbyPlaces()
            }
        }
        .alert("OpenAI API Key Required", isPresented: $showingAPIKeyAlert) {
            Button("Open Settings") {
                showingAISettings = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("AI Discovery requires an OpenAI API key. Add your key in Settings to use this feature.")
        }
        .sheet(isPresented: $showingAISettings) {
            NavigationView {
                AISettingsView()
            }
        }
    }
    
    // MARK: - Nearby Places Section
    
    private var nearbyPlacesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.red)
                Text("Nearby")
                    .font(.headline)
                
                Spacer()
                
                // Category Picker
                Menu {
                    ForEach(NearbyPlace.PlaceCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.capitalized)
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedCategory.icon)
                        Text(selectedCategory.rawValue.capitalized)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                // GPT Discovery button
                Button(action: {
                    if hasOpenAIKey() {
                        discoverNearbyWithGPT()
                    } else {
                        showingAPIKeyAlert = true
                    }
                }) {
                    HStack(spacing: 4) {
                        if isDiscoveringWithGPT {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("AI Discover")
                            .font(.caption)
                    }
                    .foregroundColor(hasOpenAIKey() ? .blue : .gray)
                }
                .disabled(isDiscoveringWithGPT || !hasOpenAIKey())
                
                // Refresh button
                Button(action: {
                    loadNearbyPlaces()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isLoadingNearby {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding nearby places...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if nearbyPlaces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No nearby \(selectedCategory.rawValue)s found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if getCurrentLocation() == nil {
                        Text("Location not available. Enable location services in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Button(action: {
                            loadNearbyPlaces()
                        }) {
                            Text("Try Again")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyPlaces) { place in
                            NearbyPlaceCard(place: place, trip: trip)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func loadNearbyPlaces() {
        guard let location = getCurrentLocation() else {
            // Request location if not available
            locationService.requestAuthorization()
            locationService.startUpdatingLocation()
            return
        }
        
        isLoadingNearby = true
        Task {
            let places = await NearbyPlacesService.shared.findNearby(
                location: location,
                category: selectedCategory,
                radius: 2000,
                limit: 10
            )
            
            await MainActor.run {
                nearbyPlaces = places
                isLoadingNearby = false
            }
        }
    }
    
    private func discoverNearbyWithGPT() {
        // Use last card's location if available, otherwise use current location
        let (location, locationName, previousActivity) = getLocationForDiscovery()
        
        guard let location = location else {
            // Request location if not available
            locationService.requestAuthorization()
            locationService.startUpdatingLocation()
            return
        }
        
        isDiscoveringWithGPT = true
        
        Task {
            // Map category to GPT categories
            let categories: [String]? = {
                switch selectedCategory {
                case .restaurant:
                    return ["restaurant", "cafe"]
                case .cafe:
                    return ["cafe", "restaurant"]
                case .bar:
                    return ["bar", "restaurant"]
                case .activity:
                    return ["activity", "attraction"]
                case .attraction:
                    return ["attraction", "museum", "view"]
                case .shopping:
                    return ["shopping", "market"]
                case .hotel:
                    return ["hotel", "lodging"]
                case .other:
                    return nil // Let GPT decide for "other"
                }
            }()
            
            let createdCardIds = await TokiAIService.shared.fetchNearbyPlacesAndCreateCards(
                location: (lat: location.latitude, lon: location.longitude),
                tripId: trip.id,
                locationName: locationName,
                enableWebSearch: true,
                categories: categories,
                previousActivity: previousActivity
            )
            
            await MainActor.run {
                isDiscoveringWithGPT = false
                
                if !createdCardIds.isEmpty {
                    // Reload nearby places to show the new cards
                    loadNearbyPlaces()
                }
            }
        }
    }
    
    private func getLocationForDiscovery() -> (location: CLLocationCoordinate2D?, locationName: String?, previousActivity: String?) {
        // Get the most recent card with a location
        let tripCards = storage.getCardsForTrip(trip.id)
            .sorted { $0.takenAt > $1.takenAt } // Most recent first
        
        for card in tripCards {
            if let placeId = card.placeId,
               let place = storage.getPlace(placeId),
               place.lat != 0 && place.lon != 0 {
                let location = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                let locationName = place.label ?? trip.name
                let previousActivity = card.text?.components(separatedBy: .newlines).first?.replacingOccurrences(of: "**", with: "") ?? place.label
                return (location, locationName, previousActivity)
            }
        }
        
        // Fallback to current location
        if let currentLocation = locationService.currentLocation {
            return (currentLocation.coordinate, trip.name, nil)
        }
        
        // Fallback to trip destination
        if let destinationPlace = searchForDestinationPlace() {
            let location = CLLocationCoordinate2D(latitude: destinationPlace.lat, longitude: destinationPlace.lon)
            return (location, trip.name, nil)
        }
        
        return (nil, nil, nil)
    }
    
    private func getCurrentLocation() -> CLLocationCoordinate2D? {
        // Try current device location first
        if let currentLocation = locationService.currentLocation {
            return currentLocation.coordinate
        }
        
        // Fallback to trip's places (try all places, not just first card)
        let tripCards = storage.getCardsForTrip(trip.id)
        for card in tripCards {
            if let placeId = card.placeId,
               let place = storage.getPlace(placeId),
               place.lat != 0 && place.lon != 0 {
                return CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
            }
        }
        
        // Fallback: search for destination by trip name
        if let destinationPlace = searchForDestinationPlace() {
            return CLLocationCoordinate2D(latitude: destinationPlace.lat, longitude: destinationPlace.lon)
        }
        
        return nil
    }
    
    private func searchForDestinationPlace() -> Place? {
        // Try to find a place that matches the trip name
        let tripNameLower = trip.name.lowercased()
        return storage.places.first { place in
            guard place.lat != 0 && place.lon != 0 else { return false }
            if let label = place.label?.lowercased() {
                return label.contains(tripNameLower) || tripNameLower.contains(label)
            }
            return false
        }
    }
    
    private func hasOpenAIKey() -> Bool {
        // PROOF OF CONCEPT: Always return true since we have hardcoded key
        return true
        // let keychain = KeychainManager.shared
        // if let apiKey = keychain.getOpenAIKey(), !apiKey.isEmpty {
        //     return true
        // }
        // return false
    }
    
    // MARK: - Unique Top Activities Section
    
    private var uniqueTopActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("Unique Top Activities in \(trip.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if hasOpenAIKey() {
                    Button(action: {
                        loadUniqueTopActivities()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
            
            if isLoadingTopActivities {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if uniqueTopActivities.isEmpty {
                if hasOpenAIKey() {
                    Button(action: {
                        loadUniqueTopActivities()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Discover Unique Activities")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                    }
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Add OpenAI API key in Settings to see suggestions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(uniqueTopActivities) { activity in
                            RichActivityCard(activity: activity, trip: trip)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Destination Tips Section
    
    private var destinationTipsSection: some View {
        let tips = DestinationTipsService.shared.getDestinationTips(for: trip.name)
        
        guard !tips.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Travel Tips for \(trip.name)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        )
    }
    
    private func loadUniqueTopActivities() {
        guard hasOpenAIKey() else { return }
        
        isLoadingTopActivities = true
        
        Task {
            // Get location from trip destination or first place
            let location: (lat: Double, lon: Double)? = {
                // Try to get location from trip's places
                let tripCards = storage.getCardsForTrip(trip.id)
                for card in tripCards {
                    if let placeId = card.placeId,
                       let place = storage.getPlace(placeId),
                       place.lat != 0 && place.lon != 0 {
                        return (lat: place.lat, lon: place.lon)
                    }
                }
                
                // Fallback to destination place search
                if let destinationPlace = searchForDestinationPlace() {
                    return (lat: destinationPlace.lat, lon: destinationPlace.lon)
                }
                
                return nil
            }()
            
            let activities = await TokiAIService.shared.fetchUniqueTopActivities(
                destination: trip.name,
                location: location,
                tripId: trip.id
            )
            
            await MainActor.run {
                uniqueTopActivities = activities
                isLoadingTopActivities = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkAccommodationStatus() {
        hasCheckedAccommodation = trip.reservations.contains { $0.type == .hotel }
    }
    
    // MARK: - Computed Properties
    
    private var hasHotelReservation: Bool {
        trip.reservations.contains { $0.type == .hotel }
    }
    
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good morning! 🌅"
        case 12..<17: return "Good afternoon! ☀️"
        case 17..<22: return "Good evening! 🌆"
        default: return "Late night! 🌙"
        }
    }
    
    private var upcomingReservations: [Reservation] {
        trip.reservations
            .filter { reservation in
                guard let date = reservation.date else { return false }
                return date >= currentTime && date <= Calendar.current.date(byAdding: .day, value: 1, to: currentTime) ?? currentTime
            }
            .sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    }
    
    private var todayCards: [Card] {
        let calendar = Calendar.current
        return storage.getCardsForTrip(trip.id)
            .filter { calendar.isDateInToday($0.takenAt) }
            .sorted { $0.takenAt < $1.takenAt }
    }
    
    private var nextScheduledCard: Card? {
        storage.getCardsForTrip(trip.id)
            .filter { $0.takenAt > currentTime }
            .sorted { $0.takenAt < $1.takenAt }
            .first
    }
    
    @State private var contextualSuggestions: [AttractionSuggestion] = []
    @State private var isLoadingSuggestions = false
    
    private func loadContextualSuggestions() {
        guard let location = getCurrentLocation() else { return }
        
        isLoadingSuggestions = true
        Task {
            // Get trip destination name for context
            let destination = trip.name
            
            // Use default trip type (can be enhanced later with trip settings)
            let tripType = "general"
            
            // Get current hour for time-based suggestions
            let hour = Calendar.current.component(.hour, from: currentTime)
            
            // Build context
            var context: [String: Any] = [
                "currentHour": hour,
                "currentTime": currentTime
            ]
            
            // Load suggestions
            let suggestions = await TokiAIService.shared.suggestAttractions(
                for: destination,
                location: (lat: location.latitude, lon: location.longitude),
                tripType: tripType,
                context: context
            )
            
            await MainActor.run {
                contextualSuggestions = suggestions.prefix(5).map { $0 } // Limit to 5
                isLoadingSuggestions = false
            }
        }
    }
}

struct ReservationCard: View {
    let reservation: Reservation
    
    private var timeUntil: String {
        guard let date = reservation.date else { return "" }
        let timeInterval = date.timeIntervalSinceNow
        
        if timeInterval < 0 {
            return "Past"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "in \(minutes) min"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "in \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = Int(timeInterval / 86400)
            return "in \(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForType(reservation.type))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reservation.provider ?? reservation.type.rawValue.capitalized)
                    .font(.headline)
                
                if let date = reservation.date {
                    HStack {
                        Text(date, style: .time)
                        if !timeUntil.isEmpty {
                            Text("• \(timeUntil)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
                
                Text("Conf: \(reservation.confirmationNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func iconForType(_ type: Reservation.ReservationType) -> String {
        switch type {
        case .flight: return "airplane"
        case .hotel: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        case .activity: return "figure.walk"
        case .car: return "car.fill"
        case .other: return "doc.text"
        }
    }
}

struct SuggestionCard: View {
    let suggestion: AttractionSuggestion
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    var body: some View {
        Button(action: {
            // Create a card for this suggestion
            let place = storage.findOrCreatePlace(
                lat: suggestion.location.lat,
                lon: suggestion.location.lon,
                label: suggestion.title,
                categories: [suggestion.category]
            )
            
            storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .note,
                takenAt: Date(),
                tags: [suggestion.category],
                text: suggestion.description
            )
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct AccommodationPromptCard: View {
    let onBook: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Have you decided where to stay?")
                        .font(.headline)
                    
                    Text("Add your hotel and confirmation number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onBook) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Hotel")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct RichActivityCard: View {
    let activity: RichActivitySuggestion
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    var body: some View {
        Button(action: {
            // Get existing cards to calculate transport and timing
            let existingCards = storage.getCardsForTrip(trip.id).sorted { $0.takenAt < $1.takenAt }
            var lastCardLocation: (lat: Double, lon: Double, name: String?)? = nil
            
            if let lastCard = existingCards.last,
               let lastPlaceId = lastCard.placeId,
               let lastPlace = storage.getPlace(lastPlaceId) {
                lastCardLocation = (lat: lastPlace.lat, lon: lastPlace.lon, name: lastPlace.label)
            }
            
            // Create a place and card for this activity
            let place = storage.findOrCreatePlace(
                lat: activity.latitude,
                lon: activity.longitude,
                label: activity.name,
                categories: [activity.category]
            )
            
            // Calculate activity duration
            let activityDuration = TransportService.shared.estimateActivityDuration(category: activity.category)
            let durationMinutes = Int(activityDuration / 60)
            
            // Calculate start time
            let cardStartTime: Date
            if let lastLocation = lastCardLocation {
                let transport = TransportService.shared.calculateTransport(
                    from: lastLocation,
                    to: (lat: activity.latitude, lon: activity.longitude, name: activity.name),
                    destination: trip.name
                )
                
                // Create transport card before this activity
                let transportCard = storage.createCard(
                    tripId: trip.id,
                    kind: .note,
                    takenAt: Date(),
                    tags: ["transport", transport.method.rawValue],
                    text: "🚶 **Transport**\n\n\(transport.instructions)\n\nDistance: \(String(format: "%.1f", transport.distance / 1000.0)) km"
                )
                
                // Activity starts after transport
                cardStartTime = Date().addingTimeInterval(transport.estimatedTime)
            } else {
                cardStartTime = Date()
            }
            
            // Build rich text content with duration
            var cardText = "**\(activity.name)**\n\n"
            
            if let rating = activity.rating {
                cardText += "⭐ \(String(format: "%.1f", rating))"
                if let priceLevel = activity.priceLevel {
                    cardText += " • \(String(repeating: "$", count: priceLevel))"
                }
                cardText += "\n\n"
            }
            
            if let address = activity.address {
                cardText += "📍 \(address)\n\n"
            }
            
            // Add duration estimate
            cardText += "⏱️ **Estimated duration:** \(durationMinutes) minutes\n\n"
            
            cardText += "**Why go:** \(activity.whyGo)\n\n"
            cardText += "**What to expect:** \(activity.whatToExpect)\n\n"
            
            if let tip = activity.tip {
                cardText += "💡 **Tip:** \(tip)\n\n"
            }
            
            // Add Google Maps link
            let placeNameEncoded = activity.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? activity.name
            let addressEncoded = (activity.address ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let query = addressEncoded.isEmpty ? placeNameEncoded : "\(placeNameEncoded)+\(addressEncoded)"
            let googleMapsURL = "https://www.google.com/maps/search/?api=1&query=\(query)"
            cardText += "🗺️ [Open in Google Maps](\(googleMapsURL))"
            
            storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .note,
                takenAt: cardStartTime,
                tags: [activity.category, "unique", "top-activity"],
                text: cardText
            )
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with rating
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            if let rating = activity.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            }
                            
                            Text(activity.category.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let priceLevel = activity.priceLevel {
                                Text("• \(String(repeating: "$", count: priceLevel))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Why go
                Text(activity.whyGo)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Address if available
                if let address = activity.address {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Add button
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Trip")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .frame(width: 300, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DestinationSuggestionCard: View {
    let suggestion: AttractionSuggestion
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    var body: some View {
        Button(action: {
            // Create a place and card for this suggestion
            let place = storage.findOrCreatePlace(
                lat: suggestion.location.lat,
                lon: suggestion.location.lon,
                label: suggestion.title,
                categories: [suggestion.category]
            )
            
            storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .note,
                takenAt: Date(),
                tags: [suggestion.category, "suggestion"],
                text: "**\(suggestion.title)**\n\n\(suggestion.description)"
            )
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Category icon and title
                HStack(alignment: .top) {
                    Image(systemName: iconForCategory(suggestion.category))
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(categoryDisplayName(suggestion.category))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Description
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Add button
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .frame(width: 280, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "restaurant", "food": return "fork.knife"
        case "cafe": return "cup.and.saucer.fill"
        case "bar": return "wineglass.fill"
        case "activity", "attraction": return "figure.walk"
        case "museum": return "building.columns.fill"
        case "park", "nature": return "tree.fill"
        case "view", "scenic": return "camera.fill"
        case "market", "shopping": return "bag.fill"
        case "hotel", "lodging": return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func categoryDisplayName(_ category: String) -> String {
        return category.capitalized
    }
}

struct NearbyPlaceCard: View {
    let place: NearbyPlace
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    private var distanceString: String {
        guard let distance = place.distance else { return "" }
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
    
    var body: some View {
        Button(action: {
            // Create a place and card for this nearby place
            let createdPlace = storage.findOrCreatePlace(
                lat: place.lat,
                lon: place.lon,
                label: place.name,
                categories: [place.category.rawValue]
            )
            
            var cardText = place.name
            if let address = place.address {
                cardText += "\n\(address)"
            }
            if let rating = place.rating {
                cardText += "\n⭐ \(String(format: "%.1f", rating))"
            }
            
            storage.createCard(
                tripId: trip.id,
                placeId: createdPlace.id,
                kind: .note,
                takenAt: Date(),
                tags: [place.category.rawValue, "nearby"],
                text: cardText
            )
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: place.category.icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Spacer()
                    
                    if let isOpen = place.isOpen {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isOpen ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(isOpen ? "Open" : "Closed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text(place.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let address = place.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let rating = place.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    if !distanceString.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(distanceString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let priceLevel = place.priceLevel {
                        Spacer()
                        Text(String(repeating: "$", count: priceLevel))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(width: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

