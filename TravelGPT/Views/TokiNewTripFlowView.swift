import SwiftUI

// MARK: - New Trip Flow - Visual First

struct TokiNewTripFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = TokiStorageService.shared
    var onTripCreated: ((Trip) -> Void)?
    
    @State private var currentStep: TripCreationStep = .destination
    @State private var destination: String = ""
    @State private var selectedDestination: PlaceSearchResult?
    @State private var startDate: Date = Date()
    @State private var endDate: Date?
    @State private var tripType: TripType?
    @State private var isSearching = false
    @State private var searchResults: [PlaceSearchResult] = []
    @State private var showingSuggestions = false
    @State private var selectedSuggestions: Set<UUID> = []
    @State private var createdTrip: Trip?
    
    // Flight booking state
    @State private var hasBookedFlight: Bool?
    @State private var flightDepartureDate: Date = Date()
    @State private var flightReturnDate: Date?
    @State private var flightNumber: String = ""
    @State private var airline: String = ""
    @State private var departureAirport: String = ""
    @State private var arrivalAirport: String = ""
    @State private var flightConfirmationNumber: String = ""
    @State private var arrivalTime: Date = Date()
    
    // Companions state
    @State private var travelStyle: TravelStyle?
    @State private var companions: [TripCompanion] = []
    @State private var newCompanionName: String = ""
    
    // Arrival feelings state
    @State private var arrivalFeelings: Set<ArrivalFeeling> = []
    
    enum TripCreationStep {
        case destination
        case flight
        case arrivalFeelings
        case companions
        case dates
        case tripType
        case suggestions
    }
    
    enum TravelStyle: String {
        case alone = "Alone"
        case group = "Group"
    }
    
    enum ArrivalFeeling: String, CaseIterable {
        case tired = "Tired"
        case hungry = "Hungry"
        case energetic = "Energetic"
        case sleepy = "Sleepy"
        case excited = "Excited"
        case relaxed = "Relaxed"
        
        var icon: String {
            switch self {
            case .tired: return "moon.zzz"
            case .hungry: return "fork.knife"
            case .energetic: return "bolt.fill"
            case .sleepy: return "bed.double"
            case .excited: return "sparkles"
            case .relaxed: return "leaf"
            }
        }
        
        var color: Color {
            switch self {
            case .tired, .sleepy: return .blue
            case .hungry: return .orange
            case .energetic, .excited: return .yellow
            case .relaxed: return .green
            }
        }
    }
    
    enum TripType: String, CaseIterable {
        case relaxing = "Relaxing"
        case adventure = "Adventure"
        case culture = "Culture"
        case food = "Food"
        case nature = "Nature"
        case mixed = "Mixed"
        
        var icon: String {
            switch self {
            case .relaxing: return "beach.umbrella"
            case .adventure: return "figure.hiking"
            case .culture: return "building.columns"
            case .food: return "fork.knife"
            case .nature: return "leaf"
            case .mixed: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .relaxing: return .blue
            case .adventure: return .orange
            case .culture: return .purple
            case .food: return .red
            case .nature: return .green
            case .mixed: return .pink
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                Group {
                    switch currentStep {
                    case .destination:
                        destinationStep
                    case .flight:
                        flightStep
                    case .arrivalFeelings:
                        arrivalFeelingsStep
                    case .companions:
                        companionsStep
                    case .dates:
                        datesStep
                    case .tripType:
                        tripTypeStep
                    case .suggestions:
                        suggestionsStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if currentStep == .destination {
                    Button("Cancel") {
                        dismiss()
                    }
                } else {
                    Button("Back") {
                        goBack()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { index in
                Circle()
                    .fill(index <= currentStepIndex ? Color.blue : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
    }
    
    private var currentStepIndex: Int {
        switch currentStep {
        case .destination: return 0
        case .flight: return 1
        case .arrivalFeelings: return 2
        case .companions: return 3
        case .dates: return 4
        case .tripType: return 5
        case .suggestions: return 6
        }
    }
    
    // MARK: - Step 1: Destination
    
    private var destinationStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("Where do you want to go?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Search
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search destination...", text: $destination)
                        .textFieldStyle(.plain)
                        .onChange(of: destination) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await performSearch(query: newValue)
                                }
                            } else {
                                searchResults = []
                            }
                        }
                    
                    if !destination.isEmpty {
                        Button(action: { destination = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                // Search Results
                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(searchResults) { result in
                                DestinationCard(result: result) {
                                    selectedDestination = result
                                    destination = result.name
                                    searchResults = []
                                    proceedToNextStep()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 300)
                }
            }
            
            Spacer()
            
            // Continue Button
            if selectedDestination != nil {
                Button(action: proceedToNextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 2: Flight
    
    private var flightStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "airplane")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("Have you booked your flight?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    hasBookedFlight = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Yes, I've booked")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(hasBookedFlight == true ? .white : .primary)
                    .padding()
                    .background(hasBookedFlight == true ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                }
                
                Button(action: {
                    hasBookedFlight = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                        Text("Not yet")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(hasBookedFlight == false ? .white : .primary)
                    .padding()
                    .background(hasBookedFlight == false ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            
            // Flight details form (shown if booked)
            if hasBookedFlight == true {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Flight Details")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                TextField("Airline (optional)", text: $airline)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Flight Number (optional)", text: $flightNumber)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Departure Airport", text: $departureAirport)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Arrival Airport", text: $arrivalAirport)
                                    .textFieldStyle(.roundedBorder)
                                
                                DatePicker("Departure Date", selection: $flightDepartureDate, displayedComponents: [.date, .hourAndMinute])
                                
                                DatePicker("Arrival Date & Time", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                                
                                TextField("Confirmation Number (optional)", text: $flightConfirmationNumber)
                                    .textFieldStyle(.roundedBorder)
                                
                                Toggle("Round Trip", isOn: Binding(
                                    get: { flightReturnDate != nil },
                                    set: { hasReturn in
                                        flightReturnDate = hasReturn ? calendar.date(byAdding: .day, value: 7, to: flightDepartureDate) : nil
                                    }
                                ))
                                
                                if flightReturnDate != nil {
                                    DatePicker("Return Date", selection: Binding(
                                        get: { flightReturnDate ?? Date() },
                                        set: { flightReturnDate = $0 }
                                    ), displayedComponents: [.date, .hourAndMinute])
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
            
            if hasBookedFlight != nil {
                Button(action: proceedToNextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 2.5: Arrival Feelings
    
    private var arrivalFeelingsStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("How will you feel when you arrive?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("We'll suggest activities based on your energy level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ArrivalFeeling.allCases, id: \.self) { feeling in
                    Button(action: {
                        if arrivalFeelings.contains(feeling) {
                            arrivalFeelings.remove(feeling)
                        } else {
                            arrivalFeelings.insert(feeling)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: feeling.icon)
                                .font(.title)
                            Text(feeling.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(arrivalFeelings.contains(feeling) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(arrivalFeelings.contains(feeling) ? feeling.color : Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            if !arrivalFeelings.isEmpty {
                Button(action: proceedToNextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 3: Companions
    
    private var companionsStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("Who's traveling?")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    travelStyle = .alone
                    companions = []
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.title2)
                        Text("Just me")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(travelStyle == .alone ? .white : .primary)
                    .padding()
                    .background(travelStyle == .alone ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                }
                
                Button(action: {
                    travelStyle = .group
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                        Text("With others")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(travelStyle == .group ? .white : .primary)
                    .padding()
                    .background(travelStyle == .group ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            
            if travelStyle == .group {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add people to your trip")
                        .font(.headline)
                        .padding(.horizontal, 24)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(companions) { companion in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(companion.name)
                                    Spacer()
                                    Button(action: {
                                        companions.removeAll { $0.id == companion.id }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            HStack {
                                TextField("Name", text: $newCompanionName)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: {
                                    if !newCompanionName.isEmpty {
                                        companions.append(TripCompanion(name: newCompanionName))
                                        newCompanionName = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            if travelStyle != nil {
                Button(action: proceedToNextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 4: Dates
    
    private var datesStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("When are you going?")
                    .font(.title)
                    .fontWeight(.bold)
                
                if hasBookedFlight == true && !departureAirport.isEmpty {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                        Text("Trip dates pre-filled from your flight")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            VStack(spacing: 20) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Toggle("Set End Date", isOn: Binding(
                    get: { endDate != nil },
                    set: { hasEndDate in
                        endDate = hasEndDate ? calendar.date(byAdding: .day, value: 7, to: startDate) : nil
                    }
                ))
                
                if endDate != nil {
                    DatePicker("End Date", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: proceedToNextStep) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Step 3: Trip Type
    
    private var tripTypeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                Text("What kind of trip?")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(TripType.allCases, id: \.self) { type in
                    TripTypeCard(type: type, isSelected: tripType == type) {
                        tripType = type
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            if tripType != nil {
                Button(action: proceedToNextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Step 4: Suggestions
    
    private var suggestionsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Here are some ideas")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Tap to add to your trip")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            if isLoadingSuggestions {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Getting AI suggestions...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if suggestions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No suggestions available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try adding an OpenAI API key in Settings for personalized suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(suggestions) { suggestion in
                            AttractionCard(
                                suggestion: suggestion,
                                isSelected: selectedSuggestions.contains(suggestion.id)
                            ) {
                                if selectedSuggestions.contains(suggestion.id) {
                                    selectedSuggestions.remove(suggestion.id)
                                } else {
                                    selectedSuggestions.insert(suggestion.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            if !selectedSuggestions.isEmpty {
                Button(action: createTripWithSuggestions) {
                    HStack {
                        Text("Create Trip")
                        Image(systemName: "checkmark")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            loadSuggestions()
        }
    }
    
    @State private var suggestions: [AttractionSuggestion] = []
    @State private var isLoadingSuggestions = false
    private let calendar = Calendar.current
    
    // MARK: - Actions
    
    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }
        
        let results = await PlaceSearchService.shared.searchPlaces(query: query)
        
        await MainActor.run {
            searchResults = results
        }
    }
    
    private func proceedToNextStep() {
        withAnimation {
            switch currentStep {
            case .destination:
                currentStep = .flight
            case .flight:
                // If flight is booked with details, use departure date as trip start date
                if hasBookedFlight == true && !departureAirport.isEmpty && !arrivalAirport.isEmpty {
                    startDate = flightDepartureDate
                    // If return flight exists, use it as end date
                    if let returnDate = flightReturnDate {
                        endDate = returnDate
                    }
                    currentStep = .arrivalFeelings
                } else {
                    currentStep = .companions
                }
            case .arrivalFeelings:
                currentStep = .companions
            case .companions:
                currentStep = .dates
            case .dates:
                currentStep = .tripType
            case .tripType:
                currentStep = .suggestions
            case .suggestions:
                break
            }
        }
    }
    
    private func goBack() {
        withAnimation {
            switch currentStep {
            case .destination:
                break
            case .flight:
                currentStep = .destination
            case .arrivalFeelings:
                currentStep = .flight
            case .companions:
                if hasBookedFlight == true && !departureAirport.isEmpty {
                    currentStep = .arrivalFeelings
                } else {
                    currentStep = .flight
                }
            case .dates:
                currentStep = .companions
            case .tripType:
                currentStep = .dates
            case .suggestions:
                currentStep = .tripType
            }
        }
    }
    
    private func loadSuggestions() {
        isLoadingSuggestions = true
        Task {
            let location = selectedDestination.map { (lat: $0.lat, lon: $0.lon) }
            let tripTypeString = tripType?.rawValue
            
            // Build context for suggestions
            var context: [String: Any] = [:]
            context["tripType"] = tripTypeString
            
            // Add arrival feelings context
            if !arrivalFeelings.isEmpty {
                context["feelings"] = arrivalFeelings.map { $0.rawValue }
            }
            
            // Add arrival time context
            if hasBookedFlight == true {
                context["arrivalTime"] = arrivalTime
                let hour = Calendar.current.component(.hour, from: arrivalTime)
                context["arrivalHour"] = hour
            }
            
            let results = await TokiAIService.shared.suggestAttractions(
                for: destination,
                location: location,
                tripType: tripTypeString,
                context: context
            )
            
            await MainActor.run {
                suggestions = results
                isLoadingSuggestions = false
            }
        }
    }
    
    private func createTripWithSuggestions() {
        guard let selectedDest = selectedDestination else { return }
        
        // Create trip
        let trip = storage.createTrip(
            name: destination,
            startDate: startDate,
            endDate: endDate
        )
        
        // Create flight card and reservation if flight was booked with details
        if hasBookedFlight == true && !departureAirport.isEmpty && !arrivalAirport.isEmpty {
            var flightText = "Flight"
            if !airline.isEmpty {
                flightText += " \(airline)"
            }
            if !flightNumber.isEmpty {
                flightText += " \(flightNumber)"
            }
            flightText += " from \(departureAirport) to \(arrivalAirport)"
            
            if flightReturnDate != nil {
                flightText += " (Round Trip)"
            }
            
            storage.createCard(
                tripId: trip.id,
                kind: .note,
                takenAt: flightDepartureDate,
                tags: ["flight", "travel"],
                text: flightText
            )
            
            // Store confirmation number as reservation
            if !flightConfirmationNumber.isEmpty {
                var updatedTrip = trip
                updatedTrip.reservations.append(Reservation(
                    type: .flight,
                    confirmationNumber: flightConfirmationNumber,
                    provider: airline.isEmpty ? nil : airline,
                    date: flightDepartureDate,
                    notes: "Flight from \(departureAirport) to \(arrivalAirport)"
                ))
                storage.updateTrip(updatedTrip)
            }
            
            // If return flight exists, create return card
            if let returnDate = flightReturnDate {
                var returnText = "Return Flight"
                if !airline.isEmpty {
                    returnText += " \(airline)"
                }
                if !flightNumber.isEmpty {
                    returnText += " \(flightNumber)"
                }
                returnText += " from \(arrivalAirport) to \(departureAirport)"
                
                storage.createCard(
                    tripId: trip.id,
                    kind: .note,
                    takenAt: returnDate,
                    tags: ["flight", "travel"],
                    text: returnText
                )
            }
        }
        
        // Update trip with companions
        var updatedTrip = trip
        updatedTrip.companions = companions
        storage.updateTrip(updatedTrip)
        
        // Create place for destination
        let destinationPlace = storage.findOrCreatePlace(
            lat: selectedDest.lat,
            lon: selectedDest.lon,
            label: selectedDest.name
        )
        
        // Create cards for selected suggestions
        for suggestion in suggestions where selectedSuggestions.contains(suggestion.id) {
            let place = storage.findOrCreatePlace(
                lat: suggestion.location.lat,
                lon: suggestion.location.lon,
                label: suggestion.title,
                categories: [suggestion.category]
            )
            
            // Create card on first day
            storage.createCard(
                tripId: trip.id,
                placeId: place.id,
                kind: .note,
                takenAt: startDate,
                tags: [suggestion.category],
                text: suggestion.description
            )
        }
        
        createdTrip = trip
        storage.setActiveTrip(trip.id)
        onTripCreated?(trip)
        dismiss()
    }
}

// MARK: - Supporting Views

struct DestinationCard: View {
    let result: PlaceSearchResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(result.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TripTypeCard: View {
    let type: TokiNewTripFlowView.TripType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? type.color : Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AttractionCard: View {
    let suggestion: AttractionSuggestion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconForCategory(suggestion.category))
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "view", "sunset": return "camera"
        case "culture", "historical": return "building.columns"
        case "nature": return "leaf"
        default: return "mappin"
        }
    }
}

