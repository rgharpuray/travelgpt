import SwiftUI
import CoreLocation

// MARK: - Adaptive "What to do now" Card

struct WhatToDoNowCard: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @StateObject private var locationService = TokiLocationService.shared
    @State private var isExpanded = false
    @State private var isDiscoveringWithGPT = false
    @State private var uniqueTopActivities: [RichActivitySuggestion] = []
    @State private var isLoadingTopActivities = false
    @State private var showingQuickDiscover = false
    @State private var discoveryStatus: DiscoveryStatus = .idle
    @State private var currentLocationName: String?
    
    enum DiscoveryStatus {
        case idle
        case gettingLocation
        case discovering
        case found(Int) // number of activities found
        case error(String)
    }
    
    private var todayCards: [Card] {
        let tripCards = storage.getCardsForTrip(trip.id)
        let calendar = Calendar.current
        return tripCards.filter { calendar.isDateInToday($0.takenAt) }
            .sorted { $0.takenAt < $1.takenAt }
    }
    
    private var lastCard: Card? {
        todayCards.last
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("What to do now?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !isExpanded {
                    Button(action: {
                        withAnimation {
                            isExpanded = true
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        withAnimation {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Quick actions (always visible)
            if let lastCard = lastCard, let placeId = lastCard.placeId, let place = storage.getPlace(placeId) {
                InteractiveDiscoverButton(
                    icon: "wand.and.stars",
                    title: "Discover nearby",
                    subtitle: "Based on: \(place.label ?? "your last activity")",
                    color: .purple,
                    status: discoveryStatus,
                    activities: uniqueTopActivities
                ) {
                    // Only discover if we don't have activities yet
                    if uniqueTopActivities.isEmpty {
                        discoverNearbyWithGPT()
                    } else {
                        // If we have activities, just expand to show them
                        withAnimation {
                            isExpanded = true
                        }
                    }
                }
            } else {
                InteractiveDiscoverButton(
                    icon: "sparkles",
                    title: "Discover activities",
                    subtitle: currentLocationName ?? "Find unique things to do in \(trip.name)",
                    color: .blue,
                    status: discoveryStatus,
                    activities: uniqueTopActivities
                ) {
                    // Only discover if we don't have activities yet
                    if uniqueTopActivities.isEmpty {
                        loadUniqueTopActivities()
                    } else {
                        // If we have activities, just expand to show them
                        withAnimation {
                            isExpanded = true
                        }
                    }
                }
            }
            
            // Show activities immediately after discovery (always visible if we have them)
            if !uniqueTopActivities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(uniqueTopActivities.count) activities found")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !isExpanded {
                            Button(action: {
                                withAnimation {
                                    isExpanded = true
                                }
                            }) {
                                Text("Show all")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(uniqueTopActivities) { activity in
                                CompactActivityCard(activity: activity, trip: trip)
                            }
                        }
                    }
                    
                    if isLoadingTopActivities || isDiscoveringWithGPT {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Finding more activities...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Destination tips (if available)
                    let tips = DestinationTipsService.shared.getDestinationTips(for: trip.name)
                    if !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Quick Tips")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            ForEach(tips.prefix(3), id: \.self) { tip in
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // All unique activities in expanded view
                    if !uniqueTopActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All Activities")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(uniqueTopActivities) { activity in
                                        CompactActivityCard(activity: activity, trip: trip)
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            // Start location updates
            locationService.startUpdatingLocation()
            
            // Update location name based on current location
            if let currentLocation = locationService.currentLocation {
                currentLocationName = "Near you"
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if newLocation != nil {
                currentLocationName = "Near you"
            }
        }
    }
    
    private func discoverNearbyWithGPT() {
        guard let lastCard = lastCard,
              let placeId = lastCard.placeId,
              let place = storage.getPlace(placeId),
              place.lat != 0 && place.lon != 0 else {
            discoveryStatus = .error("No location found")
            return
        }
        
        isDiscoveringWithGPT = true
        discoveryStatus = .discovering
        uniqueTopActivities = [] // Clear previous results
        
        Task {
            // First, get nearby activities
            let location: (lat: Double, lon: Double) = (lat: place.lat, lon: place.lon)
            
            let activities = await TokiAIService.shared.fetchUniqueTopActivities(
                destination: place.label ?? trip.name,
                location: location,
                tripId: trip.id
            )
            
            await MainActor.run {
                uniqueTopActivities = activities
                if !activities.isEmpty {
                    discoveryStatus = .found(activities.count)
                    // Auto-expand to show results
                    withAnimation {
                        isExpanded = true
                    }
                } else {
                    discoveryStatus = .error("No activities found")
                }
                isDiscoveringWithGPT = false
            }
        }
    }
    
    private func loadUniqueTopActivities() {
        isLoadingTopActivities = true
        discoveryStatus = .gettingLocation
        uniqueTopActivities = [] // Clear previous results
        
        Task {
            // Try to get current location first
            var location: (lat: Double, lon: Double)? = nil
            var locationName = trip.name
            
            // Priority 1: Current device location
            if let currentLocation = locationService.currentLocation {
                location = (lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude)
                locationName = "your current location"
                await MainActor.run {
                    currentLocationName = "Near you"
                    discoveryStatus = .discovering
                }
            }
            // Priority 2: Last card location
            else if let lastCard = lastCard,
                    let placeId = lastCard.placeId,
                    let place = storage.getPlace(placeId),
                    place.lat != 0 && place.lon != 0 {
                location = (lat: place.lat, lon: place.lon)
                locationName = place.label ?? trip.name
                await MainActor.run {
                    currentLocationName = "Near \(place.label ?? "your last activity")"
                    discoveryStatus = .discovering
                }
            }
            // Priority 3: Trip destination
            else {
                // Search for destination place
                let tripNameLower = trip.name.lowercased()
                if let destinationPlace = storage.places.first(where: { place in
                    guard place.lat != 0 && place.lon != 0 else { return false }
                    if let label = place.label?.lowercased() {
                        return label.contains(tripNameLower) || tripNameLower.contains(label)
                    }
                    return false
                }) {
                    location = (lat: destinationPlace.lat, lon: destinationPlace.lon)
                    locationName = destinationPlace.label ?? trip.name
                    await MainActor.run {
                        currentLocationName = "In \(trip.name)"
                        discoveryStatus = .discovering
                    }
                } else {
                    await MainActor.run {
                        currentLocationName = "In \(trip.name)"
                        discoveryStatus = .discovering
                    }
                }
            }
            
            let activities = await TokiAIService.shared.fetchUniqueTopActivities(
                destination: locationName,
                location: location,
                tripId: trip.id
            )
            
            await MainActor.run {
                uniqueTopActivities = activities
                if !activities.isEmpty {
                    discoveryStatus = .found(activities.count)
                    // Auto-expand to show results
                    withAnimation {
                        isExpanded = true
                    }
                } else {
                    discoveryStatus = .error("No activities found")
                }
                isLoadingTopActivities = false
            }
        }
    }
}

struct InteractiveDiscoverButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let status: WhatToDoNowCard.DiscoveryStatus
    let activities: [RichActivitySuggestion]
    let action: () -> Void
    
    private var statusText: String? {
        switch status {
        case .idle:
            return nil
        case .gettingLocation:
            return "Getting your location..."
        case .discovering:
            return "Discovering activities..."
        case .found(let count):
            return "Found \(count) activities"
        case .error(let message):
            return message
        }
    }
    
    private var isLoading: Bool {
        switch status {
        case .gettingLocation, .discovering:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(color)
                        .cornerRadius(12)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let statusText = statusText {
                        HStack(spacing: 4) {
                            if case .found = status {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else if case .error = status {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            
                            Text(statusText)
                                .font(.caption2)
                                .foregroundColor(statusColor)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                if !isLoading {
                    if !activities.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(statusColor.opacity(0.3), lineWidth: isLoading ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
    
    private var statusColor: Color {
        switch status {
        case .idle, .gettingLocation, .discovering:
            return .blue
        case .found:
            return .green
        case .error:
            return .red
        }
    }
}

struct CompactActivityCard: View {
    let activity: RichActivitySuggestion
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    var body: some View {
        Button(action: {
            // Quick add to trip
            let place = storage.findOrCreatePlace(
                lat: activity.latitude,
                lon: activity.longitude,
                label: activity.name,
                categories: [activity.category]
            )
            
            let activityDuration = TransportService.shared.estimateActivityDuration(category: activity.category)
            let durationMinutes = Int(activityDuration / 60)
            
            var cardText = "**\(activity.name)**\n\n"
            if let rating = activity.rating {
                cardText += "⭐ \(String(format: "%.1f", rating))\n\n"
            }
            if let address = activity.address {
                cardText += "📍 \(address)\n\n"
            }
            cardText += "⏱️ **Estimated duration:** \(durationMinutes) minutes\n\n"
            cardText += "**Why go:** \(activity.whyGo)\n\n"
            cardText += "**What to expect:** \(activity.whatToExpect)\n\n"
            if let tip = activity.tip {
                cardText += "💡 **Tip:** \(tip)\n\n"
            }
            
            storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .note,
                takenAt: Date(),
                tags: [activity.category, "unique", "top-activity"],
                text: cardText
            )
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if let rating = activity.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
                
                Text(activity.whyGo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 160)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Collapsed Past Section

struct CollapsedPastSection: View {
    let pastCards: [Card]
    @Binding var collapsedDays: Set<Date>
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var isExpanded = false
    
    private var groupedByDay: [Date: [Card]] {
        let calendar = Calendar.current
        return Dictionary(grouping: pastCards) { calendar.startOfDay(for: $0.takenAt) }
    }
    
    private var sortedDays: [Date] {
        Array(groupedByDay.keys).sorted(by: >) // Most recent first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Small gray collapsed row
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Past")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("\(pastCards.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedDays, id: \.self) { day in
                        let dayCards = groupedByDay[day] ?? []
                        let dayIsCollapsed = collapsedDays.contains(day)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation {
                                    if dayIsCollapsed {
                                        collapsedDays.remove(day)
                                    } else {
                                        collapsedDays.insert(day)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(dayFormatter.string(from: day))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(dayCards.count) card\(dayCards.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: dayIsCollapsed ? "chevron.right" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if !dayIsCollapsed {
                                ForEach(dayCards.sorted { $0.takenAt < $1.takenAt }) { card in
                                    CardRow(card: card)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 16)
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

