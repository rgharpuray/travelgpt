import SwiftUI

struct EditPersonalityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var profileStore: ProfileStore
    
    @State private var selectedPersonalities: [String] = []
    @State private var selectedBreed: String = ""
    @State private var customBreed: String = ""
    @State private var showCustomBreedField = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        // Icon
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        Text("Edit Personality & Breed")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Update your dog's personality traits and breed")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Personality Categories
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("Personality Traits")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(selectedPersonalities.count)/5")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedPersonalities.count >= 5 ? .blue : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedPersonalities.count >= 5 ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                )
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(PersonalityCategories.allCategories) { category in
                                PersonalityCard(
                                    category: category,
                                    isSelected: selectedPersonalities.contains(category.id),
                                    isDisabled: !selectedPersonalities.contains(category.id) && selectedPersonalities.count >= 5
                                ) {
                                    togglePersonality(category.id)
                                }
                            }
                        }
                    }
                    
                    // Breed Selection
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "dog.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("Breed (Optional)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            // Popular breeds dropdown
                            Menu {
                                ForEach(PersonalityCategories.popularBreeds, id: \.self) { breed in
                                    Button(breed) {
                                        selectedBreed = breed
                                        showCustomBreedField = false
                                        customBreed = ""
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "dog")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 8)
                                    
                                    Text(getDisplayBreedText())
                                        .foregroundColor(getDisplayBreedText() == "Select a breed" ? .gray : .primary)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Custom breed option
                            if selectedBreed == "Other" || showCustomBreedField {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 8)
                                    
                                    TextField("Enter custom breed", text: $customBreed)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // "Other" option
                            if selectedBreed.isEmpty || (selectedBreed != "Other" && !showCustomBreedField) {
                                Button(action: {
                                    selectedBreed = "Other"
                                    showCustomBreedField = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 16))
                                        Text("Or enter a custom breed")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            print("🔘 Save button tapped!")
                            savePersonalityData()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isLoading ? "Saving..." : "Save Changes")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPersonalities.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(16)
                        }
                        .disabled(selectedPersonalities.isEmpty || isLoading)
                        
                        Button("Clear All") {
                            selectedPersonalities = []
                            selectedBreed = ""
                            customBreed = ""
                            showCustomBreedField = false
                        }
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .medium))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Edit Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentData()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Personality and breed information updated successfully!")
            }
        }
    }
    
    private func loadCurrentData() {
        print("🔄 Loading current data...")
        if let profile = profileStore.profile {
            print("📋 Profile found, personality categories: \(profile.personalityCategories)")
            print("🐕 Dog breed: '\(profile.dogBreed)'")
            
            selectedPersonalities = profile.personalityCategories
            let breed = profile.dogBreed
            
            // Check if the breed is in the popular breeds list
            if PersonalityCategories.popularBreeds.contains(breed) {
                selectedBreed = breed
                customBreed = ""
                showCustomBreedField = false
                print("✅ Popular breed selected: \(breed)")
            } else if !breed.isEmpty {
                // It's a custom breed
                selectedBreed = "Other"
                customBreed = breed
                showCustomBreedField = true
                print("✅ Custom breed loaded: \(breed)")
            } else {
                // No breed selected
                selectedBreed = ""
                customBreed = ""
                showCustomBreedField = false
                print("ℹ️ No breed selected")
            }
        } else {
            print("❌ No profile found")
        }
        print("🎯 Selected personalities after loading: \(selectedPersonalities)")
    }
    
    private func togglePersonality(_ categoryId: String) {
        print("🔄 Toggling personality: \(categoryId)")
        print("📋 Current selected: \(selectedPersonalities)")
        
        if selectedPersonalities.contains(categoryId) {
            selectedPersonalities.removeAll { $0 == categoryId }
            print("➖ Removed \(categoryId)")
        } else if selectedPersonalities.count < 5 {
            selectedPersonalities.append(categoryId)
            print("➕ Added \(categoryId)")
        } else {
            print("❌ Cannot add more than 5 personalities")
        }
        
        print("📋 Updated selected: \(selectedPersonalities)")
    }
    
    private func getDisplayBreedText() -> String {
        if selectedBreed.isEmpty {
            return "Select a breed"
        } else if selectedBreed == "Other" {
            return customBreed.isEmpty ? "Custom breed" : customBreed
        } else {
            return selectedBreed
        }
    }
    
    private func savePersonalityData() {
        print("💾 Saving personality data...")
        print("📋 Selected personalities: \(selectedPersonalities)")
        print("🐕 Selected breed: '\(selectedBreed)'")
        print("✏️ Custom breed: '\(customBreed)'")
        
        isLoading = true
        
        let finalBreed = selectedBreed == "Other" ? (customBreed.isEmpty ? nil : customBreed) : (selectedBreed.isEmpty ? nil : selectedBreed)
        print("🎯 Final breed to save: \(finalBreed ?? "nil")")
        
        Task {
            do {
                let response = try await BackendService.shared.saveOnboardingData(
                    personalityCategories: selectedPersonalities,
                    breed: finalBreed
                )
                
                await MainActor.run {
                    isLoading = false
                    if response.success {
                        // Store the data locally since profile endpoint doesn't return it
                        if let profile = profileStore.profile {
                            print("🔄 Updating profile locally with new personality data")
                            // Create a new profile with updated personality data
                            let updatedProfile = Profile(
                                total_cards: profile.total_cards,
                                total_likes: profile.total_likes,
                                destination_name: profile.destination_name,
                                profile_image_url: profile.profile_image_url,
                                is_premium: profile.is_premium,
                                blocked_users_count: profile.blocked_users_count,
                                personality_categories: selectedPersonalities,
                                breed: finalBreed,
                                device_id: profile.device_id,
                                cards_generated_normal: profile.cardsGeneratedNormal,
                                cards_generated_intrusive: profile.cardsGeneratedIntrusive,
                                date_joined: profile.dateJoined
                            )
                            profileStore.profile = updatedProfile
                            print("✅ Profile updated locally with personalities: \(selectedPersonalities)")
                            print("✅ Profile updated locally with breed: \(finalBreed ?? "nil")")
                        }
                        
                        // Also refresh profile to get any other updates
                        Task {
                            await profileStore.fetchProfile()
                        }
                        showSuccess = true
                    } else {
                        errorMessage = response.message
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    EditPersonalityView(profileStore: ProfileStore())
} 