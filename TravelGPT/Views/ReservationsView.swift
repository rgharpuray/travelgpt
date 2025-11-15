import SwiftUI

struct ReservationsView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingAddReservation = false
    @State private var reservationType: Reservation.ReservationType = .hotel
    
    private var reservationsByType: [Reservation.ReservationType: [Reservation]] {
        Dictionary(grouping: trip.reservations) { $0.type }
    }
    
    var body: some View {
        List {
            if trip.reservations.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No reservations yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add your flight, hotel, and other bookings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(Reservation.ReservationType.allCases, id: \.self) { type in
                    if let reservations = reservationsByType[type], !reservations.isEmpty {
                        Section(header: Text(type.rawValue.capitalized)) {
                            ForEach(reservations) { reservation in
                                ReservationDetailRow(reservation: reservation, trip: trip)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reservations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        reservationType = .hotel
                        showingAddReservation = true
                    }) {
                        Label("Hotel", systemImage: "bed.double.fill")
                    }
                    
                    Button(action: {
                        reservationType = .flight
                        showingAddReservation = true
                    }) {
                        Label("Flight", systemImage: "airplane")
                    }
                    
                    Button(action: {
                        reservationType = .restaurant
                        showingAddReservation = true
                    }) {
                        Label("Restaurant", systemImage: "fork.knife")
                    }
                    
                    Button(action: {
                        reservationType = .activity
                        showingAddReservation = true
                    }) {
                        Label("Activity", systemImage: "figure.walk")
                    }
                    
                    Button(action: {
                        reservationType = .car
                        showingAddReservation = true
                    }) {
                        Label("Car Rental", systemImage: "car.fill")
                    }
                    
                    Button(action: {
                        reservationType = .other
                        showingAddReservation = true
                    }) {
                        Label("Other", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddReservation) {
            if reservationType == .hotel {
                AccommodationBookingView(trip: trip)
            } else {
                AddReservationView(trip: trip, type: reservationType)
            }
        }
    }
}

struct ReservationDetailRow: View {
    let reservation: Reservation
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(reservation.type))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.provider ?? reservation.type.rawValue.capitalized)
                        .font(.headline)
                    
                    if let date = reservation.date {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Text("Confirmation: \(reservation.confirmationNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let notes = reservation.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: Reservation.ReservationType) -> String {
        switch type {
        case .flight: return "airplane"
        case .hotel: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        case .activity: return "figure.walk"
        case .car: return "car.fill"
        case .other: return "doc.text"
        }
    }
}

struct AddReservationView: View {
    let trip: Trip
    let type: Reservation.ReservationType
    @StateObject private var storage = TokiStorageService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var confirmationNumber: String = ""
    @State private var provider: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("\(type.rawValue.capitalized) Details")) {
                    TextField("Confirmation Number", text: $confirmationNumber)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Provider (optional)", text: $provider)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Notes")) {
                    TextField("Additional notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add \(type.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReservation()
                    }
                    .disabled(confirmationNumber.isEmpty)
                }
            }
        }
    }
    
    private func saveReservation() {
        var updatedTrip = trip
        
        let reservation = Reservation(
            type: type,
            confirmationNumber: confirmationNumber,
            provider: provider.isEmpty ? nil : provider,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        
        updatedTrip.reservations.append(reservation)
        storage.updateTrip(updatedTrip)
        
        dismiss()
    }
}

extension Reservation.ReservationType: CaseIterable {
    static var allCases: [Reservation.ReservationType] {
        [.flight, .hotel, .restaurant, .activity, .car, .other]
    }
}


