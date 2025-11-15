import Foundation
import UIKit

// MARK: - Seed Data Service for UI Showcase

class TokiSeedDataService {
    static let shared = TokiSeedDataService()
    
    private init() {}
    
    // Okinawa locations with coordinates - arranged in a logical travel path
    private let okinawaPlaces: [(name: String, lat: Double, lon: Double, categories: [String], description: String)] = [
        (
            name: "Naha Airport",
            lat: 26.1958,
            lon: 127.6456,
            categories: ["transport", "arrival"],
            description: "Starting point of your Okinawa adventure"
        ),
        (
            name: "Naha Castle Ruins",
            lat: 26.2167,
            lon: 127.7167,
            categories: ["culture", "historical", "view"],
            description: "Historic castle ruins with panoramic views of Naha"
        ),
        (
            name: "Asato Dojo",
            lat: 26.2133,
            lon: 127.6800,
            categories: ["culture", "hidden", "walk"],
            description: "Traditional karate dojo in the heart of Naha"
        ),
        (
            name: "Ogimi Village Farm to Table Experience",
            lat: 26.6833,
            lon: 128.1167,
            categories: ["food", "culture", "hidden"],
            description: "Authentic farm-to-table experience in the longevity village"
        ),
        (
            name: "Cape Hedo",
            lat: 26.8700,
            lon: 128.2633,
            categories: ["view", "sunset", "scenic drive"],
            description: "Northernmost point of Okinawa with stunning ocean views"
        ),
        (
            name: "Okinawa Churaumi Aquarium",
            lat: 26.6944,
            lon: 127.8772,
            categories: ["attraction", "family", "view"],
            description: "One of the world's largest aquariums"
        )
    ]
    
    // Hotels for the demo trip
    private let okinawaHotels: [(name: String, lat: Double, lon: Double, checkInDay: Int, checkOutDay: Int)] = [
        (
            name: "Naha Grand Hotel",
            lat: 26.2125,
            lon: 127.6800,
            checkInDay: -2, // 2 days ago
            checkOutDay: 0   // Today
        ),
        (
            name: "Okinawa Resort & Spa",
            lat: 26.7000,
            lon: 127.8500,
            checkInDay: 0,   // Today
            checkOutDay: 2   // 2 days from now
        )
    ]
    
    @MainActor
    func createSampleTrip() -> Trip {
        let storage = TokiStorageService.shared
        
        // Create trip
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        
        let trip = storage.createTrip(
            name: "Okinawa 2025",
            startDate: startDate,
            endDate: endDate
        )
        
        // Create places and cards
        var createdPlaces: [Place] = []
        
        // Create hotel check-ins first (they should appear early in the timeline)
        var hotelReservations: [Reservation] = []
        for hotelData in okinawaHotels {
            // Create hotel place
            let hotelPlace = storage.findOrCreatePlace(
                lat: hotelData.lat,
                lon: hotelData.lon,
                label: hotelData.name,
                categories: ["hotel", "accommodation"]
            )
            createdPlaces.append(hotelPlace)
            
            // Create check-in date
            let checkInDate = calendar.date(byAdding: .day, value: hotelData.checkInDay, to: Date()) ?? Date()
            let checkInTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: checkInDate) ?? checkInDate
            
            // Create check-out date
            let checkOutDate = calendar.date(byAdding: .day, value: hotelData.checkOutDay, to: Date()) ?? Date()
            let checkOutTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: checkOutDate) ?? checkOutDate
            
            // Create reservation
            let reservation = Reservation(
                type: .hotel,
                confirmationNumber: "OKN-\(Int.random(in: 1000...9999))",
                provider: "Booking.com",
                date: checkInDate,
                notes: "Check-in: \(DateFormatter.localizedString(from: checkInDate, dateStyle: .short, timeStyle: .none))\nCheck-out: \(DateFormatter.localizedString(from: checkOutDate, dateStyle: .short, timeStyle: .none))"
            )
            hotelReservations.append(reservation)
            
            // Create check-in card with properly formatted dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            let checkInText = """
            **\(hotelData.name)**
            
            🏨 **Check-in:** \(dateFormatter.string(from: checkInTime))
            🏨 **Check-out:** \(dateFormatter.string(from: checkOutTime))
            
            Confirmation: \(reservation.confirmationNumber)
            
            Your home base for exploring Okinawa!
            """
            
            let hotelCard = storage.createCard(
                tripId: trip.id,
                placeId: hotelPlace.id,
                kind: .photo, // Use photo kind so it shows on map
                takenAt: checkInTime,
                tags: ["hotel", "accommodation", "check-in"],
                text: checkInText
            )
            
            // Create a hotel-themed placeholder image
            if let imageData = createHotelPlaceholderImage(hotelName: hotelData.name) {
                let mediaId = storage.saveMedia(data: imageData, mime: "image/jpeg")
                var updatedCard = hotelCard
                updatedCard.mediaId = mediaId
                storage.updateCard(updatedCard)
            }
        }
        
        // Add reservations to trip
        var updatedTrip = trip
        updatedTrip.reservations = hotelReservations
        storage.updateTrip(updatedTrip)
        
        // Create cards in chronological order to form a clear path
        // Each place gets a card on sequential days to show the journey
        for (index, placeData) in okinawaPlaces.enumerated() {
            // Create place
            let place = storage.findOrCreatePlace(
                lat: placeData.lat,
                lon: placeData.lon,
                label: placeData.name,
                categories: placeData.categories
            )
            createdPlaces.append(place)
            
            // Create cards in chronological order (one per day, sequential)
            let dayOffset = index - 2 // Start 2 days ago, go forward
            let cardDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let hourOffset = 10 + (index * 2) // Spread times throughout the day
            let finalDate = calendar.date(byAdding: .hour, value: hourOffset, to: cardDate) ?? cardDate
            
            // Photo card
            let photoCard = storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .photo,
                takenAt: finalDate,
                tags: placeData.categories,
                text: placeData.description
            )
            
            // Create a simple colored image as placeholder
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple]
            if let imageData = createPlaceholderImage(color: colors[index % colors.count], text: placeData.name) {
                let mediaId = storage.saveMedia(data: imageData, mime: "image/jpeg")
                var updatedCard = photoCard
                updatedCard.mediaId = mediaId
                storage.updateCard(updatedCard)
            }
            
            // Note card for some places
            if index % 2 == 0 {
                let noteDate = calendar.date(byAdding: .hour, value: 2, to: finalDate) ?? finalDate
                storage.createCard(
                    tripId: trip.id,
                    placeId: place.id,
                    kind: .note,
                    takenAt: noteDate,
                    tags: ["food", "walk"],
                    text: "Must try the local specialties here!"
                )
            }
        }
        
        // Set cover photo
        if let firstCard = storage.getCardsForTrip(trip.id).first,
           let mediaId = firstCard.mediaId {
            var updatedTrip = trip
            updatedTrip.coverPhotoId = mediaId
            storage.updateTrip(updatedTrip)
        }
        
        return trip
    }
    
    private func createPlaceholderImage(color: UIColor, text: String) -> Data? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background
            color.withAlphaComponent(0.3).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedString.draw(in: textRect)
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
    
    private func createHotelPlaceholderImage(hotelName: String) -> Data? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Purple gradient background for hotels
            let colors = [UIColor.systemPurple.withAlphaComponent(0.8).cgColor, UIColor.systemPurple.withAlphaComponent(0.5).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])
            context.cgContext.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Bed icon
            if let bedIcon = UIImage(systemName: "bed.double.fill") {
                let iconSize: CGFloat = 120
                let iconRect = CGRect(
                    x: (size.width - iconSize) / 2,
                    y: (size.height - iconSize) / 2 - 40,
                    width: iconSize,
                    height: iconSize
                )
                bedIcon.withTintColor(.white).draw(in: iconRect)
            }
            
            // Hotel name
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let attributedString = NSAttributedString(string: hotelName, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height - 100,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedString.draw(in: textRect)
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
    
    @MainActor
    func hasSeededData() -> Bool {
        let storage = TokiStorageService.shared
        return storage.trips.contains { $0.name == "Okinawa 2025" }
    }
    
    @MainActor
    func seedIfNeeded() async {
        if !hasSeededData() {
            let storage = TokiStorageService.shared
            let trip = createSampleTrip()
            print("✅ Created seed trip: \(trip.name) with \(storage.getCardsForTrip(trip.id).count) cards")
        } else {
            print("ℹ️ Seed data already exists")
        }
    }
}

