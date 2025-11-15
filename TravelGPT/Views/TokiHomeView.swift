import SwiftUI

struct TokiHomeView: View {
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingNewTrip = false
    @State private var selectedTrip: Trip?
    
    var body: some View {
        NavigationView {
            ZStack {
                if storage.trips.isEmpty {
                    emptyState
                } else {
                    tripsList
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewTrip = true }) {
                            Label("New Trip", systemImage: "plus")
                        }
                        
                        Button(action: {
                            // Force create seed data for testing
                            Task { @MainActor in
                                let trip = TokiSeedDataService.shared.createSampleTrip()
                                print("✅ Created seed trip: \(trip.name)")
                                // Refresh the view by selecting the trip
                                selectedTrip = trip
                            }
                        }) {
                            Label("Create Demo Trip", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                NavigationView {
                    TokiNewTripFlowView { trip in
                        selectedTrip = trip
                        showingNewTrip = false
                    }
                }
            }
            .fullScreenCover(item: $selectedTrip) { trip in
                TokiTripView(trip: trip)
            }
            .onAppear {
                // Seed sample data for UI showcase
                Task { @MainActor in
                    if storage.trips.isEmpty {
                        await TokiSeedDataService.shared.seedIfNeeded()
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.6))
                
                VStack(spacing: 12) {
                    Text("Where do you want to go?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap to start planning your trip")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { showingNewTrip = true }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Start Planning")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var tripsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(storage.trips) { trip in
                    TripCard(trip: trip) {
                        selectedTrip = trip
                        storage.setActiveTrip(trip.id)
                    }
                }
            }
            .padding()
        }
    }
}

struct TripCard: View {
    let trip: Trip
    let action: () -> Void
    
    @StateObject private var storage = TokiStorageService.shared
    
    private var coverImage: UIImage? {
        guard let coverPhotoId = trip.coverPhotoId,
              let card = storage.cards.first(where: { $0.mediaId == coverPhotoId }),
              let mediaId = card.mediaId,
              let image = storage.loadMediaImage(mediaId) else {
            return nil
        }
        return image
    }
    
    private var cardCount: Int {
        storage.getCardsForTrip(trip.id).count
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Cover Image
                Group {
                    if let image = coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.blue.opacity(0.3)
                            .overlay(
                                Image(systemName: "map.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .clipped()
                
                // Trip Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let startDate = trip.startDate {
                        Text(formatDateRange(start: startDate, end: trip.endDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("\(cardCount) cards", systemImage: "photo.on.rectangle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
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

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = TokiStorageService.shared
    
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTrip()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createTrip() {
        let trip = storage.createTrip(
            name: name,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        storage.setActiveTrip(trip.id)
        dismiss()
    }
}

