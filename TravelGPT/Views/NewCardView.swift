import SwiftUI
import PhotosUI
import AVFoundation

struct NewCardView: View {
    let trip: Trip
    var initialPlace: Place? = nil
    var initialLocation: CLLocationCoordinate2D? = nil
    var initialKind: CardKind = .photo
    
    @StateObject private var storage = TokiStorageService.shared
    @StateObject private var locationService = TokiLocationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedKind: CardKind
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var text = ""
    @State private var selectedTags: Set<String> = []
    @State private var place: Place?
    @State private var takenAt = Date()
    @State private var isSaving = false
    @State private var showingPlacePicker = false
    
    init(trip: Trip, initialPlace: Place? = nil, initialLocation: CLLocationCoordinate2D? = nil, initialKind: CardKind = .photo) {
        self.trip = trip
        self.initialPlace = initialPlace
        self.initialLocation = initialLocation
        self.initialKind = initialKind
        _selectedKind = State(initialValue: initialKind)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Type")) {
                    Picker("Type", selection: $selectedKind) {
                        Text("Photo").tag(CardKind.photo)
                        Text("Note").tag(CardKind.note)
                        Text("Audio").tag(CardKind.audio)
                    }
                }
                
                Section(header: Text("Content")) {
                    if selectedKind == .photo {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                            
                            Button("Change Photo") {
                                showingImagePicker = true
                            }
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Select Photo")
                                }
                            }
                            
                            Button(action: { showingCamera = true }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Take Photo")
                                }
                            }
                        }
                    }
                    
                    TextField("Caption or Note", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Place")) {
                    if let place = place {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(place.label ?? "Unknown Place")
                            Spacer()
                            Button("Change") {
                                showingPlacePicker = true
                            }
                        }
                    } else {
                        Button(action: { showingPlacePicker = true }) {
                            HStack {
                                Image(systemName: "location")
                                Text("Set Place")
                            }
                        }
                    }
                }
                
                Section(header: Text("Tags")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TokiTags.availableTags, id: \.self) { tag in
                                Button(action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }) {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedTags.contains(tag) ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Time")) {
                    DatePicker("Taken At", selection: $takenAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(isSaving || (selectedKind == .photo && selectedImage == nil))
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                TokiImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                TokiImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPlacePicker) {
                PlacePickerView(selectedPlace: $place)
            }
            .onAppear {
                // Request location permission if needed
                if locationService.authorizationStatus == .notDetermined {
                    locationService.requestAuthorization()
                }
                
                // Start location updates
                locationService.startUpdatingLocation()
                
                setupInitialPlace()
                extractLocationFromImage()
                
                // Auto-set place from current location if no place is set
                if place == nil, let location = locationService.currentLocation {
                    Task {
                        await autoSetPlaceFromLocation()
                    }
                }
            }
        }
    }
    
    private func setupInitialPlace() {
        if let initialPlace = initialPlace {
            place = initialPlace
        } else if let initialLocation = initialLocation {
            place = storage.findOrCreatePlace(lat: initialLocation.latitude, lon: initialLocation.longitude)
        } else if let location = locationService.currentLocation {
            place = storage.findOrCreatePlace(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    private func extractLocationFromImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 1.0) else { return }
        
        if let (lat, lon, timestamp) = EXIFParser.extractLocation(from: imageData) {
            Task {
                // Reverse geocode to get place name
                if let result = await PlaceSearchService.shared.reverseGeocode(lat: lat, lon: lon) {
                    await MainActor.run {
                        place = storage.findOrCreatePlace(
                            lat: lat,
                            lon: lon,
                            label: result.name
                        )
                        if let timestamp = timestamp {
                            takenAt = timestamp
                        }
                    }
                } else {
                    await MainActor.run {
                        place = storage.findOrCreatePlace(lat: lat, lon: lon)
                        if let timestamp = timestamp {
                            takenAt = timestamp
                        }
                    }
                }
            }
        }
    }
    
    private func autoSetPlaceFromLocation() async {
        guard let location = locationService.currentLocation else { return }
        
        // Reverse geocode to get place name
        if let result = await PlaceSearchService.shared.reverseGeocode(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        ) {
            await MainActor.run {
                place = storage.findOrCreatePlace(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    label: result.name
                )
            }
        } else {
            await MainActor.run {
                place = storage.findOrCreatePlace(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
            }
        }
    }
    
    private func saveCard() {
        isSaving = true
        
        var mediaId: TokiID? = nil
        
        // Save media if photo
        if selectedKind == .photo, let image = selectedImage {
            let compressed = compressImage(image)
            if let imageData = compressed.jpegData(compressionQuality: 0.78) {
                mediaId = storage.saveMedia(data: imageData, mime: "image/jpeg")
            }
        }
        
        // Ensure place exists
        if place == nil {
            if let location = locationService.currentLocation {
                place = storage.findOrCreatePlace(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            } else {
                // Create placeholder place
                place = storage.findOrCreatePlace(lat: 0, lon: 0)
            }
        }
        
        // Create card
        let card = storage.createCard(
            tripId: trip.id,
            placeId: place?.id,
            kind: selectedKind,
            takenAt: takenAt,
            tags: Array(selectedTags),
            text: text.isEmpty ? nil : text,
            mediaId: mediaId
        )
        
        // Update trip cover if needed
        if trip.coverPhotoId == nil, let mediaId = mediaId {
            var updatedTrip = trip
            updatedTrip.coverPhotoId = mediaId
            storage.updateTrip(updatedTrip)
        }
        
        isSaving = false
        dismiss()
    }
    
    private func compressImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 2560
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let compressed = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compressed ?? image
    }
}

struct TokiImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: TokiImagePicker
        
        init(_ parent: TokiImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}

struct PlacePickerView: View {
    @Binding var selectedPlace: Place?
    @StateObject private var storage = TokiStorageService.shared
    @StateObject private var locationService = TokiLocationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [PlaceSearchResult] = []
    @State private var isSearching = false
    @State private var currentLocationPlace: PlaceSearchResult?
    @State private var isLoadingLocation = false
    
    private var filteredPlaces: [Place] {
        if searchText.isEmpty {
            return storage.places
        }
        return storage.places.filter { place in
            (place.label?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            place.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Current Location Section
                if locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
                    Section(header: Text("Current Location")) {
                        if isLoadingLocation {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Getting location...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } else if let locationPlace = currentLocationPlace {
                            Button(action: {
                                let place = storage.findOrCreatePlace(
                                    lat: locationPlace.lat,
                                    lon: locationPlace.lon,
                                    label: locationPlace.name
                                )
                                selectedPlace = place
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(locationPlace.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let address = locationPlace.address {
                                            Text(formatAddress(address))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        } else if let location = locationService.currentLocation {
                            Button(action: {
                                Task {
                                    await loadCurrentLocationPlace()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    Text("Use Current Location")
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("Location Services")) {
                        Button(action: {
                            locationService.requestAuthorization()
                        }) {
                            HStack {
                                Image(systemName: "location.slash")
                                    .foregroundColor(.orange)
                                Text("Enable Location Services")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // Search Results
                if !searchText.isEmpty && !searchResults.isEmpty {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults) { result in
                            Button(action: {
                                let place = storage.findOrCreatePlace(
                                    lat: result.lat,
                                    lon: result.lon,
                                    label: result.name
                                )
                                selectedPlace = place
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: iconForType(result.type))
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                        .frame(width: 24)
                                    
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
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // Saved Places
                if searchText.isEmpty || !filteredPlaces.isEmpty {
                    Section(header: Text("Saved Places")) {
                        if filteredPlaces.isEmpty && searchText.isEmpty {
                            Text("No saved places yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(filteredPlaces) { place in
                                Button(action: {
                                    selectedPlace = place
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(place.label ?? "Unknown Place")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            if !place.categories.isEmpty {
                                                Text(place.categories.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search for a place...")
            .onChange(of: searchText) { newValue in
                if !newValue.isEmpty {
                    Task {
                        await performSearch(query: newValue)
                    }
                } else {
                    searchResults = []
                }
            }
            .navigationTitle("Select Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Request location if not authorized
                if locationService.authorizationStatus == .notDetermined {
                    locationService.requestAuthorization()
                }
                
                // Start updating location
                locationService.startUpdatingLocation()
                
                // Load current location place
                Task {
                    await loadCurrentLocationPlace()
                }
            }
        }
    }
    
    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }
        
        let near = locationService.currentLocation?.coordinate
        let results = await PlaceSearchService.shared.searchPlaces(query: query, near: near)
        
        await MainActor.run {
            searchResults = results
        }
    }
    
    private func loadCurrentLocationPlace() async {
        guard let location = locationService.currentLocation else { return }
        
        await MainActor.run {
            isLoadingLocation = true
        }
        
        let result = await PlaceSearchService.shared.reverseGeocode(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude
        )
        
        await MainActor.run {
            currentLocationPlace = result
            isLoadingLocation = false
        }
    }
    
    private func formatAddress(_ address: PlaceSearchResult.PlaceAddress) -> String {
        var components: [String] = []
        
        if let road = address.road {
            if let houseNumber = address.houseNumber {
                components.append("\(houseNumber) \(road)")
            } else {
                components.append(road)
            }
        }
        
        if let city = address.city {
            components.append(city)
        }
        
        if let state = address.state {
            components.append(state)
        }
        
        if let country = address.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func iconForType(_ type: String?) -> String {
        guard let type = type else { return "mappin" }
        
        switch type.lowercased() {
        case "restaurant", "cafe", "food", "fast_food":
            return "fork.knife"
        case "hotel", "accommodation":
            return "bed.double"
        case "attraction", "tourism", "museum":
            return "camera"
        case "shop", "store", "mall":
            return "bag"
        case "park", "nature", "beach":
            return "leaf"
        case "transport", "station", "airport":
            return "car"
        default:
            return "mappin"
        }
    }
}

