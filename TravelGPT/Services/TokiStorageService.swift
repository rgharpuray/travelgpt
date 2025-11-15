import Foundation
import SwiftUI

// MARK: - Toki Storage Service

@MainActor
class TokiStorageService: ObservableObject {
    static let shared = TokiStorageService()
    
    @Published var trips: [Trip] = []
    @Published var activeTripId: TokiID?
    @Published var places: [Place] = []
    @Published var cards: [Card] = []
    @Published var media: [Media] = []
    
    private let documentsURL: URL
    private let tripsURL: URL
    private let placesURL: URL
    private let cardsURL: URL
    private let mediaURL: URL
    private let mediaDirectoryURL: URL
    
    private init() {
        let fileManager = FileManager.default
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        tripsURL = documentsURL.appendingPathComponent("trips.json")
        placesURL = documentsURL.appendingPathComponent("places.json")
        cardsURL = documentsURL.appendingPathComponent("cards.json")
        mediaURL = documentsURL.appendingPathComponent("media.json")
        mediaDirectoryURL = documentsURL.appendingPathComponent("media", isDirectory: true)
        
        // Create media directory if needed
        try? fileManager.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true)
        
        loadAll()
    }
    
    // MARK: - Active Trip
    
    var activeTrip: Trip? {
        guard let activeTripId = activeTripId else { return nil }
        return trips.first { $0.id == activeTripId }
    }
    
    var activeTripCards: [Card] {
        guard let activeTripId = activeTripId else { return [] }
        return cards.filter { $0.tripId == activeTripId }
            .sorted { $0.takenAt < $1.takenAt }
    }
    
    func setActiveTrip(_ tripId: TokiID) {
        activeTripId = tripId
        saveActiveTripId()
    }
    
    // MARK: - Trip Management
    
    func createTrip(name: String, startDate: Date? = nil, endDate: Date? = nil) -> Trip {
        let trip = Trip(name: name, startDate: startDate, endDate: endDate)
        trips.append(trip)
        saveTrips()
        
        if activeTripId == nil {
            setActiveTrip(trip.id)
        }
        
        return trip
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            var updated = trip
            updated.updatedAt = Date()
            trips[index] = updated
            saveTrips()
        }
    }
    
    func deleteTrip(_ tripId: TokiID) {
        trips.removeAll { $0.id == tripId }
        cards.removeAll { $0.tripId == tripId }
        saveTrips()
        saveCards()
        
        if activeTripId == tripId {
            activeTripId = trips.first?.id
            saveActiveTripId()
        }
    }
    
    // MARK: - Place Management
    
    func findOrCreatePlace(lat: Double, lon: Double, label: String? = nil, categories: [String] = []) -> Place {
        let geohash5 = Geohash.encode(latitude: lat, longitude: lon, length: 5)
        
        // Check for existing place within ~200m (geohash5 match)
        if let existing = places.first(where: { $0.geohash5 == geohash5 }) {
            return existing
        }
        
        // Create new place
        let place = Place(label: label, lat: lat, lon: lon, geohash5: geohash5, categories: categories)
        places.append(place)
        savePlaces()
        
        return place
    }
    
    func updatePlace(_ place: Place) {
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            var updated = place
            updated.updatedAt = Date()
            places[index] = updated
            savePlaces()
        }
    }
    
    func getPlace(_ placeId: TokiID) -> Place? {
        return places.first { $0.id == placeId }
    }
    
    func getPlaceForCard(_ card: Card) -> Place? {
        guard let placeId = card.placeId else { return nil }
        return getPlace(placeId)
    }
    
    // MARK: - Card Management
    
    func createCard(tripId: TokiID, placeId: TokiID? = nil, kind: CardKind, takenAt: Date = Date(), tags: [String] = [], text: String? = nil, mediaId: TokiID? = nil) -> Card {
        var placeLabel: String? = nil
        var coords: Coordinates? = nil
        
        if let placeId = placeId, let place = getPlace(placeId) {
            placeLabel = place.label
            coords = Coordinates(lat: place.lat, lon: place.lon)
        }
        
        let card = Card(
            tripId: tripId,
            placeId: placeId,
            kind: kind,
            takenAt: takenAt,
            tags: tags,
            text: text,
            mediaId: mediaId,
            placeLabelAtSave: placeLabel,
            coordsAtSave: coords
        )
        
        cards.append(card)
        saveCards()
        
        return card
    }
    
    func updateCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            var updated = card
            updated.updatedAt = Date()
            cards[index] = updated
            saveCards()
        }
    }
    
    func deleteCard(_ cardId: TokiID) {
        if let card = cards.first(where: { $0.id == cardId }) {
            // Delete associated media
            if let mediaId = card.mediaId {
                deleteMedia(mediaId)
            }
        }
        
        cards.removeAll { $0.id == cardId }
        saveCards()
    }
    
    func getCardsForTrip(_ tripId: TokiID) -> [Card] {
        return cards.filter { $0.tripId == tripId }
            .sorted { $0.takenAt < $1.takenAt }
    }
    
    func getCardsForPlace(_ placeId: TokiID) -> [Card] {
        return cards.filter { $0.placeId == placeId }
            .sorted { $0.takenAt < $1.takenAt }
    }
    
    // MARK: - Media Management
    
    func saveMedia(data: Data, mime: String, mediaId: TokiID? = nil) -> TokiID {
        let id = mediaId ?? UUID().uuidString
        let filename = "\(id).\(mimeExtension(for: mime))"
        let fileURL = mediaDirectoryURL.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
        
        let media = Media(id: id, mime: mime)
        if let existingIndex = self.media.firstIndex(where: { $0.id == id }) {
            self.media[existingIndex] = media
        } else {
            self.media.append(media)
        }
        
        saveMediaIndex()
        
        return id
    }
    
    func loadMedia(_ mediaId: TokiID) -> Data? {
        guard let media = self.media.first(where: { $0.id == mediaId }) else { return nil }
        let filename = "\(mediaId).\(mimeExtension(for: media.mime))"
        let fileURL = mediaDirectoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }
    
    func loadMediaImage(_ mediaId: TokiID) -> UIImage? {
        guard let data = loadMedia(mediaId) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteMedia(_ mediaId: TokiID) {
        guard let media = self.media.first(where: { $0.id == mediaId }) else { return }
        let filename = "\(mediaId).\(mimeExtension(for: media.mime))"
        let fileURL = mediaDirectoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        
        self.media.removeAll { $0.id == mediaId }
        saveMediaIndex()
    }
    
    private func mimeExtension(for mime: String) -> String {
        switch mime {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "image/heic": return "heic"
        case "audio/m4a": return "m4a"
        case "audio/webm": return "webm"
        default: return "bin"
        }
    }
    
    // MARK: - Persistence
    
    private func loadAll() {
        loadTrips()
        loadPlaces()
        loadCards()
        loadMediaIndex()
        loadActiveTripId()
    }
    
    private func loadTrips() {
        guard let data = try? Data(contentsOf: tripsURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Trip].self, from: data) else { return }
        trips = decoded
    }
    
    private func saveTrips() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(trips) else { return }
        try? encoded.write(to: tripsURL)
    }
    
    private func loadPlaces() {
        guard let data = try? Data(contentsOf: placesURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Place].self, from: data) else { return }
        places = decoded
    }
    
    private func savePlaces() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(places) else { return }
        try? encoded.write(to: placesURL)
    }
    
    private func loadCards() {
        guard let data = try? Data(contentsOf: cardsURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Card].self, from: data) else { return }
        cards = decoded
    }
    
    private func saveCards() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(cards) else { return }
        try? encoded.write(to: cardsURL)
    }
    
    private func loadMediaIndex() {
        guard let data = try? Data(contentsOf: mediaURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Media].self, from: data) else { return }
        media = decoded
    }
    
    private func saveMediaIndex() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(media) else { return }
        try? encoded.write(to: mediaURL)
    }
    
    private func loadActiveTripId() {
        activeTripId = UserDefaults.standard.string(forKey: "activeTripId")
    }
    
    private func saveActiveTripId() {
        if let activeTripId = activeTripId {
            UserDefaults.standard.set(activeTripId, forKey: "activeTripId")
        } else {
            UserDefaults.standard.removeObject(forKey: "activeTripId")
        }
    }
    
    // MARK: - Export/Import
    
    func exportTrip(_ tripId: TokiID) -> TokiExport? {
        guard let trip = trips.first(where: { $0.id == tripId }) else { return nil }
        
        let tripCards = getCardsForTrip(tripId)
        let tripPlaceIds = Set(tripCards.compactMap { $0.placeId })
        let tripPlaces = places.filter { tripPlaceIds.contains($0.id) }
        let tripMediaIds = Set(tripCards.compactMap { $0.mediaId })
        let tripMedia = media.filter { tripMediaIds.contains($0.id) }
        
        var mediaIndex: [MediaIndexEntry] = []
        for media in tripMedia {
            let filename = "\(media.id).\(mimeExtension(for: media.mime))"
            mediaIndex.append(MediaIndexEntry(mediaId: media.id, filename: filename))
        }
        
        return TokiExport(
            trip: trip,
            places: tripPlaces,
            cards: tripCards,
            media: tripMedia,
            mediaIndex: mediaIndex
        )
    }
    
    func importTrip(_ export: TokiExport) -> Trip {
        // Import places (merge if exists)
        for place in export.places {
            if places.first(where: { $0.id == place.id }) == nil {
                places.append(place)
            }
        }
        
        // Import media files
        for mediaEntry in export.mediaIndex {
            // Media files would need to be included in the import bundle
            // For now, we'll just import the metadata
            if media.first(where: { $0.id == mediaEntry.mediaId }) == nil {
                if let mediaItem = export.media.first(where: { $0.id == mediaEntry.mediaId }) {
                    media.append(mediaItem)
                }
            }
        }
        
        // Import trip (suffix if duplicate name)
        var tripName = export.trip.name
        var suffix = 2
        while trips.contains(where: { $0.name == tripName }) {
            tripName = "\(export.trip.name) \(suffix)"
            suffix += 1
        }
        
        // Create new trip with new ID
        let importedTrip = Trip(
            id: UUID().uuidString,
            name: tripName,
            startDate: export.trip.startDate,
            endDate: export.trip.endDate,
            coverPhotoId: export.trip.coverPhotoId,
            settings: export.trip.settings
        )
        
        // Import cards with new trip ID
        var importedCards: [Card] = []
        for card in export.cards {
            let newCard = Card(
                id: UUID().uuidString,
                tripId: importedTrip.id,
                placeId: card.placeId,
                kind: card.kind,
                takenAt: card.takenAt,
                tags: card.tags,
                text: card.text,
                mediaId: card.mediaId,
                placeLabelAtSave: card.placeLabelAtSave,
                coordsAtSave: card.coordsAtSave
            )
            importedCards.append(newCard)
        }
        
        trips.append(importedTrip)
        cards.append(contentsOf: importedCards)
        
        saveTrips()
        savePlaces()
        saveCards()
        saveMediaIndex()
        
        return importedTrip
    }
}

