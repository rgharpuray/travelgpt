import SwiftUI
import CoreLocation

struct TokiFeedView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var selectedDay: Date?
    @State private var showingCardDetail: Card?
    @State private var showingQuickInput = false
    @State private var quickInputText = ""
    @State private var collapsedPastDays: Set<Date> = []
    
    private var cards: [Card] {
        let tripCards = storage.getCardsForTrip(trip.id)
        
        if let selectedDay = selectedDay {
            let calendar = Calendar.current
            return tripCards.filter { calendar.isDate($0.takenAt, inSameDayAs: selectedDay) }
        }
        
        return tripCards
    }
    
    // Separate cards into past, today, and future
    private var pastCards: [Card] {
        let now = Date()
        return cards.filter { $0.takenAt < now }
    }
    
    private var todayCards: [Card] {
        let calendar = Calendar.current
        return cards.filter { calendar.isDateInToday($0.takenAt) }
    }
    
    private var futureCards: [Card] {
        let now = Date()
        return cards.filter { $0.takenAt > now }
    }
    
    private var days: [Date] {
        let tripCards = storage.getCardsForTrip(trip.id)
        let calendar = Calendar.current
        
        // Get all days between trip start and today (or trip end)
        var allDays: [Date] = []
        
        let startDate = trip.startDate ?? tripCards.first?.takenAt ?? Date()
        let endDate = trip.endDate ?? Date()
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        while currentDate <= endDay {
            allDays.append(currentDate)
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = calendar.startOfDay(for: nextDate)
            } else {
                break
            }
        }
        
        return allDays.sorted(by: <) // Oldest first
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Current Hotel indicator (if applicable)
                if let currentHotel = getCurrentHotel() {
                    CurrentHotelCard(hotel: currentHotel, trip: trip)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // "What to do now" adaptive card at the top
                WhatToDoNowCard(trip: trip)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Day Filter
                if !days.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: { selectedDay = nil }) {
                                Text("All")
                                    .font(.subheadline)
                                    .fontWeight(selectedDay == nil ? .semibold : .regular)
                                    .foregroundColor(selectedDay == nil ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedDay == nil ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(20)
                            }
                            
                            ForEach(days, id: \.self) { day in
                                let hasCards = groupedCards[day] != nil && !groupedCards[day]!.isEmpty
                                let isToday = Calendar.current.isDateInToday(day)
                                let isFuture = day > Date()
                                
                                Button(action: { selectedDay = day }) {
                                    VStack(spacing: 4) {
                                        Text(dayFormatter.string(from: day))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(dayNumberFormatter.string(from: day))
                                            .font(.headline)
                                    }
                                    .foregroundColor(selectedDay == day ? .white : (hasCards ? .primary : .secondary))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedDay == day ? Color.blue :
                                        (hasCards ? Color(.systemGray5) : Color(.systemGray6))
                                    )
                                    .overlay(
                                        // Dot indicator for days with cards
                                        hasCards ? Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                            .offset(x: 16, y: -16) : nil
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Today's cards (present moment - primary focus)
                if !todayCards.isEmpty {
                    DaySection(
                        day: Date(),
                        cards: todayCards.sorted { $0.takenAt < $1.takenAt },
                        trip: trip,
                        isCollapsed: false
                    )
                }
                
                // Future/Upcoming cards
                if !futureCards.isEmpty {
                    ForEach(futureDays, id: \.self) { day in
                        let calendar = Calendar.current
                        let dayCards = futureCards.filter { calendar.isDate($0.takenAt, inSameDayAs: day) }
                        if !dayCards.isEmpty {
                            DaySection(
                                day: day,
                                cards: dayCards.sorted { $0.takenAt < $1.takenAt },
                                trip: trip,
                                isCollapsed: false
                            )
                        }
                    }
                }
                
                // Empty state (only if no cards at all)
                if cards.isEmpty {
                    emptyState
                }
                
                // Past cards (collapsed, minimal, at bottom)
                if !pastCards.isEmpty {
                    CollapsedPastSection(
                        pastCards: pastCards,
                        collapsedDays: $collapsedPastDays,
                        trip: trip
                    )
                }
            }
        }
        .sheet(item: $showingCardDetail) { card in
            CardDetailView(card: card)
        }
        .safeAreaInset(edge: .bottom) {
            QuickInputBar(
                text: $quickInputText,
                isPresented: $showingQuickInput,
                onSubmit: handleQuickInput
            )
        }
    }
    
    private var groupedCards: [Date: [Card]] {
        let calendar = Calendar.current
        return Dictionary(grouping: cards) { calendar.startOfDay(for: $0.takenAt) }
    }
    
    private var futureDays: [Date] {
        let calendar = Calendar.current
        let futureCards = cards.filter { $0.takenAt > Date() }
        let uniqueDays = Set(futureCards.map { calendar.startOfDay(for: $0.takenAt) })
        return Array(uniqueDays).sorted()
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No cards yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to add your first card")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    // Get current active hotel based on check-in/check-out dates
    private func getCurrentHotel() -> (card: Card, place: Place, checkOut: Date?)? {
        let now = Date()
        let calendar = Calendar.current
        
        // Find hotel cards with check-in tags
        let hotelCards = cards.filter { card in
            card.tags.contains("hotel") || card.tags.contains("accommodation") || card.tags.contains("check-in")
        }
        
        // Try to find current hotel from cards (parse check-out date from text)
        for card in hotelCards.sorted(by: { $0.takenAt > $1.takenAt }) {
            guard let placeId = card.placeId,
                  let place = storage.getPlace(placeId) else { continue }
            
            // Parse check-out date from card text
            var checkOutDate: Date? = nil
            if let text = card.text {
                // Look for check-out date in text
                let lines = text.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("Check-out") || line.contains("check-out") {
                        // Try to extract date - look for date after "Check-out:"
                        if let colonRange = line.range(of: ":") {
                            let afterColon = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            formatter.timeStyle = .short
                            if let date = formatter.date(from: afterColon) {
                                checkOutDate = date
                            } else {
                                // Try without time
                                formatter.timeStyle = .none
                                checkOutDate = formatter.date(from: afterColon)
                            }
                        }
                    }
                }
            }
            
            // If check-in date is in the past and check-out is in the future (or not specified), it's current
            if card.takenAt <= now {
                if let checkOut = checkOutDate {
                    if checkOut > now {
                        return (card, place, checkOut)
                    }
                } else {
                    // No check-out date found, assume it's current if check-in was recent (within last 7 days)
                    if calendar.dateComponents([.day], from: card.takenAt, to: now).day ?? 0 <= 7 {
                        return (card, place, nil)
                    }
                }
            }
        }
        
        // Fallback: check reservations
        for reservation in trip.reservations where reservation.type == .hotel {
            if let reservationDate = reservation.date,
               reservationDate <= now {
                // Find the corresponding card
                if let card = hotelCards.first(where: { 
                    abs($0.takenAt.timeIntervalSince(reservationDate)) < 3600 // Within 1 hour
                }),
                   let placeId = card.placeId,
                   let place = storage.getPlace(placeId) {
                    return (card, place, nil)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Quick Input Handler
    
    private func handleQuickInput() {
        guard !quickInputText.isEmpty else { return }
        
        Task {
            let processed = await TokiAIService.shared.processUserInput(quickInputText, for: trip)
            
            await MainActor.run {
                switch processed {
                case .note(let text):
                    // Create note card
                    let card = storage.createCard(
                        tripId: trip.id,
                        kind: .note,
                        takenAt: selectedDay ?? Date(),
                        tags: [],
                        text: text
                    )
                    quickInputText = ""
                    
                case .place(let info):
                    // Create place card
                    if let placeName = info.name {
                        // Search for place and create card
                        Task {
                            let results = await PlaceSearchService.shared.searchPlaces(query: placeName)
                            if let result = results.first {
                                let place = storage.findOrCreatePlace(
                                    lat: result.lat,
                                    lon: result.lon,
                                    label: result.name
                                )
                                
                                await MainActor.run {
                                    storage.createCard(
                                        tripId: trip.id,
                                        placeId: place.id,
                                        kind: .note,
                                        takenAt: selectedDay ?? Date(),
                                        tags: [],
                                        text: info.description
                                    )
                                    quickInputText = ""
                                }
                            }
                        }
                    }
                    
                case .flight(let flightInfo):
                    // Create flight card (as note for now)
                    var flightText = "Flight"
                    if let dest = flightInfo.destination {
                        flightText += " to \(dest)"
                    }
                    if let date = flightInfo.date {
                        flightText += " on \(dateFormatter.string(from: date))"
                    }
                    
                    storage.createCard(
                        tripId: trip.id,
                        kind: .note,
                        takenAt: flightInfo.date ?? selectedDay ?? Date(),
                        tags: ["flight"],
                        text: flightText
                    )
                    quickInputText = ""
                    
                case .hotel(let hotelInfo):
                    // Create hotel card
                    var hotelText = "Hotel"
                    if let name = hotelInfo.name {
                        hotelText = name
                    }
                    
                    storage.createCard(
                        tripId: trip.id,
                        kind: .note,
                        takenAt: hotelInfo.checkIn ?? selectedDay ?? Date(),
                        tags: ["hotel"],
                        text: hotelText
                    )
                    quickInputText = ""
                    
                case .meal(let mealInfo):
                    // Create meal card
                    var mealText = mealInfo.type.capitalized
                    if let place = mealInfo.place {
                        mealText += " at \(place)"
                    }
                    
                    storage.createCard(
                        tripId: trip.id,
                        kind: .note,
                        takenAt: mealInfo.time ?? selectedDay ?? Date(),
                        tags: ["food", mealInfo.type],
                        text: mealText
                    )
                    quickInputText = ""
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct DaySection: View {
    let day: Date
    let cards: [Card]
    let trip: Trip
    let isCollapsed: Bool
    @StateObject private var storage = TokiStorageService.shared
    
    // Insert transport cards between activities that have locations
    private func insertTransportCards(cards: [Card], trip: Trip) -> [Card] {
        var result: [Card] = []
        
        for (index, card) in cards.enumerated() {
            result.append(card)
            
            // Check if there's a next card with a location
            if index < cards.count - 1 {
                let nextCard = cards[index + 1]
                
                // Both cards need to have places
                if let currentPlaceId = card.placeId,
                   let nextPlaceId = nextCard.placeId,
                   let currentPlace = storage.getPlace(currentPlaceId),
                   let nextPlace = storage.getPlace(nextPlaceId),
                   currentPlace.lat != 0 && currentPlace.lon != 0,
                   nextPlace.lat != 0 && nextPlace.lon != 0 {
                    
                    // Don't create transport if current card is already a transport card
                    if !card.tags.contains("transport") {
                        let transport = TransportService.shared.calculateTransport(
                            from: (lat: currentPlace.lat, lon: currentPlace.lon, name: currentPlace.label),
                            to: (lat: nextPlace.lat, lon: nextPlace.lon, name: nextPlace.label),
                            destination: trip.name
                        )
                        
                        // Create a transport card (virtual - not saved, just for display)
                        let transportCard = Card(
                            tripId: card.tripId,
                            kind: .note,
                            takenAt: card.takenAt.addingTimeInterval(3600), // 1 hour after current card
                            tags: ["transport", transport.method.rawValue],
                            text: "🚶 **Transport**\n\n\(transport.instructions)\n\nDistance: \(String(format: "%.1f", transport.distance / 1000.0)) km"
                        )
                        
                        result.append(transportCard)
                    }
                }
            }
        }
        
        return result
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    
    private var isFuture: Bool {
        day > Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayFormatter.string(from: day))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isToday {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if isFuture {
                        Text("Upcoming")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if !cards.isEmpty {
                    Text("\(cards.count) card\(cards.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Cards or Empty State
            if cards.isEmpty {
                EmptyDayCard(day: day, trip: trip)
            } else {
                // Insert transport cards between activities
                let cardsWithTransport = insertTransportCards(cards: cards, trip: trip)
                ForEach(cardsWithTransport) { card in
                    CardRow(card: card)
                }
            }
        }
    }
}

struct EmptyDayCard: View {
    let day: Date
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    
    private var isFuture: Bool {
        day > Date()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isFuture ? "calendar" : "map")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 4) {
                    if isFuture {
                        Text("Upcoming Day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Your itinerary will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No cards this day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Tap + to add a card")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Placeholder for auto-generated itinerary
            if isFuture {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("Suggested Itinerary")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ItineraryPlaceholderItem(time: "9:00 AM", title: "Morning Activity", icon: "sunrise")
                        ItineraryPlaceholderItem(time: "12:00 PM", title: "Lunch Spot", icon: "fork.knife")
                        ItineraryPlaceholderItem(time: "3:00 PM", title: "Afternoon Exploration", icon: "map")
                        ItineraryPlaceholderItem(time: "7:00 PM", title: "Dinner & Evening", icon: "moon.stars")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

struct ItineraryPlaceholderItem: View {
    let time: String
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue.opacity(0.6))
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct CardRow: View {
    let card: Card
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingDetail = false
    
    private var place: Place? {
        guard let placeId = card.placeId else { return nil }
        return storage.getPlace(placeId)
    }
    
    private var image: UIImage? {
        guard let mediaId = card.mediaId else { return nil }
        return storage.loadMediaImage(mediaId)
    }
    
    private var isHotel: Bool {
        card.tags.contains { tag in
            tag.lowercased() == "hotel" || tag.lowercased() == "accommodation" || tag.lowercased() == "lodging"
        } || (place?.categories.contains { category in
            category.lowercased() == "hotel" || category.lowercased() == "accommodation" || category.lowercased() == "lodging"
        } ?? false)
    }
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.3)
                            .overlay(
                                Image(systemName: isHotel ? "bed.double.fill" : iconForKind(card.kind))
                                    .foregroundColor(isHotel ? .purple.opacity(0.7) : .white.opacity(0.7))
                            )
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        // Hotel icon or card kind icon
                        if isHotel {
                            Image(systemName: "bed.double.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        } else {
                            Image(systemName: iconForKind(card.kind))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if isHotel {
                            Text("Hotel Stay")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        } else {
                            Text(card.kind.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(timeFormatter.string(from: card.takenAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let text = card.text, !text.isEmpty {
                        // Show first line or title for AI-discovered places
                        let firstLine = text.components(separatedBy: .newlines).first ?? text
                        let displayText = firstLine.replacingOccurrences(of: "**", with: "")
                        Text(displayText)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                    }
                    
                    if let place = place {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(place.label ?? "Unknown Place")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if !card.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(card.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            CardDetailView(card: card)
        }
    }
    
    private func iconForKind(_ kind: CardKind) -> String {
        switch kind {
        case .photo: return "photo.fill"
        case .note: return card.tags.contains("transport") ? "arrow.right.circle.fill" : "note.text"
        case .audio: return "waveform"
        }
    }
    
    private var isTransportCard: Bool {
        card.tags.contains("transport")
    }
    
    private var backgroundColor: Color {
        if isTransportCard {
            return Color.green.opacity(0.1)
        } else if isHotel {
            return Color.purple.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if isTransportCard {
            return Color.green.opacity(0.3)
        } else if isHotel {
            return Color.purple.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CardDetailView: View {
    let card: Card
    @StateObject private var storage = TokiStorageService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var nearbyPlaces: [NearbyPlace] = []
    @State private var isLoadingNearby = false
    @State private var selectedCategory: NearbyPlace.PlaceCategory = .attraction
    
    private var place: Place? {
        guard let placeId = card.placeId else { return nil }
        return storage.getPlace(placeId)
    }
    
    private var image: UIImage? {
        guard let mediaId = card.mediaId else { return nil }
        return storage.loadMediaImage(mediaId)
    }
    
    private var cardLocation: CLLocationCoordinate2D? {
        guard let place = place, place.lat != 0 && place.lon != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        // Time
                        HStack {
                            Image(systemName: "clock.fill")
                            Text(dateTimeFormatter.string(from: card.takenAt))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        // Place
                        if let place = place {
                            HStack {
                                Image(systemName: "location.fill")
                                Text(place.label ?? "Unknown Place")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        // Text - parse and display rich content
                        if let text = card.text, !text.isEmpty {
                            RichCardTextView(text: text, place: place)
                        }
                        
                        // Tags
                        if !card.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(card.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Nearby Activities Section
                    if let location = cardLocation {
                        nearbyActivitiesSection(location: location)
                    }
                }
            }
            .navigationTitle(card.kind.rawValue.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let location = cardLocation {
                    loadNearbyPlaces(location: location)
                }
            }
            .onChange(of: selectedCategory) { _ in
                if let location = cardLocation {
                    loadNearbyPlaces(location: location)
                }
            }
        }
    }
    
    // MARK: - Nearby Activities Section
    
    private func nearbyActivitiesSection(location: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                Text("Nearby Activities")
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
            }
            .padding(.horizontal)
            
            if isLoadingNearby {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if nearbyPlaces.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "mappin.slash")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No nearby \(selectedCategory.rawValue)s found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyPlaces) { place in
                            NearbyPlaceCardForDetail(place: place, card: card)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func loadNearbyPlaces(location: CLLocationCoordinate2D) {
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
    
    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Nearby Place Card for Detail View

struct NearbyPlaceCardForDetail: View {
    let place: NearbyPlace
    let card: Card
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
                tripId: card.tripId,
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

// MARK: - Rich Card Text View

struct RichCardTextView: View {
    let text: String
    let place: Place?
    @State private var googleMapsURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let sections = parseText(text)
            
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                switch section.type {
                case .title:
                    Text(section.content)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                case .rating:
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(section.content)
                            .font(.headline)
                    }
                    .padding(.bottom, 4)
                    
                case .address:
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(section.content)
                            .font(.subheadline)
                    }
                    .padding(.bottom, 4)
                    
                case .duration:
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.purple)
                        Text(section.content)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.bottom, 4)
                    
                case .sectionHeader:
                    Text(section.content)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                case .tip:
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(section.content)
                            .font(.subheadline)
                            .italic()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    
                case .googleMaps:
                    if let url = extractGoogleMapsURL(from: section.content) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Open in Google Maps")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                case .regular:
                    Text(section.content)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func parseText(_ text: String) -> [TextSection] {
        var sections: [TextSection] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Title (bold at start)
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && !trimmed.contains("Why go") && !trimmed.contains("What to expect") && !trimmed.contains("Tip") {
                let content = trimmed.replacingOccurrences(of: "**", with: "")
                sections.append(TextSection(type: .title, content: content))
            }
            // Rating
            else if trimmed.hasPrefix("⭐") {
                let content = trimmed.replacingOccurrences(of: "⭐", with: "").trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .rating, content: content))
            }
            // Address
            else if trimmed.hasPrefix("📍") {
                let content = trimmed.replacingOccurrences(of: "📍", with: "").trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .address, content: content))
            }
            // Duration
            else if trimmed.contains("⏱️") && trimmed.contains("Estimated duration") {
                let content = trimmed.replacingOccurrences(of: "⏱️", with: "")
                    .replacingOccurrences(of: "**Estimated duration:**", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .duration, content: content))
            }
            // Section headers
            else if trimmed.hasPrefix("**Why go:**") {
                let content = trimmed.replacingOccurrences(of: "**Why go:**", with: "").trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .sectionHeader, content: "Why go"))
                sections.append(TextSection(type: .regular, content: content))
            }
            else if trimmed.hasPrefix("**What to expect:**") {
                let content = trimmed.replacingOccurrences(of: "**What to expect:**", with: "").trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .sectionHeader, content: "What to expect"))
                sections.append(TextSection(type: .regular, content: content))
            }
            // Tip
            else if trimmed.contains("💡") && trimmed.contains("**Tip:**") {
                let content = trimmed.replacingOccurrences(of: "💡", with: "")
                    .replacingOccurrences(of: "**Tip:**", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                sections.append(TextSection(type: .tip, content: content))
            }
            // Google Maps link
            else if trimmed.contains("🗺️") && trimmed.contains("Open in Google Maps") {
                sections.append(TextSection(type: .googleMaps, content: trimmed))
            }
            // Regular text
            else {
                let cleaned = trimmed.replacingOccurrences(of: "**", with: "")
                if !cleaned.isEmpty {
                    sections.append(TextSection(type: .regular, content: cleaned))
                }
            }
        }
        
        return sections
    }
    
    private func extractGoogleMapsURL(from text: String) -> URL? {
        // Extract URL from markdown link format: [text](url)
        if let range = text.range(of: #"\(([^)]+)\)"#, options: .regularExpression) {
            let urlString = String(text[range])
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            return URL(string: urlString)
        }
        return nil
    }
}

struct TextSection {
    let type: SectionType
    let content: String
}

enum SectionType {
    case title
    case rating
    case address
    case duration
    case sectionHeader
    case tip
    case googleMaps
    case regular
}

// MARK: - Current Hotel Card

struct CurrentHotelCard: View {
    let hotel: (card: Card, place: Place, checkOut: Date?)
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    
    private var checkOutText: String {
        if let checkOut = hotel.checkOut {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: checkOut)
        }
        return "Not specified"
    }
    
    private var daysRemaining: Int? {
        guard let checkOut = hotel.checkOut else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: checkOut).day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Hotel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(hotel.place.label ?? "Hotel")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let days = daysRemaining {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(days)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        Text("days left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(checkOutText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let address = hotel.place.meta?.address {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(address)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Quick Input Bar

struct QuickInputBar: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { isPresented.toggle() }) {
                Image(systemName: isPresented ? "xmark" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            if isPresented {
                TextField("Just tell me what to add...", text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        onSubmit()
                    }
                
                if !text.isEmpty {
                    Button(action: onSubmit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("Tap to add something")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

