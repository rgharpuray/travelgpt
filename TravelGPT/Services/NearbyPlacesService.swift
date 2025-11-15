import Foundation
import CoreLocation

// MARK: - Nearby Places Service

struct NearbyPlace: Identifiable {
    let id: String
    let name: String
    let address: String?
    let lat: Double
    let lon: Double
    let category: PlaceCategory
    let rating: Double?
    let priceLevel: Int? // 0-4, where 4 is most expensive
    let distance: Double? // in meters
    let isOpen: Bool?
    
    enum PlaceCategory: String, CaseIterable {
        case restaurant = "restaurant"
        case cafe = "cafe"
        case bar = "bar"
        case attraction = "attraction"
        case activity = "activity"
        case shopping = "shopping"
        case hotel = "hotel"
        case other = "other"
        
        var icon: String {
            switch self {
            case .restaurant: return "fork.knife"
            case .cafe: return "cup.and.saucer.fill"
            case .bar: return "wineglass.fill"
            case .attraction: return "camera.fill"
            case .activity: return "figure.walk"
            case .shopping: return "bag.fill"
            case .hotel: return "bed.double.fill"
            case .other: return "mappin"
            }
        }
        
        var googleType: String {
            switch self {
            case .restaurant: return "restaurant"
            case .cafe: return "cafe"
            case .bar: return "bar"
            case .attraction: return "tourist_attraction"
            case .activity: return "amusement_park|gym|park"
            case .shopping: return "shopping_mall|store"
            case .hotel: return "lodging"
            case .other: return "point_of_interest"
            }
        }
    }
}

class NearbyPlacesService {
    static let shared = NearbyPlacesService()
    
    private let keychain = KeychainManager.shared
    
    private init() {}
    
    // MARK: - Find Nearby Places
    
    func findNearby(
        location: CLLocationCoordinate2D,
        category: NearbyPlace.PlaceCategory,
        radius: Int = 2000, // meters
        limit: Int = 10
    ) async -> [NearbyPlace] {
        // Try Google Places API first if key is available
        if let apiKey = keychain.getGoogleMapsKey(), !apiKey.isEmpty {
            if let places = await fetchGooglePlaces(
                location: location,
                category: category,
                radius: radius,
                limit: limit,
                apiKey: apiKey
            ) {
                return places
            }
        }
        
        // Fallback to OpenStreetMap
        return await fetchOSMNearby(
            location: location,
            category: category,
            radius: radius,
            limit: limit
        )
    }
    
    // MARK: - Google Places API
    
    private func fetchGooglePlaces(
        location: CLLocationCoordinate2D,
        category: NearbyPlace.PlaceCategory,
        radius: Int,
        limit: Int,
        apiKey: String
    ) async -> [NearbyPlace]? {
        let types = category.googleType.components(separatedBy: "|").first ?? category.googleType
        
        let urlString = "\(Config.googlePlacesBaseURL)/nearbysearch/json?location=\(location.latitude),\(location.longitude)&radius=\(radius)&type=\(types)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let results = json?["results"] as? [[String: Any]] else {
                return nil
            }
            
            return results.prefix(limit).compactMap { result in
                guard let placeId = result["place_id"] as? String,
                      let name = result["name"] as? String,
                      let geometry = result["geometry"] as? [String: Any],
                      let placeLocationDict = geometry["location"] as? [String: Any],
                      let lat = placeLocationDict["lat"] as? Double,
                      let lon = placeLocationDict["lng"] as? Double else {
                    return nil
                }
                
                let address = result["vicinity"] as? String
                let rating = result["rating"] as? Double
                let priceLevel = result["price_level"] as? Int
                
                // Calculate distance
                let placeLocation = CLLocation(latitude: lat, longitude: lon)
                let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                let distance = placeLocation.distance(from: userLocation)
                
                // Check if open
                let openingHours = result["opening_hours"] as? [String: Any]
                let isOpen = openingHours?["open_now"] as? Bool
                
                return NearbyPlace(
                    id: placeId,
                    name: name,
                    address: address,
                    lat: lat,
                    lon: lon,
                    category: category,
                    rating: rating,
                    priceLevel: priceLevel,
                    distance: distance,
                    isOpen: isOpen
                )
            }
        } catch {
            print("Google Places API error: \(error)")
            return nil
        }
    }
    
    // MARK: - OpenStreetMap Fallback (using Nominatim search)
    
    private func fetchOSMNearby(
        location: CLLocationCoordinate2D,
        category: NearbyPlace.PlaceCategory,
        radius: Int,
        limit: Int
    ) async -> [NearbyPlace] {
        // Use Nominatim to search for places near the location
        let searchTerms = getSearchTerms(for: category)
        var allResults: [NearbyPlace] = []
        
        // Search for each term and combine results
        for term in searchTerms {
            let query = "\(term) near \(location.latitude),\(location.longitude)"
            let urlString = "https://nominatim.openstreetmap.org/search?format=json&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&limit=\(limit)&lat=\(location.latitude)&lon=\(location.longitude)&radius=\(radius)&addressdetails=1"
            
            guard let url = URL(string: urlString) else { continue }
            
            var request = URLRequest(url: url)
            request.setValue("Toki Travel Logger", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                
                let results = json?.compactMap { result -> NearbyPlace? in
                    guard let latStr = result["lat"] as? String,
                          let lonStr = result["lon"] as? String,
                          let lat = Double(latStr),
                          let lon = Double(lonStr),
                          let displayName = result["display_name"] as? String else {
                        return nil
                    }
                    
                    let name = result["name"] as? String ?? displayName
                    let type = result["type"] as? String ?? result["class"] as? String
                    
                    // Filter by category relevance
                    if !isRelevantType(type, for: category) {
                        return nil
                    }
                    
                    var address: String? = nil
                    if let addressDetails = result["address"] as? [String: Any] {
                        var components: [String] = []
                        if let road = addressDetails["road"] as? String {
                            components.append(road)
                        }
                        if let city = addressDetails["city"] as? String ?? addressDetails["town"] as? String {
                            components.append(city)
                        }
                        address = components.isEmpty ? nil : components.joined(separator: ", ")
                    }
                    
                    let placeLocation = CLLocation(latitude: lat, longitude: lon)
                    let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    let distance = placeLocation.distance(from: userLocation)
                    
                    // Only include if within radius
                    guard distance <= Double(radius) else { return nil }
                    
                    return NearbyPlace(
                        id: "\(result["osm_id"] ?? UUID().uuidString)",
                        name: name,
                        address: address,
                        lat: lat,
                        lon: lon,
                        category: category,
                        rating: nil,
                        priceLevel: nil,
                        distance: distance,
                        isOpen: nil
                    )
                } ?? []
                
                allResults.append(contentsOf: results)
            } catch {
                print("OSM Nominatim search error: \(error)")
                continue
            }
        }
        
        // Remove duplicates and sort by distance
        var uniqueResults: [NearbyPlace] = []
        var seenNames: Set<String> = []
        
        for result in allResults.sorted(by: { ($0.distance ?? 0) < ($1.distance ?? 0) }) {
            if !seenNames.contains(result.name.lowercased()) {
                uniqueResults.append(result)
                seenNames.insert(result.name.lowercased())
            }
        }
        
        return Array(uniqueResults.prefix(limit))
    }
    
    private func getSearchTerms(for category: NearbyPlace.PlaceCategory) -> [String] {
        switch category {
        case .restaurant:
            return ["restaurant", "dining", "food"]
        case .cafe:
            return ["cafe", "coffee"]
        case .bar:
            return ["bar", "pub", "nightlife"]
        case .attraction:
            return ["attraction", "museum", "monument", "landmark"]
        case .activity:
            return ["park", "gym", "sports", "recreation"]
        case .shopping:
            return ["shop", "store", "mall", "market"]
        case .hotel:
            return ["hotel", "lodging", "accommodation"]
        case .other:
            return ["place", "point of interest"]
        }
    }
    
    private func isRelevantType(_ type: String?, for category: NearbyPlace.PlaceCategory) -> Bool {
        guard let type = type?.lowercased() else { return true }
        
        switch category {
        case .restaurant:
            return type.contains("restaurant") || type.contains("food") || type.contains("dining")
        case .cafe:
            return type.contains("cafe") || type.contains("coffee")
        case .bar:
            return type.contains("bar") || type.contains("pub") || type.contains("nightclub")
        case .attraction:
            return type.contains("attraction") || type.contains("museum") || type.contains("monument") || type.contains("historic")
        case .activity:
            return type.contains("park") || type.contains("sport") || type.contains("leisure") || type.contains("gym")
        case .shopping:
            return type.contains("shop") || type.contains("store") || type.contains("mall") || type.contains("market")
        case .hotel:
            return type.contains("hotel") || type.contains("lodging") || type.contains("hostel")
        case .other:
            return true
        }
    }
}

