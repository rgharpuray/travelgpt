import SwiftUI
import MapKit
import UIKit

struct TokiSummaryView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingExport = false
    
    private var cards: [Card] {
        storage.getCardsForTrip(trip.id)
    }
    
    private var places: [Place] {
        let placeIds = Set(cards.compactMap { $0.placeId })
        return storage.places.filter { placeIds.contains($0.id) }
    }
    
    private var allTags: [String] {
        Array(Set(cards.flatMap { $0.tags })).sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(trip.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let startDate = trip.startDate {
                        Text(formatDateRange(start: startDate, end: trip.endDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Stats
                HStack(spacing: 20) {
                    StatBox(title: "Cards", value: "\(cards.count)", icon: "photo.on.rectangle")
                    StatBox(title: "Places", value: "\(places.count)", icon: "map")
                    StatBox(title: "Days", value: "\(uniqueDays)", icon: "calendar")
                }
                .padding(.horizontal)
                
                // Photo Gallery
                if !photoCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(photoCards.prefix(10)) { card in
                                    if let image = storage.loadMediaImage(card.mediaId ?? "") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(12)
                                            .clipped()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Map with Route
                if !places.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TripMapView(places: places, cards: cards)
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                
                // Tags
                if !allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Export Button
                Button(action: { showingExport = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Trip")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportView(trip: trip)
        }
    }
    
    private var photoCards: [Card] {
        cards.filter { $0.kind == .photo && $0.mediaId != nil }
    }
    
    private var uniqueDays: Int {
        let calendar = Calendar.current
        let days = Set(cards.map { calendar.startOfDay(for: $0.takenAt) })
        return days.count
    }
    
    private func formatDateRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if let end = end {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            return "Started \(formatter.string(from: start))"
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TripMapView: View {
    let places: [Place]
    let cards: [Card]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 26.2124, longitude: 127.6809),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: places) { place in
            MapAnnotation(coordinate: place.coordinate) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
            }
        }
        .onAppear {
            updateRegion()
        }
    }
    
    private func updateRegion() {
        guard !places.isEmpty else { return }
        
        let lats = places.map { $0.lat }
        let lons = places.map { $0.lon }
        
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct ExportView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isExporting {
                    ProgressView("Exporting...")
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Export Trip")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Export your trip data as JSON and media files")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let error = exportError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: exportTrip) {
                        Text("Export Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let exportURL = exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
        }
    }
    
    private func exportTrip() {
        isExporting = true
        exportError = nil
        
        guard let export = storage.exportTrip(trip.id) else {
            exportError = "Failed to export trip"
            isExporting = false
            return
        }
        
        // Create export directory
        let exportDir = FileManager.default.temporaryDirectory.appendingPathComponent("toki-export-\(trip.id)")
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // Save JSON
        let jsonURL = exportDir.appendingPathComponent("trip-\(trip.id).toki.json")
        if let jsonData = try? JSONEncoder().encode(export) {
            try? jsonData.write(to: jsonURL)
        }
        
        // Copy media files
        let mediaDir = exportDir.appendingPathComponent("media")
        try? FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        
        for mediaEntry in export.mediaIndex {
            if let mediaData = storage.loadMedia(mediaEntry.mediaId) {
                let mediaURL = mediaDir.appendingPathComponent(mediaEntry.filename)
                try? mediaData.write(to: mediaURL)
            }
        }
        
        // Store export URL for sharing
        exportURL = exportDir
        
        isExporting = false
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

