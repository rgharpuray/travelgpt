import Foundation
import CoreLocation

// MARK: - Place Search Service

struct PlaceSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let lat: Double
    let lon: Double
    let type: String?
    let address: PlaceAddress?
    
    struct PlaceAddress: Codable {
        let road: String?
        let houseNumber: String?
        let city: String?
        let state: String?
        let country: String?
        let postcode: String?
    }
}

class PlaceSearchService {
    static let shared = PlaceSearchService()
    
    private init() {}
    
    // Search for places using OpenStreetMap Nominatim
    func searchPlaces(query: String, near: CLLocationCoordinate2D? = nil) async -> [PlaceSearchResult] {
        var urlString = "https://nominatim.openstreetmap.org/search?format=json&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&limit=10&addressdetails=1"
        
        // If we have a location, bias results towards it
        if let near = near {
            urlString += "&lat=\(near.latitude)&lon=\(near.longitude)"
        }
        
        guard let url = URL(string: urlString) else { return [] }
        
        var request = URLRequest(url: url)
        request.setValue("Toki Travel Logger", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            return json?.compactMap { result in
                guard let latStr = result["lat"] as? String,
                      let lonStr = result["lon"] as? String,
                      let lat = Double(latStr),
                      let lon = Double(lonStr),
                      let displayName = result["display_name"] as? String else {
                    return nil
                }
                
                let name = result["name"] as? String ?? displayName
                let type = result["type"] as? String
                
                var address: PlaceSearchResult.PlaceAddress? = nil
                if let addressDetails = result["address"] as? [String: Any] {
                    address = PlaceSearchResult.PlaceAddress(
                        road: addressDetails["road"] as? String,
                        houseNumber: addressDetails["house_number"] as? String,
                        city: addressDetails["city"] as? String ?? addressDetails["town"] as? String ?? addressDetails["village"] as? String,
                        state: addressDetails["state"] as? String,
                        country: addressDetails["country"] as? String,
                        postcode: addressDetails["postcode"] as? String
                    )
                }
                
                return PlaceSearchResult(
                    name: name,
                    displayName: displayName,
                    lat: lat,
                    lon: lon,
                    type: type,
                    address: address
                )
            } ?? []
        } catch {
            print("Place search error: \(error)")
            return []
        }
    }
    
    // Reverse geocode to get place name from coordinates
    func reverseGeocode(lat: Double, lon: Double) async -> PlaceSearchResult? {
        let urlString = "https://nominatim.openstreetmap.org/reverse?format=json&lat=\(lat)&lon=\(lon)&zoom=18&addressdetails=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Toki Travel Logger", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let latStr = json?["lat"] as? String,
                  let lonStr = json?["lon"] as? String,
                  let lat = Double(latStr),
                  let lon = Double(lonStr),
                  let displayName = json?["display_name"] as? String else {
                return nil
            }
            
            let name = json?["name"] as? String ?? displayName
            let type = json?["type"] as? String
            
            var address: PlaceSearchResult.PlaceAddress? = nil
            if let addressDetails = json?["address"] as? [String: Any] {
                address = PlaceSearchResult.PlaceAddress(
                    road: addressDetails["road"] as? String,
                    houseNumber: addressDetails["house_number"] as? String,
                    city: addressDetails["city"] as? String ?? addressDetails["town"] as? String ?? addressDetails["village"] as? String,
                    state: addressDetails["state"] as? String,
                    country: addressDetails["country"] as? String,
                    postcode: addressDetails["postcode"] as? String
                )
            }
            
            return PlaceSearchResult(
                name: name,
                displayName: displayName,
                lat: lat,
                lon: lon,
                type: type,
                address: address
            )
        } catch {
            print("Reverse geocoding error: \(error)")
            return nil
        }
    }
}

