import Foundation
import CoreLocation
import UIKit
import ImageIO

// MARK: - Toki Location Service

class TokiLocationService: NSObject, ObservableObject {
    static let shared = TokiLocationService()
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension TokiLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - EXIF Parser

struct EXIFParser {
    static func extractLocation(from imageData: Data) -> (lat: Double, lon: Double, timestamp: Date?)? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }
        
        guard let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            return nil
        }
        
        let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
        
        let finalLat = latRef == "S" ? -lat : lat
        let finalLon = lonRef == "W" ? -lon : lon
        
        // Extract timestamp
        var timestamp: Date? = nil
        if let dateTime = gps[kCGImagePropertyGPSDateStamp as String] as? String,
           let time = gps[kCGImagePropertyGPSTimeStamp as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            timestamp = formatter.date(from: "\(dateTime) \(time)")
        }
        
        return (finalLat, finalLon, timestamp)
    }
    
    static func extractTimestamp(from imageData: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        
        // Try EXIF DateTimeOriginal
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            return formatter.date(from: dateTimeOriginal)
        }
        
        // Try TIFF DateTime
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            return formatter.date(from: dateTime)
        }
        
        return nil
    }
}

// MARK: - Reverse Geocoding

class ReverseGeocoder {
    static func reverseGeocode(lat: Double, lon: Double) async -> String? {
        let urlString = "https://nominatim.openstreetmap.org/reverse?format=json&lat=\(lat)&lon=\(lon)&zoom=18&addressdetails=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Toki Travel Logger", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let address = json?["display_name"] as? String {
                return address
            }
        } catch {
            print("Reverse geocoding error: \(error)")
        }
        
        return nil
    }
}


