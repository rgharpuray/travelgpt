import SwiftUI
import MapKit
import UIKit

struct TokiMapView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @StateObject private var locationService = TokiLocationService.shared
    @Binding var selectedPlace: Place?
    @Binding var showingPlaceSheet: Bool
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 26.2124, longitude: 127.6809), // Okinawa default
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var hasInitializedRegion = false
    @State private var showingNewCard = false
    @State private var newCardLocation: CLLocationCoordinate2D?
    
    private var cards: [Card] {
        storage.getCardsForTrip(trip.id)
    }
    
    private var places: [Place] {
        let placeIds = Set(cards.compactMap { $0.placeId })
        return storage.places.filter { placeIds.contains($0.id) }
    }
    
    // Get trip path coordinates in chronological order (matching feed order)
    private var tripPathCoordinates: [CLLocationCoordinate2D]? {
        // Get all cards with places, sorted by time (same as feed)
        let sortedCards = cards.sorted { $0.takenAt < $1.takenAt }
        
        let cardsWithPlaces = sortedCards
            .compactMap { card -> (card: Card, place: Place)? in
                guard let placeId = card.placeId,
                      let place = storage.getPlace(placeId) else {
                    return nil
                }
                
                // Validate coordinates are reasonable
                guard place.lat != 0 && place.lon != 0,
                      place.lat >= -90 && place.lat <= 90,
                      place.lon >= -180 && place.lon <= 180 else {
                    return nil
                }
                
                return (card, place)
            }
        
        // Keep all visits in order (don't remove duplicates - show the full journey)
        // This creates a more interesting path that shows backtracking
        let orderedPlaces = cardsWithPlaces.map { $0.place }
        
        guard orderedPlaces.count > 1 else { return nil }
        
        return orderedPlaces.map { place in
            CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
        }
    }
    
    // Get ordered cards with places for numbering (matches feed order)
    private var orderedCardsWithPlaces: [(card: Card, place: Place, order: Int)] {
        let sortedCards = cards.sorted { $0.takenAt < $1.takenAt }
        
        var order = 1
        return sortedCards.compactMap { card -> (card: Card, place: Place, order: Int)? in
            guard let placeId = card.placeId,
                  let place = storage.getPlace(placeId),
                  place.lat != 0 && place.lon != 0,
                  place.lat >= -90 && place.lat <= 90,
                  place.lon >= -180 && place.lon <= 180 else {
                return nil
            }
            
            let result = (card: card, place: place, order: order)
            order += 1
            return result
        }
    }
    
    var body: some View {
        ZStack {
            MapWithPath(
                coordinateRegion: $region,
                annotations: cardAnnotations,
                pathCoordinates: tripPathCoordinates,
                onAnnotationTap: { annotation in
                    if let place = annotation.place {
                        selectedPlace = place
                        showingPlaceSheet = true
                    }
                }
            )
            .onAppear {
                if !hasInitializedRegion {
                    updateRegion()
                }
                locationService.startUpdatingLocation()
            }
            .onChange(of: places.count) { _ in
                // Update region when places change
                updateRegion()
            }
            .onDisappear {
                locationService.stopUpdatingLocation()
            }
            
            // Controls
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // User Location Button
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        // Fit to Places Button
                        if !places.isEmpty {
                            Button(action: fitToPlaces) {
                                Image(systemName: "map")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            
            // Info Card
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if !cards.isEmpty {
                            Text("\(cards.count) card\(cards.count == 1 ? "" : "s")")
                                .font(.headline)
                            Text("\(places.count) place\(places.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Path indicator
                        if let pathCoordinates = tripPathCoordinates, pathCoordinates.count > 1 {
                            HStack(spacing: 6) {
                                Image(systemName: "path")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(pathCoordinates.count) stops connected")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        } else if !places.isEmpty {
                            Text("Add more places to see your path")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(12)
                .padding()
            }
        }
        .sheet(isPresented: $showingNewCard) {
            if let location = newCardLocation {
                NewCardView(trip: trip, initialLocation: location)
            } else {
                NewCardView(trip: trip)
            }
        }
    }
    
    private var cardAnnotations: [CardAnnotation] {
        // Create annotations with order numbers matching feed
        let ordered = orderedCardsWithPlaces
        
        // Group by place but keep order info
        var placeAnnotations: [String: (place: Place, cards: [Card], order: Int)] = [:]
        
        for item in ordered {
            let placeId = item.place.id
            if var existing = placeAnnotations[placeId] {
                existing.cards.append(item.card)
                // Keep the earliest order number for this place
                existing.order = min(existing.order, item.order)
                placeAnnotations[placeId] = existing
            } else {
                placeAnnotations[placeId] = (place: item.place, cards: [item.card], order: item.order)
            }
        }
        
        return placeAnnotations.values.map { data in
            CardAnnotation(
                coordinate: data.place.coordinate,
                place: data.place,
                cards: data.cards,
                order: data.order
            )
        }
    }
    
    private func fitToPlaces() {
        updateRegion()
    }
    
    private func updateRegion() {
        guard !places.isEmpty else {
            // If no places, try to use trip name to get a location
            if !hasInitializedRegion {
                // Search for trip destination
                Task {
                    let results = await PlaceSearchService.shared.searchPlaces(query: trip.name)
                    if let firstResult = results.first {
                        await MainActor.run {
                            region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: firstResult.lat, longitude: firstResult.lon),
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                            hasInitializedRegion = true
                        }
                    }
                }
            }
            return
        }
        
        // Filter out invalid coordinates (0,0 or obviously wrong)
        let validPlaces = places.filter { place in
            place.lat != 0 && place.lon != 0 &&
            place.lat >= -90 && place.lat <= 90 &&
            place.lon >= -180 && place.lon <= 180
        }
        
        guard !validPlaces.isEmpty else { return }
        
        let lats = validPlaces.map { $0.lat }
        let lons = validPlaces.map { $0.lon }
        
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate appropriate span
        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
        
        let span = MKCoordinateSpan(
            latitudeDelta: min(latDelta, 10.0), // Cap at reasonable size
            longitudeDelta: min(lonDelta, 10.0)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
        hasInitializedRegion = true
    }
    
    private func centerOnUserLocation() {
        guard let location = locationService.currentLocation else { return }
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

struct CardAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let place: Place?
    let cards: [Card]
    let order: Int? // Order number matching feed
    
    init(coordinate: CLLocationCoordinate2D, place: Place?, cards: [Card], order: Int? = nil) {
        self.coordinate = coordinate
        self.place = place
        self.cards = cards
        self.order = order
    }
}

struct CardPin: View {
    let annotation: CardAnnotation
    let action: () -> Void
    
    private var cardCount: Int {
        annotation.cards.count
    }
    
    private var hasPhoto: Bool {
        annotation.cards.contains { $0.kind == .photo }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer circle
                Circle()
                    .fill(hasPhoto ? Color.blue : Color.gray)
                    .frame(width: 36, height: 36)
                
                // Inner circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                
                // Icon or count
                if cardCount == 1, let card = annotation.cards.first {
                    Image(systemName: iconForKind(card.kind))
                        .font(.caption)
                        .foregroundColor(hasPhoto ? .blue : .gray)
                } else {
                    Text("\(cardCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(hasPhoto ? .blue : .gray)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private func iconForKind(_ kind: CardKind) -> String {
        switch kind {
        case .photo: return "photo.fill"
        case .note: return "note.text"
        case .audio: return "waveform"
        }
    }
}

// MARK: - Map with Path Overlay

struct MapWithPath: UIViewRepresentable {
    @Binding var coordinateRegion: MKCoordinateRegion
    let annotations: [CardAnnotation]
    let pathCoordinates: [CLLocationCoordinate2D]?
    let onAnnotationTap: (CardAnnotation) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = coordinateRegion
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Validate region coordinates before updating
        let validRegion = coordinateRegion
        guard validRegion.center.latitude >= -90 && validRegion.center.latitude <= 90,
              validRegion.center.longitude >= -180 && validRegion.center.longitude <= 180,
              validRegion.span.latitudeDelta > 0 && validRegion.span.latitudeDelta <= 180,
              validRegion.span.longitudeDelta > 0 && validRegion.span.longitudeDelta <= 360 else {
            print("⚠️ Invalid region coordinates, skipping update")
            return
        }
        
        // Update region only if significantly different
        let latDiff = abs(mapView.region.center.latitude - validRegion.center.latitude)
        let lonDiff = abs(mapView.region.center.longitude - validRegion.center.longitude)
        if latDiff > 0.01 || lonDiff > 0.01 {
            mapView.setRegion(validRegion, animated: true)
        }
        
        // Remove old annotations and overlays
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)
        
        // Add custom annotations (validate coordinates first)
        for annotation in annotations {
            let coord = annotation.coordinate
            guard coord.latitude >= -90 && coord.latitude <= 90,
                  coord.longitude >= -180 && coord.longitude <= 180 else {
                print("⚠️ Skipping annotation with invalid coordinates: \(coord)")
                continue
            }
            let mkAnnotation = CustomAnnotation(annotation: annotation)
            mapView.addAnnotation(mkAnnotation)
        }
        
        // Add path polyline if we have valid coordinates
        if let pathCoordinates = pathCoordinates, pathCoordinates.count > 1 {
            // Validate all coordinates in path
            let validPath = pathCoordinates.filter { coord in
                coord.latitude >= -90 && coord.latitude <= 90 &&
                coord.longitude >= -180 && coord.longitude <= 180
            }
            
            if validPath.count > 1 {
                let polyline = MKPolyline(coordinates: validPath, count: validPath.count)
                mapView.addOverlay(polyline)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapWithPath
        
        init(_ parent: MapWithPath) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? CustomAnnotation else {
                return nil
            }
            
            let identifier = "CardPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Get order number from annotation (matches feed order)
            let orderNumber = customAnnotation.cardAnnotation.order
            
            // Create custom pin view
            let cardAnnotation = customAnnotation.cardAnnotation
            let hasPhoto = cardAnnotation.cards.contains { $0.kind == .photo }
            let cardCount = cardAnnotation.cards.count
            
            // Check if this is a hotel/accommodation
            let isHotel = cardAnnotation.cards.contains { card in
                card.tags.contains { tag in
                    tag.lowercased() == "hotel" || tag.lowercased() == "accommodation" || tag.lowercased() == "lodging"
                }
            } || (cardAnnotation.place?.categories.contains { category in
                category.lowercased() == "hotel" || category.lowercased() == "accommodation" || category.lowercased() == "lodging"
            } ?? false)
            
            // Get photos for this place
            let photoCards = cardAnnotation.cards.filter { $0.kind == .photo }
            let storage = TokiStorageService.shared
            
            // Clear any existing subviews
            annotationView?.subviews.forEach { $0.removeFromSuperview() }
            
            // Larger pin to show photos
            let pinView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            pinView.backgroundColor = .clear
            
            // Outer circle with border (special color for hotels)
            let outerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            if isHotel {
                // Warm, friendly color for hotels
                outerCircle.backgroundColor = UIColor.systemPurple
            } else {
                outerCircle.backgroundColor = (hasPhoto ? UIColor.systemBlue : UIColor.systemGray)
            }
            outerCircle.layer.cornerRadius = 30
            outerCircle.layer.borderWidth = 3
            outerCircle.layer.borderColor = UIColor.white.cgColor
            outerCircle.layer.shadowColor = UIColor.black.cgColor
            outerCircle.layer.shadowRadius = 4
            outerCircle.layer.shadowOpacity = 0.3
            outerCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
            pinView.addSubview(outerCircle)
            
            // Always show images - photos if available, or placeholder
            var displayImage: UIImage? = nil
            
            // Try to get actual photos first
            if !photoCards.isEmpty {
                if let firstCard = photoCards.first,
                   let mediaId = firstCard.mediaId {
                    displayImage = storage.loadMediaImage(mediaId)
                }
            }
            
            // If no photo, create a placeholder image
            if displayImage == nil {
                displayImage = createPlaceholderImage(
                    for: cardAnnotation.place?.label ?? "Place",
                    isHotel: isHotel,
                    color: isHotel ? .systemPurple : .systemBlue
                )
            }
            
            // Display the image (always show something)
            if let image = displayImage {
                let imageView = UIImageView(frame: CGRect(x: 5, y: 5, width: 50, height: 50))
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 25
                imageView.layer.borderWidth = 2
                imageView.layer.borderColor = UIColor.white.cgColor
                pinView.addSubview(imageView)
                
                // Add hotel icon overlay for hotels
                if isHotel {
                    let bedIcon = UIImage(systemName: "bed.double.fill")
                    let iconView = UIImageView(frame: CGRect(x: 35, y: 35, width: 20, height: 20))
                    iconView.image = bedIcon
                    iconView.contentMode = .scaleAspectFit
                    iconView.tintColor = .white
                    iconView.backgroundColor = UIColor.systemPurple
                    iconView.layer.cornerRadius = 10
                    iconView.layer.borderWidth = 1.5
                    iconView.layer.borderColor = UIColor.white.cgColor
                    pinView.addSubview(iconView)
                }
            }
            
            // Order number badge (top right corner) - special styling for hotels
            if let order = orderNumber {
                let badgeView = UIView(frame: CGRect(x: 40, y: -5, width: 24, height: 24))
                if isHotel {
                    badgeView.backgroundColor = .systemOrange // Warm, friendly color for hotel badges
                } else {
                    badgeView.backgroundColor = .systemBlue
                }
                badgeView.layer.cornerRadius = 12
                badgeView.layer.borderWidth = 2
                badgeView.layer.borderColor = UIColor.white.cgColor
                badgeView.layer.shadowColor = UIColor.black.cgColor
                badgeView.layer.shadowRadius = 2
                badgeView.layer.shadowOpacity = 0.3
                badgeView.layer.shadowOffset = CGSize(width: 0, height: 1)
                
                let badgeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                badgeLabel.text = "\(order)"
                badgeLabel.textAlignment = .center
                badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                badgeLabel.textColor = .white
                badgeView.addSubview(badgeLabel)
                
                pinView.addSubview(badgeView)
            }
            
            annotationView?.addSubview(pinView)
            annotationView?.frame = pinView.frame
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let customAnnotation = view.annotation as? CustomAnnotation {
                parent.onAnnotationTap(customAnnotation.cardAnnotation)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.coordinateRegion = mapView.region
            }
        }
        
        // Create placeholder image for places without photos
        private func createPlaceholderImage(for name: String, isHotel: Bool, color: UIColor) -> UIImage? {
            let size = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let image = renderer.image { context in
                // Background with gradient
                let colors = [color.withAlphaComponent(0.8).cgColor, color.withAlphaComponent(0.5).cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])
                context.cgContext.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
                
                // Icon or emoji
                let iconName = isHotel ? "bed.double.fill" : "mappin.circle.fill"
                if let icon = UIImage(systemName: iconName) {
                    let iconSize: CGFloat = 60
                    let iconRect = CGRect(
                        x: (size.width - iconSize) / 2,
                        y: (size.height - iconSize) / 2 - 20,
                        width: iconSize,
                        height: iconSize
                    )
                    icon.withTintColor(.white).draw(in: iconRect)
                }
                
                // Place name (truncated if too long)
                let displayName = name.count > 15 ? String(name.prefix(12)) + "..." : name
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
                
                let attributedString = NSAttributedString(string: displayName, attributes: attributes)
                let textSize = attributedString.size()
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: size.height - 50,
                    width: textSize.width,
                    height: textSize.height
                )
                
                attributedString.draw(in: textRect)
            }
            
            return image
        }
    }
}

// Custom annotation class to hold CardAnnotation
class CustomAnnotation: NSObject, MKAnnotation {
    let cardAnnotation: CardAnnotation
    var coordinate: CLLocationCoordinate2D {
        cardAnnotation.coordinate
    }
    var title: String? {
        cardAnnotation.place?.label
    }
    
    init(annotation: CardAnnotation) {
        self.cardAnnotation = annotation
        super.init()
    }
}

// MARK: - Place Sheet View

struct PlaceSheetView: View {
    let place: Place
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingNewCard = false
    @Environment(\.dismiss) private var dismiss
    
    private var cards: [Card] {
        storage.getCardsForPlace(place.id)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Place Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(place.label ?? "Unknown Place")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let address = place.meta?.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(cards.count) card\(cards.count == 1 ? "" : "s")", systemImage: "photo.on.rectangle")
                            Spacer()
                            Label(formatCoordinates(place.lat, place.lon), systemImage: "location")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Categories
                    if !place.categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(place.categories, id: \.self) { category in
                                    Text(category)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Cards
                    if cards.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No cards at this place yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingNewCard = true }) {
                                Text("Add Card")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cards")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(cards) { card in
                                CardRow(card: card)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingNewCard = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewCard) {
            NewCardView(trip: trip, initialPlace: place)
        }
    }
    
    private func formatCoordinates(_ lat: Double, _ lon: Double) -> String {
        return String(format: "%.4f, %.4f", lat, lon)
    }
}

