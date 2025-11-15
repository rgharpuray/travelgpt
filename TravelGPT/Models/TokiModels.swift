import Foundation
import CoreLocation
import SwiftUI

// MARK: - Toki 2.0 Core Models

typealias TokiID = String

struct Trip: Identifiable, Codable {
    let id: TokiID
    var name: String
    var startDate: Date?
    var endDate: Date?
    var coverPhotoId: TokiID?
    var settings: TripSettings
    var companions: [TripCompanion]
    var reservations: [Reservation]
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, startDate, endDate, coverPhotoId, settings, companions, reservations, createdAt, updatedAt
    }
    
    init(id: TokiID = UUID().uuidString, name: String, startDate: Date? = nil, endDate: Date? = nil, coverPhotoId: TokiID? = nil, settings: TripSettings = TripSettings(), companions: [TripCompanion] = [], reservations: [Reservation] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.coverPhotoId = coverPhotoId
        self.settings = settings
        self.companions = companions
        self.reservations = reservations
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        coverPhotoId = try container.decodeIfPresent(String.self, forKey: .coverPhotoId)
        settings = try container.decode(TripSettings.self, forKey: .settings)
        companions = try container.decodeIfPresent([TripCompanion].self, forKey: .companions) ?? []
        reservations = try container.decodeIfPresent([Reservation].self, forKey: .reservations) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(coverPhotoId, forKey: .coverPhotoId)
        try container.encode(settings, forKey: .settings)
        try container.encode(companions, forKey: .companions)
        try container.encode(reservations, forKey: .reservations)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct TripCompanion: Identifiable, Codable {
    let id: TokiID
    var name: String
    var email: String?
    var phone: String?
    
    init(id: TokiID = UUID().uuidString, name: String, email: String? = nil, phone: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
    }
}

struct Reservation: Identifiable, Codable {
    let id: TokiID
    var type: ReservationType
    var confirmationNumber: String
    var provider: String? // e.g., "United Airlines", "Marriott"
    var date: Date?
    var notes: String?
    
    enum ReservationType: String, Codable {
        case flight = "flight"
        case hotel = "hotel"
        case restaurant = "restaurant"
        case activity = "activity"
        case car = "car"
        case other = "other"
    }
    
    init(id: TokiID = UUID().uuidString, type: ReservationType, confirmationNumber: String, provider: String? = nil, date: Date? = nil, notes: String? = nil) {
        self.id = id
        self.type = type
        self.confirmationNumber = confirmationNumber
        self.provider = provider
        self.date = date
        self.notes = notes
    }
}

struct TripSettings: Codable, Equatable {
    var distanceUnits: DistanceUnit = .km
    var autoReverseGeocode: Bool = true
    var enableSuggestions: Bool = true
    var hidePreciseLocation: Bool = false
    
    enum DistanceUnit: String, Codable {
        case km = "km"
        case mi = "mi"
    }
}

struct Place: Identifiable, Codable {
    let id: TokiID
    var label: String?
    var lat: Double
    var lon: Double
    var geohash5: String
    var providerKey: String?
    var categories: [String]
    var meta: PlaceMeta?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, label, lat, lon, geohash5, providerKey, categories, meta, createdAt, updatedAt
    }
    
    init(id: TokiID = UUID().uuidString, label: String? = nil, lat: Double, lon: Double, geohash5: String? = nil, providerKey: String? = nil, categories: [String] = [], meta: PlaceMeta? = nil) {
        self.id = id
        self.label = label
        self.lat = lat
        self.lon = lon
        self.geohash5 = geohash5 ?? Geohash.encode(latitude: lat, longitude: lon, length: 5)
        self.providerKey = providerKey
        self.categories = categories
        self.meta = meta
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        geohash5 = try container.decode(String.self, forKey: .geohash5)
        providerKey = try container.decodeIfPresent(String.self, forKey: .providerKey)
        categories = try container.decode([String].self, forKey: .categories)
        meta = try container.decodeIfPresent(PlaceMeta.self, forKey: .meta)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encode(lat, forKey: .lat)
        try container.encode(lon, forKey: .lon)
        try container.encode(geohash5, forKey: .geohash5)
        try container.encodeIfPresent(providerKey, forKey: .providerKey)
        try container.encode(categories, forKey: .categories)
        try container.encodeIfPresent(meta, forKey: .meta)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

struct PlaceMeta: Codable, Equatable {
    var address: String?
    var city: String?
    var hours: String?
    var phone: String?
    var website: String?
}

enum CardKind: String, Codable {
    case photo = "photo"
    case note = "note"
    case audio = "audio"
}

struct Card: Identifiable, Codable {
    let id: TokiID
    var tripId: TokiID
    var placeId: TokiID?
    var kind: CardKind
    var takenAt: Date
    var tags: [String]
    var text: String?
    var mediaId: TokiID?
    
    // Denormalized snapshot fields for export resilience
    var placeLabelAtSave: String?
    var coordsAtSave: Coordinates?
    
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, tripId, placeId, kind, takenAt, tags, text, mediaId, placeLabelAtSave, coordsAtSave, createdAt, updatedAt
    }
    
    init(id: TokiID = UUID().uuidString, tripId: TokiID, placeId: TokiID? = nil, kind: CardKind, takenAt: Date = Date(), tags: [String] = [], text: String? = nil, mediaId: TokiID? = nil, placeLabelAtSave: String? = nil, coordsAtSave: Coordinates? = nil) {
        self.id = id
        self.tripId = tripId
        self.placeId = placeId
        self.kind = kind
        self.takenAt = takenAt
        self.tags = tags
        self.text = text
        self.mediaId = mediaId
        self.placeLabelAtSave = placeLabelAtSave
        self.coordsAtSave = coordsAtSave
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        tripId = try container.decode(String.self, forKey: .tripId)
        placeId = try container.decodeIfPresent(String.self, forKey: .placeId)
        kind = try container.decode(CardKind.self, forKey: .kind)
        takenAt = try container.decode(Date.self, forKey: .takenAt)
        tags = try container.decode([String].self, forKey: .tags)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        mediaId = try container.decodeIfPresent(String.self, forKey: .mediaId)
        placeLabelAtSave = try container.decodeIfPresent(String.self, forKey: .placeLabelAtSave)
        coordsAtSave = try container.decodeIfPresent(Coordinates.self, forKey: .coordsAtSave)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tripId, forKey: .tripId)
        try container.encodeIfPresent(placeId, forKey: .placeId)
        try container.encode(kind, forKey: .kind)
        try container.encode(takenAt, forKey: .takenAt)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(mediaId, forKey: .mediaId)
        try container.encodeIfPresent(placeLabelAtSave, forKey: .placeLabelAtSave)
        try container.encodeIfPresent(coordsAtSave, forKey: .coordsAtSave)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct Coordinates: Codable, Equatable {
    var lat: Double
    var lon: Double
}

struct Media: Identifiable, Codable {
    let id: TokiID
    var mime: String
    var width: Int?
    var height: Int?
    var exif: MediaEXIF?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, mime, width, height, exif, createdAt
    }
    
    init(id: TokiID = UUID().uuidString, mime: String, width: Int? = nil, height: Int? = nil, exif: MediaEXIF? = nil) {
        self.id = id
        self.mime = mime
        self.width = width
        self.height = height
        self.exif = exif
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        mime = try container.decode(String.self, forKey: .mime)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        exif = try container.decodeIfPresent(MediaEXIF.self, forKey: .exif)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mime, forKey: .mime)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(exif, forKey: .exif)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct MediaEXIF: Codable, Equatable {
    var lat: Double?
    var lon: Double?
    var timestamp: Date?
    var camera: String?
    var iso: Int?
    var aperture: String?
    var shutterSpeed: String?
}

// MARK: - Geohash Implementation

struct Geohash {
    static let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"
    
    static func encode(latitude: Double, longitude: Double, length: Int = 5) -> String {
        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)
        var hash = ""
        var bits = 0
        var bit = 0
        var ch = 0
        
        while hash.count < length {
            if bits % 2 == 0 {
                let mid = (lonRange.0 + lonRange.1) / 2
                if longitude >= mid {
                    ch |= (1 << (4 - bit))
                    lonRange.0 = mid
                } else {
                    lonRange.1 = mid
                }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if latitude >= mid {
                    ch |= (1 << (4 - bit))
                    latRange.0 = mid
                } else {
                    latRange.1 = mid
                }
            }
            
            bit += 1
            if bit == 5 {
                let index = base32.index(base32.startIndex, offsetBy: ch)
                hash.append(base32[index])
                bit = 0
                ch = 0
            }
            bits += 1
        }
        
        return hash
    }
    
    static func decode(_ hash: String) -> (lat: Double, lon: Double)? {
        var latRange = (-90.0, 90.0)
        var lonRange = (-180.0, 180.0)
        var isEven = true
        
        for char in hash {
            guard let index = base32.firstIndex(of: char) else { return nil }
            var bits = base32.distance(from: base32.startIndex, to: index)
            
            for _ in 0..<5 {
                if isEven {
                    let mid = (lonRange.0 + lonRange.1) / 2
                    if bits & 0x10 != 0 {
                        lonRange.0 = mid
                    } else {
                        lonRange.1 = mid
                    }
                } else {
                    let mid = (latRange.0 + latRange.1) / 2
                    if bits & 0x10 != 0 {
                        latRange.0 = mid
                    } else {
                        latRange.1 = mid
                    }
                }
                bits <<= 1
                isEven.toggle()
            }
        }
        
        return ((latRange.0 + latRange.1) / 2, (lonRange.0 + lonRange.1) / 2)
    }
}

// MARK: - Export Models

struct TokiExport: Codable {
    var version: Int = 1
    var trip: Trip
    var places: [Place]
    var cards: [Card]
    var media: [Media]
    var mediaIndex: [MediaIndexEntry]
}

struct MediaIndexEntry: Codable {
    var mediaId: TokiID
    var filename: String
}

// MARK: - Tag Constants

struct TokiTags {
    static let availableTags = ["food", "beach", "walk", "view", "cafe", "market", "sunset", "hidden", "quiet", "lunch", "dinner", "breakfast"]
}

