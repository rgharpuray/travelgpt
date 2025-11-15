import SwiftUI

struct TokiTripSettingsView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var editedTrip: Trip
    @State private var showingDeleteConfirmation = false
    @State private var showingReservations = false
    
    init(trip: Trip) {
        self.trip = trip
        _editedTrip = State(initialValue: trip)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Trip Details")) {
                TextField("Trip Name", text: $editedTrip.name)
                
                DatePicker("Start Date", selection: Binding(
                    get: { editedTrip.startDate ?? Date() },
                    set: { editedTrip.startDate = $0 }
                ), displayedComponents: .date)
                
                Toggle("Set End Date", isOn: Binding(
                    get: { editedTrip.endDate != nil },
                    set: { hasEndDate in
                        editedTrip.endDate = hasEndDate ? Date() : nil
                    }
                ))
                
                if editedTrip.endDate != nil {
                    DatePicker("End Date", selection: Binding(
                        get: { editedTrip.endDate ?? Date() },
                        set: { editedTrip.endDate = $0 }
                    ), displayedComponents: .date)
                }
            }
            
            Section(header: Text("Settings")) {
                Picker("Distance Units", selection: $editedTrip.settings.distanceUnits) {
                    Text("Kilometers").tag(TripSettings.DistanceUnit.km)
                    Text("Miles").tag(TripSettings.DistanceUnit.mi)
                }
                
                Toggle("Auto Reverse Geocode", isOn: $editedTrip.settings.autoReverseGeocode)
                Toggle("Enable Suggestions", isOn: $editedTrip.settings.enableSuggestions)
                Toggle("Hide Precise Location", isOn: $editedTrip.settings.hidePreciseLocation)
            }
            
            Section(header: Text("Reservations")) {
                NavigationLink(destination: ReservationsView(trip: trip)) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("View All Reservations")
                        Spacer()
                        if !editedTrip.reservations.isEmpty {
                            Text("\(editedTrip.reservations.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("AI Suggestions")) {
                NavigationLink(destination: AISettingsView()) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Configure AI")
                    }
                }
            }
            
            Section(header: Text("Data")) {
                Button(action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Trip")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: editedTrip.name) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.startDate) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.endDate) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.settings.distanceUnits) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.settings.autoReverseGeocode) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.settings.enableSuggestions) { _ in
            storage.updateTrip(editedTrip)
        }
        .onChange(of: editedTrip.settings.hidePreciseLocation) { _ in
            storage.updateTrip(editedTrip)
        }
        .alert("Delete Trip", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                storage.deleteTrip(trip.id)
            }
        } message: {
            Text("This will permanently delete this trip and all its cards. This action cannot be undone.")
        }
    }
}

