import Foundation

// MARK: - AI Agent Service

class TokiAIService {
    static let shared = TokiAIService()
    
    private let keychain = KeychainManager.shared
    
    // PROOF OF CONCEPT: Hardcoded API key
    
    private init() {}
    
    private func getAPIKey() -> String? {
        // PROOF OF CONCEPT: Use hardcoded key first, fallback to keychain
    }
    
    // MARK: - Destination Suggestions
    
    func suggestAttractions(for destination: String, location: (lat: Double, lon: Double)? = nil, tripType: String? = nil, context: [String: Any]? = nil) async -> [AttractionSuggestion] {
        // Try OpenAI API first if key is available
        if let apiKey = getAPIKey(), !apiKey.isEmpty {
            if let aiSuggestions = await fetchAISuggestions(
                destination: destination,
                location: location,
                tripType: tripType,
                context: context,
                apiKey: apiKey
            ) {
                return aiSuggestions
            }
        }
        
        // Fallback to curated suggestions
        return getCuratedSuggestions(for: destination, location: location)
    }
    
    // MARK: - OpenAI API Integration
    
    private func fetchAISuggestions(
        destination: String,
        location: (lat: Double, lon: Double)?,
        tripType: String?,
        context: [String: Any]?,
        apiKey: String
    ) async -> [AttractionSuggestion]? {
        guard let url = URL(string: "\(Config.openAIBaseURL)/chat/completions") else {
            return nil
        }
        
        // Build prompt
        var prompt = "You are a travel expert. Suggest 5-7 unique, authentic, and interesting attractions or activities for a trip to \(destination)."
        
        if let tripType = tripType {
            prompt += " The traveler is interested in \(tripType.lowercased()) experiences."
        }
        
        if let location = location {
            prompt += " The destination is located at approximately \(String(format: "%.4f", location.lat)), \(String(format: "%.4f", location.lon))."
        }
        
        // Add contextual information
        if let context = context {
            if let feelings = context["feelings"] as? [String], !feelings.isEmpty {
                prompt += " The traveler will arrive feeling: \(feelings.joined(separator: ", "))."
                
                // Add time-based suggestions
                if let arrivalHour = context["arrivalHour"] as? Int {
                    if arrivalHour >= 22 || arrivalHour < 6 {
                        prompt += " They're arriving late at night/early morning - suggest things that are open late or good for tired travelers."
                    } else if arrivalHour >= 6 && arrivalHour < 12 {
                        prompt += " They're arriving in the morning - suggest breakfast spots, light activities, or places to get oriented."
                    } else if arrivalHour >= 12 && arrivalHour < 17 {
                        prompt += " They're arriving in the afternoon - suggest lunch spots, moderate activities, or places to explore."
                    } else {
                        prompt += " They're arriving in the evening - suggest dinner spots, evening activities, or places to relax."
                    }
                }
                
                // Add feeling-based suggestions
                if feelings.contains("Tired") || feelings.contains("Sleepy") {
                    prompt += " Focus on low-energy activities like cafes, parks, or scenic viewpoints."
                }
                if feelings.contains("Hungry") {
                    prompt += " Include great local food spots and markets."
                }
                if feelings.contains("Energetic") || feelings.contains("Excited") {
                    prompt += " Include active experiences and must-see attractions."
                }
            }
        }
        
        prompt += """
        
        CRITICAL: Only suggest places that are CURRENTLY OPEN and OPERATIONAL. Do NOT include permanently closed places.
        
        For each suggestion, provide detailed information like a travel expert:
        1. title: A short, catchy title (max 50 characters) - must be a real, currently operating place
        2. description: A compelling 1-2 sentence description explaining why it's special and what to expect
        3. category: One of: restaurant, cafe, bar, food, culture, nature, view, adventure, beach, market, museum, shrine, activity, attraction, or other
        
        Focus on high-quality, authentic experiences (prioritize places with good ratings when possible). 
        Be specific with actual business/place names and real information.
        Return ONLY a JSON array with this exact structure:
        [
          {
            "title": "The Brick Saloon",
            "description": "Established in 1889, it's the oldest continuously operating bar in Washington. Pub-style fare and historic atmosphere.",
            "category": "restaurant"
          },
          ...
        ]
        
        Return ONLY the JSON array, no other text.
        """
        
        let requestBody: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("OpenAI API error: \(response)")
                return nil
            }
            
            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Extract JSON from response (might have markdown code blocks)
                let cleanedContent = content
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let jsonData = cleanedContent.data(using: .utf8),
                   let suggestions = try? JSONDecoder().decode([AISuggestionResponse].self, from: jsonData) {
                    return suggestions.map { suggestion in
                        AttractionSuggestion(
                            title: suggestion.title,
                            description: suggestion.description,
                            category: suggestion.category,
                            location: location ?? (lat: 0, lon: 0),
                            imageURL: nil
                        )
                    }
                }
            }
        } catch {
            print("Error calling OpenAI API: \(error)")
            return nil
        }
        
        return nil
    }
    
    // MARK: - Helper Models
    
    private struct AISuggestionResponse: Codable {
        let title: String
        let description: String
        let category: String
    }
    
    private func getCuratedSuggestions(for destination: String, location: (lat: Double, lon: Double)?) -> [AttractionSuggestion] {
        // Okinawa-specific suggestions
        if destination.lowercased().contains("okinawa") {
            return [
                AttractionSuggestion(
                    title: "Ogimi Village Farm to Table",
                    description: "Authentic farm-to-table experience in the longevity village",
                    category: "food",
                    location: (lat: 26.6833, lon: 128.1167),
                    imageURL: nil
                ),
                AttractionSuggestion(
                    title: "Cape Hedo",
                    description: "Northernmost point with stunning ocean views",
                    category: "view",
                    location: (lat: 26.8700, lon: 128.2633),
                    imageURL: nil
                ),
                AttractionSuggestion(
                    title: "Naha Castle Ruins",
                    description: "Historic castle ruins with panoramic views",
                    category: "culture",
                    location: (lat: 26.2167, lon: 127.7167),
                    imageURL: nil
                ),
                AttractionSuggestion(
                    title: "Asato Dojo",
                    description: "Traditional karate dojo in the heart of Naha",
                    category: "culture",
                    location: (lat: 26.2133, lon: 127.6800),
                    imageURL: nil
                ),
                AttractionSuggestion(
                    title: "Shuri Castle",
                    description: "UNESCO World Heritage site and royal palace",
                    category: "culture",
                    location: (lat: 26.2172, lon: 127.7192),
                    imageURL: nil
                )
            ]
        }
        
        // Default suggestions
        return [
            AttractionSuggestion(
                title: "Local Market",
                description: "Explore local flavors and culture",
                category: "food",
                location: location ?? (lat: 0, lon: 0),
                imageURL: nil
            ),
            AttractionSuggestion(
                title: "Scenic Viewpoint",
                description: "Best views of the area",
                category: "view",
                location: location ?? (lat: 0, lon: 0),
                imageURL: nil
            ),
            AttractionSuggestion(
                title: "Historic Site",
                description: "Discover local history",
                category: "culture",
                location: location ?? (lat: 0, lon: 0),
                imageURL: nil
            ),
            AttractionSuggestion(
                title: "Nature Walk",
                description: "Peaceful natural setting",
                category: "nature",
                location: location ?? (lat: 0, lon: 0),
                imageURL: nil
            ),
            AttractionSuggestion(
                title: "Local Experience",
                description: "Authentic cultural experience",
                category: "culture",
                location: location ?? (lat: 0, lon: 0),
                imageURL: nil
            )
        ]
    }
    
    // MARK: - Natural Language Processing
    
    func processUserInput(_ input: String, for trip: Trip) async -> ProcessedInput {
        let lowercased = input.lowercased()
        
        // Flight detection
        if lowercased.contains("flight") || lowercased.contains("fly") {
            return .flight(extractFlightInfo(from: input))
        }
        
        // Hotel detection
        if lowercased.contains("hotel") || lowercased.contains("stay") || lowercased.contains("accommodation") {
            return .hotel(extractHotelInfo(from: input))
        }
        
        // Meal detection
        if lowercased.contains("lunch") || lowercased.contains("dinner") || lowercased.contains("breakfast") || lowercased.contains("eat") {
            return .meal(extractMealInfo(from: input))
        }
        
        // Place/attraction detection
        if lowercased.contains("visit") || lowercased.contains("see") || lowercased.contains("go to") {
            return .place(extractPlaceInfo(from: input))
        }
        
        // Default to note
        return .note(input)
    }
    
    private func extractFlightInfo(from input: String) -> FlightInfo {
        // Simple extraction - in production, use NLP
        return FlightInfo(
            destination: extractDestination(from: input),
            date: extractDate(from: input),
            airline: nil,
            flightNumber: nil
        )
    }
    
    private func extractHotelInfo(from input: String) -> HotelInfo {
        return HotelInfo(
            name: extractPlaceName(from: input),
            checkIn: extractDate(from: input),
            checkOut: nil
        )
    }
    
    private func extractMealInfo(from input: String) -> MealInfo {
        return MealInfo(
            type: extractMealType(from: input),
            place: extractPlaceName(from: input),
            time: extractTime(from: input)
        )
    }
    
    private func extractPlaceInfo(from input: String) -> PlaceInfo {
        return PlaceInfo(
            name: extractPlaceName(from: input),
            description: input
        )
    }
    
    // MARK: - Simple Extractors (Replace with proper NLP)
    
    private func extractDestination(from input: String) -> String? {
        // Simple pattern matching
        if let match = input.range(of: "to [A-Z][a-z]+", options: .regularExpression) {
            return String(input[match]).replacingOccurrences(of: "to ", with: "")
        }
        return nil
    }
    
    private func extractDate(from input: String) -> Date? {
        // Simple date extraction - in production use proper date parsing
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Day of week
        
        if input.lowercased().contains("monday") {
            return nextWeekday(2)
        } else if input.lowercased().contains("tuesday") {
            return nextWeekday(3)
        } else if input.lowercased().contains("wednesday") {
            return nextWeekday(4)
        } else if input.lowercased().contains("thursday") {
            return nextWeekday(5)
        } else if input.lowercased().contains("friday") {
            return nextWeekday(6)
        } else if input.lowercased().contains("saturday") {
            return nextWeekday(7)
        } else if input.lowercased().contains("sunday") {
            return nextWeekday(1)
        }
        
        return nil
    }
    
    private func extractTime(from input: String) -> Date? {
        // Simple time extraction
        return nil
    }
    
    private func extractPlaceName(from input: String) -> String? {
        // Extract place name - simplified
        return input
    }
    
    private func extractMealType(from input: String) -> String {
        if input.lowercased().contains("breakfast") { return "breakfast" }
        if input.lowercased().contains("lunch") { return "lunch" }
        if input.lowercased().contains("dinner") { return "dinner" }
        return "meal"
    }
    
    private func nextWeekday(_ weekday: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToAdd = (weekday - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd == 0 ? 7 : daysToAdd, to: today)
    }
    
    // MARK: - Auto-captioning
    
    func generateCaption(for imageData: Data, location: (lat: Double, lon: Double)?) async -> String? {
        // TODO: Use GPT Vision API to generate captions
        // For now, return placeholder
        return nil
    }
    
    func generateTitle(for card: Card) async -> String? {
        // TODO: Use GPT to generate titles based on card content
        return nil
    }
    
    // MARK: - Destination Activities Discovery
    
    /// Fetches unique top activities for a destination and returns rich suggestion data
    /// - Parameters:
    ///   - destination: The city/location name
    ///   - location: Optional coordinates
    ///   - tripId: The trip ID
    /// - Returns: Array of rich activity suggestions with details
    @MainActor
    func fetchUniqueTopActivities(
        destination: String,
        location: (lat: Double, lon: Double)?,
        tripId: String
    ) async -> [RichActivitySuggestion] {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("⚠️ No OpenAI API key available for destination activities")
            return []
        }
        
        guard let url = URL(string: "\(Config.openAIBaseURL)/chat/completions") else {
            print("❌ Invalid OpenAI URL")
            return []
        }
        
        var prompt = "You are a travel expert. Find unique top activities to do in \(destination). "
        
        if let location = location {
            prompt += "The destination is at coordinates: \(String(format: "%.4f", location.lat)), \(String(format: "%.4f", location.lon)). "
        }
        
        prompt += """
        
        CRITICAL: Only suggest places that are CURRENTLY OPEN and OPERATIONAL. Do NOT include permanently closed places, seasonal places that are currently closed, or places that no longer exist.
        
        For each activity, provide detailed information like a travel expert would:
        1. name: The exact name of the place/activity (required) - must be a real, currently operating business or attraction
        2. rating: Google rating (0-5) if known, or null
        3. address: Full street address if available
        4. whyGo: A compelling 1-2 sentence reason to visit (what makes it special/unique)
        5. whatToExpect: What visitors will experience (atmosphere, activities, highlights, etc.)
        6. tip: A helpful tip for visitors (best time to go, what to do, etc.)
        7. category: One of: restaurant, cafe, bar, activity, attraction, market, museum, park, view, shopping, hotel, beach, culture, or other
        8. latitude: Approximate latitude (as a number, required)
        9. longitude: Approximate longitude (as a number, required)
        10. priceLevel: Price level indicator (1-4, where 4 is most expensive), or null
        
        Return 8-12 unique, high-quality activities that are actually in \(destination) and CURRENTLY OPEN.
        Prioritize places with good ratings (4.0+) when possible. Include a mix of popular and hidden gems.
        Focus on UNIQUE experiences - things that make \(destination) special.
        Make sure the coordinates are realistic for the location.
        Be specific and detailed - include ratings, addresses, and helpful tips like you would in a travel guide.
        ONLY include places you are confident are currently operating and open to visitors.
        Avoid generic or vague suggestions - be specific with actual business names and real addresses.
        
        Return ONLY a JSON array with this exact structure:
        [
          {
            "name": "The Brick Saloon",
            "rating": 4.5,
            "address": "100 W Pennsylvania Ave, Roslyn, WA 98941",
            "whyGo": "Established in 1889, it's the oldest continuously operating bar in Washington.",
            "whatToExpect": "Pub-style fare (burgers, fish & chips, chili) and a historic, lively atmosphere. Minors allowed in the dining area until 9pm.",
            "tip": "After dinner, stick around for live music (Fri & Sat) or soak up the history.",
            "category": "restaurant",
            "latitude": 47.2234,
            "longitude": -120.9912,
            "priceLevel": 2
          },
          ...
        ]
        
        Return ONLY the JSON array, no other text.
        """
        
        let requestBody: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 3000
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ OpenAI API error: \(response)")
                return []
            }
            
            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Extract JSON from response (might have markdown code blocks)
                let cleanedContent = content
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let jsonData = cleanedContent.data(using: .utf8),
                   let activities = try? JSONDecoder().decode([RichActivityResponse].self, from: jsonData) {
                    
                    // Get existing cards to calculate transport
                    let storage = TokiStorageService.shared
                    let existingCards = storage.getCardsForTrip(tripId).sorted { $0.takenAt < $1.takenAt }
                    var lastCardLocation: (lat: Double, lon: Double, name: String?)? = nil
                    
                    if let lastCard = existingCards.last,
                       let lastPlaceId = lastCard.placeId,
                       let lastPlace = storage.getPlace(lastPlaceId) {
                        lastCardLocation = (lat: lastPlace.lat, lon: lastPlace.lon, name: lastPlace.label)
                    }
                    
                    return activities.map { activity in
                        RichActivitySuggestion(
                            name: activity.name,
                            rating: activity.rating,
                            address: activity.address,
                            whyGo: activity.whyGo,
                            whatToExpect: activity.whatToExpect,
                            tip: activity.tip,
                            category: activity.category,
                            latitude: activity.latitude,
                            longitude: activity.longitude,
                            priceLevel: activity.priceLevel
                        )
                    }
                } else {
                    print("❌ Failed to parse destination activities JSON")
                    if let contentPreview = cleanedContent.prefix(500) as? String {
                        print("Response preview: \(contentPreview)")
                    }
                }
            }
        } catch {
            print("❌ Error calling OpenAI API for destination activities: \(error)")
            return []
        }
        
        return []
    }
    
    // MARK: - Nearby Places Discovery
    
    /// Fetches nearby activities, restaurants, and places using GPT and creates cards for each
    /// - Parameters:
    ///   - location: The location coordinates (lat, lon)
    ///   - tripId: The trip ID to associate cards with
    ///   - locationName: Optional location name for context
    ///   - enableWebSearch: Whether to enable web search (if supported by the model)
    ///   - categories: Optional list of categories to focus on (e.g., ["restaurant", "activity", "attraction"])
    ///   - previousActivity: Optional name of previous activity for context
    /// - Returns: Array of created Card IDs, or empty array if failed
    @MainActor
    func fetchNearbyPlacesAndCreateCards(
        location: (lat: Double, lon: Double),
        tripId: String,
        locationName: String? = nil,
        enableWebSearch: Bool = true,
        categories: [String]? = nil,
        previousActivity: String? = nil
    ) async -> [String] {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("⚠️ No OpenAI API key available for nearby places discovery")
            return []
        }
        
        guard let url = URL(string: "\(Config.openAIBaseURL)/chat/completions") else {
            print("❌ Invalid OpenAI URL")
            return []
        }
        
        // Build prompt with web search instructions if enabled
        var prompt = "You are a travel expert helping someone discover nearby places. "
        
        if enableWebSearch {
            prompt += "Use your knowledge and any available current information to find real, existing places. "
        }
        
        if let locationName = locationName {
            prompt += "The user is at or near \(locationName) (coordinates: \(String(format: "%.4f", location.lat)), \(String(format: "%.4f", location.lon))). "
        } else {
            prompt += "The user is at coordinates: \(String(format: "%.4f", location.lat)), \(String(format: "%.4f", location.lon)). "
        }
        
        if let previousActivity = previousActivity {
            prompt += "They just finished: \(previousActivity). Suggest what to do NEXT - activities, restaurants, or places that make sense to visit after this. "
        }
        
        if let categories = categories, !categories.isEmpty {
            prompt += "Focus on: \(categories.joined(separator: ", ")). "
        } else {
            prompt += "Find a mix of restaurants, activities, attractions, cafes, and interesting places that work well for building an itinerary. "
        }
        
        prompt += """
        
        CRITICAL: Only suggest places that are CURRENTLY OPEN and OPERATIONAL. Do NOT include permanently closed places, seasonal places that are currently closed, or places that no longer exist.
        
        For each place, provide detailed information like a travel expert would:
        1. name: The exact name of the place (required) - must be a real, currently operating business
        2. rating: Google rating (0-5) if known, or null
        3. address: Full street address if available
        4. whyGo: A compelling 1-2 sentence reason to visit (what makes it special)
        5. whatToExpect: What visitors will experience (atmosphere, food type, activities, etc.)
        6. tip: A helpful tip for visitors (best time to go, what to order, etc.)
        7. category: One of: restaurant, cafe, bar, activity, attraction, market, museum, park, view, shopping, hotel, or other
        8. latitude: Approximate latitude (as a number, required)
        9. longitude: Approximate longitude (as a number, required)
        10. imageURL: URL to an image of the place if you can find one, or null
        11. priceLevel: Price level indicator (1-4, where 4 is most expensive), or null
        
        Return 6-10 high-quality, diverse places that are actually nearby (within a few kilometers) and CURRENTLY OPEN.
        Prioritize places with good ratings (4.0+) when possible. Include a mix of popular and hidden gems.
        Make sure the coordinates are realistic for the location.
        Be specific and detailed - include ratings, addresses, and helpful tips like you would in a travel guide.
        ONLY include places you are confident are currently operating and open to visitors.
        Avoid generic or vague suggestions - be specific with actual business names and real addresses.
        
        Return ONLY a JSON array with this exact structure:
        [
          {
            "name": "The Brick Saloon",
            "rating": 4.5,
            "address": "100 W Pennsylvania Ave, Roslyn, WA 98941",
            "whyGo": "Established in 1889, it's the oldest continuously operating bar in Washington.",
            "whatToExpect": "Pub-style fare (burgers, fish & chips, chili) and a historic, lively atmosphere. Minors allowed in the dining area until 9pm.",
            "tip": "After dinner, stick around for live music (Fri & Sat) or soak up the history.",
            "category": "restaurant",
            "latitude": 47.2234,
            "longitude": -120.9912,
            "imageURL": null,
            "priceLevel": 2
          },
          ...
        ]
        
        Return ONLY the JSON array, no other text.
        """
        
        let requestBody: [String: Any] = [
            "model": Config.openAIModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 3000
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ OpenAI API error: \(response)")
                return []
            }
            
            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Extract JSON from response (might have markdown code blocks)
                let cleanedContent = content
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let jsonData = cleanedContent.data(using: .utf8),
                   let places = try? JSONDecoder().decode([NearbyPlaceResponse].self, from: jsonData) {
                    
                    // Create cards for each place
                    let storage = TokiStorageService.shared
                    var createdCardIds: [String] = []
                    
                    // Get existing cards to calculate transport between them
                    let existingCards = storage.getCardsForTrip(tripId).sorted { $0.takenAt < $1.takenAt }
                    var lastCardLocation: (lat: Double, lon: Double, name: String?)? = nil
                    
                    // Get last card's location if exists
                    if let lastCard = existingCards.last,
                       let lastPlaceId = lastCard.placeId,
                       let lastPlace = storage.getPlace(lastPlaceId) {
                        lastCardLocation = (lat: lastPlace.lat, lon: lastPlace.lon, name: lastPlace.label)
                    }
                    
                    for (index, place) in places.enumerated() {
                        // Create or find place with enhanced metadata
                        var placeMeta = PlaceMeta()
                        placeMeta.address = place.address
                        
                        let placeModel = storage.findOrCreatePlace(
                            lat: place.latitude,
                            lon: place.longitude,
                            label: place.name,
                            categories: [place.category]
                        )
                        
                        // Update place with metadata
                        var updatedPlace = placeModel
                        updatedPlace.meta = placeMeta
                        storage.updatePlace(updatedPlace)
                        
                        // Calculate activity duration
                        let activityDuration = TransportService.shared.estimateActivityDuration(category: place.category)
                        
                        // Calculate start time (after previous activity + transport)
                        let cardStartTime: Date
                        if let lastLocation = lastCardLocation {
                            let transport = TransportService.shared.calculateTransport(
                                from: lastLocation,
                                to: (lat: place.latitude, lon: place.longitude, name: place.name),
                                destination: locationName ?? ""
                            )
                            
                            // Create transport card before this activity
                            let transportCard = storage.createCard(
                                tripId: tripId,
                                kind: .note,
                                takenAt: Date().addingTimeInterval(TimeInterval(index * 60 * 60)), // Space them out
                                tags: ["transport", transport.method.rawValue],
                                text: "🚶 **Transport**\n\n\(transport.instructions)\n\nDistance: \(String(format: "%.1f", transport.distance / 1000.0)) km"
                            )
                            createdCardIds.append(transportCard.id)
                            
                            // Activity starts after transport
                            cardStartTime = Date().addingTimeInterval(TimeInterval(index * 60 * 60) + transport.estimatedTime)
                        } else {
                            cardStartTime = Date().addingTimeInterval(TimeInterval(index * 60 * 60))
                        }
                        
                        // Build rich text content with duration estimate
                        var cardText = "**\(place.name)**\n\n"
                        
                        if let rating = place.rating {
                            cardText += "⭐ \(String(format: "%.1f", rating))"
                            if let priceLevel = place.priceLevel {
                                cardText += " • \(String(repeating: "$", count: priceLevel))"
                            }
                            cardText += "\n\n"
                        }
                        
                        if let address = place.address {
                            cardText += "📍 \(address)\n\n"
                        }
                        
                        // Add duration estimate
                        let durationMinutes = Int(activityDuration / 60)
                        cardText += "⏱️ **Estimated duration:** \(durationMinutes) minutes\n\n"
                        
                        cardText += "**Why go:** \(place.whyGo)\n\n"
                        cardText += "**What to expect:** \(place.whatToExpect)\n\n"
                        
                        if let tip = place.tip {
                            cardText += "💡 **Tip:** \(tip)\n\n"
                        }
                        
                        // Add Google Maps link with place name
                        let placeNameEncoded = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
                        let addressEncoded = (place.address ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let query = addressEncoded.isEmpty ? placeNameEncoded : "\(placeNameEncoded)+\(addressEncoded)"
                        let googleMapsURL = "https://www.google.com/maps/search/?api=1&query=\(query)"
                        cardText += "🗺️ [Open in Google Maps](\(googleMapsURL))"
                        
                        // Create card with estimated start time
                        let card = storage.createCard(
                            tripId: tripId,
                            placeId: placeModel.id,
                            kind: .note,
                            takenAt: cardStartTime,
                            tags: [place.category, "nearby", "discovered", "ai-suggested"],
                            text: cardText
                        )
                        
                        createdCardIds.append(card.id)
                        
                        // Update last location for next iteration
                        lastCardLocation = (lat: place.latitude, lon: place.longitude, name: place.name)
                        
                        print("✅ Created card for: \(place.name) at \(cardStartTime)")
                    }
                    
                    print("✅ Created \(createdCardIds.count) cards from nearby places")
                    return createdCardIds
                } else {
                    print("❌ Failed to parse nearby places JSON")
                    if let contentPreview = cleanedContent.prefix(500) as? String {
                        print("Response preview: \(contentPreview)")
                    }
                }
            }
        } catch {
            print("❌ Error calling OpenAI API for nearby places: \(error)")
            return []
        }
        
        return []
    }
}

// MARK: - Rich Activity Models

struct RichActivitySuggestion: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double?
    let address: String?
    let whyGo: String
    let whatToExpect: String
    let tip: String?
    let category: String
    let latitude: Double
    let longitude: Double
    let priceLevel: Int?
}

private struct RichActivityResponse: Codable {
    let name: String
    let rating: Double?
    let address: String?
    let whyGo: String
    let whatToExpect: String
    let tip: String?
    let category: String
    let latitude: Double
    let longitude: Double
    let priceLevel: Int?
}

// MARK: - Nearby Place Response Model

private struct NearbyPlaceResponse: Codable {
    let name: String
    let rating: Double?
    let address: String?
    let whyGo: String
    let whatToExpect: String
    let tip: String?
    let category: String
    let latitude: Double
    let longitude: Double
    let imageURL: String?
    let priceLevel: Int?
}

// MARK: - AI Models

struct AttractionSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let location: (lat: Double, lon: Double)
    let imageURL: String?
}

enum ProcessedInput {
    case flight(FlightInfo)
    case hotel(HotelInfo)
    case meal(MealInfo)
    case place(PlaceInfo)
    case note(String)
}

struct FlightInfo {
    let destination: String?
    let date: Date?
    let airline: String?
    let flightNumber: String?
}

struct HotelInfo {
    let name: String?
    let checkIn: Date?
    let checkOut: Date?
}

struct MealInfo {
    let type: String
    let place: String?
    let time: Date?
}

struct PlaceInfo {
    let name: String?
    let description: String
}

