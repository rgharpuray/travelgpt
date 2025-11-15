import SwiftUI

struct AISettingsView: View {
    @State private var apiKey: String = ""
    @State private var googleMapsKey: String = ""
    @State private var showingAPIKey = false
    @State private var showingGoogleMapsKey = false
    @State private var isSaving = false
    @State private var isSavingGoogleMaps = false
    @State private var saveMessage: String?
    @State private var googleMapsMessage: String?
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key"), footer: Text("Your API key is stored securely in the device keychain. Get your key from platform.openai.com")) {
                if showingAPIKey {
                    TextField("sk-...", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Enter your OpenAI API key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Button(action: { showingAPIKey.toggle() }) {
                    HStack {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        Text(showingAPIKey ? "Hide" : "Show")
                    }
                    .foregroundColor(.blue)
                }
                
                if let message = saveMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Saved") ? .green : .red)
                }
                
                Button(action: saveAPIKey) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(apiKey.isEmpty ? "Save API Key" : "Update API Key")
                    }
                }
                .disabled(isSaving || apiKey.isEmpty)
                
                if keychain.getOpenAIKey() != nil {
                    Button(role: .destructive, action: deleteAPIKey) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove API Key")
                        }
                    }
                }
            }
            
            Section(header: Text("Google Maps API Key"), footer: Text("Get your key from console.cloud.google.com. Enables nearby restaurant and activity suggestions with ratings and hours.")) {
                if showingGoogleMapsKey {
                    TextField("AIza...", text: $googleMapsKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Enter your Google Maps API key", text: $googleMapsKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Button(action: { showingGoogleMapsKey.toggle() }) {
                    HStack {
                        Image(systemName: showingGoogleMapsKey ? "eye.slash" : "eye")
                        Text(showingGoogleMapsKey ? "Hide" : "Show")
                    }
                    .foregroundColor(.blue)
                }
                
                if let message = googleMapsMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Saved") ? .green : .red)
                }
                
                Button(action: saveGoogleMapsKey) {
                    HStack {
                        if isSavingGoogleMaps {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(googleMapsKey.isEmpty ? "Save Google Maps Key" : "Update Google Maps Key")
                    }
                }
                .disabled(isSavingGoogleMaps || googleMapsKey.isEmpty)
                
                if keychain.getGoogleMapsKey() != nil {
                    Button(role: .destructive, action: deleteGoogleMapsKey) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove Google Maps Key")
                        }
                    }
                }
            }
            
            Section(header: Text("About"), footer: Text("AI suggestions use OpenAI's GPT models to provide personalized travel recommendations. Without an API key, the app will use curated suggestions.")) {
                HStack {
                    Text("OpenAI Status")
                    Spacer()
                    if keychain.getOpenAIKey() != nil {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Using Curated Suggestions", systemImage: "info.circle")
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Text("Google Maps Status")
                    Spacer()
                    if keychain.getGoogleMapsKey() != nil {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Using OpenStreetMap", systemImage: "info.circle")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("AI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAPIKey()
        }
    }
    
    private func loadAPIKey() {
        // Don't load the actual key for security - just check if one exists
        // User needs to re-enter if they want to update
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        // Basic validation
        guard apiKey.hasPrefix("sk-") || apiKey.hasPrefix("sk_") else {
            saveMessage = "Invalid API key format. Should start with 'sk-'"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                saveMessage = nil
            }
            return
        }
        
        isSaving = true
        saveMessage = nil
        
        keychain.saveOpenAIKey(apiKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            apiKey = "" // Clear for security
            saveMessage = "API key saved successfully!"
            
            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                saveMessage = nil
            }
        }
    }
    
    private func deleteAPIKey() {
        keychain.deleteOpenAIKey()
        apiKey = ""
        saveMessage = "API key removed"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            saveMessage = nil
        }
    }
    
    private func saveGoogleMapsKey() {
        guard !googleMapsKey.isEmpty else { return }
        
        // Basic validation
        guard googleMapsKey.hasPrefix("AIza") else {
            googleMapsMessage = "Invalid API key format. Should start with 'AIza'"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                googleMapsMessage = nil
            }
            return
        }
        
        isSavingGoogleMaps = true
        googleMapsMessage = nil
        
        keychain.saveGoogleMapsKey(googleMapsKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSavingGoogleMaps = false
            googleMapsKey = "" // Clear for security
            googleMapsMessage = "Google Maps API key saved successfully!"
            
            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                googleMapsMessage = nil
            }
        }
    }
    
    private func deleteGoogleMapsKey() {
        keychain.deleteGoogleMapsKey()
        googleMapsKey = ""
        googleMapsMessage = "Google Maps API key removed"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            googleMapsMessage = nil
        }
    }
}

