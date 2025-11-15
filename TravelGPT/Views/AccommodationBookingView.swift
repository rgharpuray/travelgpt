import SwiftUI

struct AccommodationBookingView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var hotelName: String = ""
    @State private var confirmationNumber: String = ""
    @State private var checkInDate: Date = Date()
    @State private var checkOutDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var provider: String = ""
    @State private var notes: String = ""
    @State private var showingBookingSites = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hotel Details")) {
                    TextField("Hotel Name", text: $hotelName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Confirmation Number", text: $confirmationNumber)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Booking Site (e.g., Booking.com, Hotels.com)", text: $provider)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Check-in", selection: $checkInDate, displayedComponents: [.date])
                    DatePicker("Check-out", selection: $checkOutDate, displayedComponents: [.date])
                }
                
                Section(header: Text("Notes")) {
                    TextField("Additional notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Need to Book?"), footer: Text("We'll help you find the best deals")) {
                    Button(action: { showingBookingSites = true }) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Open Booking Sites")
                        }
                    }
                }
            }
            .navigationTitle("Add Accommodation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccommodation()
                    }
                    .disabled(hotelName.isEmpty || confirmationNumber.isEmpty)
                }
            }
            .sheet(isPresented: $showingBookingSites) {
                BookingSitesView(destination: trip.name, checkIn: checkInDate, checkOut: checkOutDate)
            }
        }
    }
    
    private func saveAccommodation() {
        var updatedTrip = trip
        
        // Create reservation
        let reservation = Reservation(
            type: .hotel,
            confirmationNumber: confirmationNumber,
            provider: provider.isEmpty ? nil : provider,
            date: checkInDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        updatedTrip.reservations.append(reservation)
        storage.updateTrip(updatedTrip)
        
        // Create a card for the hotel
        let hotelText = "Hotel: \(hotelName)"
        storage.createCard(
            tripId: trip.id,
            kind: .note,
            takenAt: checkInDate,
            tags: ["hotel", "accommodation"],
            text: hotelText
        )
        
        dismiss()
    }
}

struct BookingSitesView: View {
    let destination: String
    let checkIn: Date
    let checkOut: Date
    @Environment(\.dismiss) private var dismiss
    
    private let bookingSites = [
        BookingSite(name: "Booking.com", url: "https://www.booking.com", icon: "bed.double.fill", color: .blue),
        BookingSite(name: "Hotels.com", url: "https://www.hotels.com", icon: "building.2.fill", color: .orange),
        BookingSite(name: "Expedia", url: "https://www.expedia.com", icon: "airplane", color: .green),
        BookingSite(name: "Airbnb", url: "https://www.airbnb.com", icon: "house.fill", color: .pink),
        BookingSite(name: "Agoda", url: "https://www.agoda.com", icon: "globe", color: .red),
        BookingSite(name: "Kayak", url: "https://www.kayak.com", icon: "magnifyingglass", color: .purple)
    ]
    
    private func buildBookingURL(for site: BookingSite) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let checkInStr = dateFormatter.string(from: checkIn)
        let checkOutStr = dateFormatter.string(from: checkOut)
        
        // Build URL with destination and dates
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destination
        
        switch site.name {
        case "Booking.com":
            return URL(string: "\(site.url)/searchresults.html?ss=\(encodedDestination)&checkin=\(checkInStr)&checkout=\(checkOutStr)")
        case "Hotels.com":
            return URL(string: "\(site.url)/Hotels/Search?destination=\(encodedDestination)&checkIn=\(checkInStr)&checkOut=\(checkOutStr)")
        case "Expedia":
            return URL(string: "\(site.url)/Hotels?destination=\(encodedDestination)&checkIn=\(checkInStr)&checkOut=\(checkOutStr)")
        case "Airbnb":
            return URL(string: "\(site.url)/s/\(encodedDestination)/homes?checkin=\(checkInStr)&checkout=\(checkOutStr)")
        case "Agoda":
            return URL(string: "\(site.url)/search?city=\(encodedDestination)&checkIn=\(checkInStr)&checkOut=\(checkOutStr)")
        case "Kayak":
            return URL(string: "\(site.url)/hotels/\(encodedDestination)/\(checkInStr)/\(checkOutStr)")
        default:
            return URL(string: site.url)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Popular Booking Sites"), footer: Text("Tap to open in Safari and find the best deals for your trip")) {
                    ForEach(bookingSites) { site in
                        Link(destination: buildBookingURL(for: site) ?? URL(string: site.url)!) {
                            HStack(spacing: 16) {
                                Image(systemName: site.icon)
                                    .font(.title2)
                                    .foregroundColor(site.color)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(site.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Search hotels in \(destination)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Book Accommodation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BookingSite: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let icon: String
    let color: Color
}


