import SwiftUI

struct PersonalitySelectionView: View {
    @State private var selectedPersonalities: [String] = []
    @State private var selectedBreed: String = ""
    @State private var customBreed: String = ""
    @State private var showCustomBreedField = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    // Pistachio Green
    let pistachio = Color(red: 0.576, green: 0.773, blue: 0.447)
    let lightPistachio = Color(red: 0.7, green: 0.85, blue: 0.6)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Tell us about your pup! 🐕")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Select up to 5 personality traits that best describe your dog")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                // Personality Categories
                VStack(spacing: 16) {
                    HStack {
                        Text("Personality Traits")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(selectedPersonalities.count)/5")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedPersonalities.count >= 5 ? .orange : .white.opacity(0.8))
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
                        Text("Breed (Optional)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
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
                                Text(selectedBreed.isEmpty ? "Select a breed" : selectedBreed)
                                    .foregroundColor(selectedBreed.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Custom breed option
                        if selectedBreed == "Other" || showCustomBreedField {
                            TextField("Enter custom breed", text: $customBreed)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        // "Other" option
                        if selectedBreed.isEmpty || (selectedBreed != "Other" && !showCustomBreedField) {
                            Button("Or enter a custom breed") {
                                selectedBreed = "Other"
                                showCustomBreedField = true
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: savePersonalityData) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Saving..." : "Save & Continue")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPersonalities.isEmpty ? Color.gray : pistachio)
                        .cornerRadius(16)
                    }
                    .disabled(selectedPersonalities.isEmpty || isLoading)
                    
                    Button("Skip for now") {
                        onSkip()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(pistachio.ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func togglePersonality(_ categoryId: String) {
        if selectedPersonalities.contains(categoryId) {
            selectedPersonalities.removeAll { $0 == categoryId }
        } else if selectedPersonalities.count < 5 {
            selectedPersonalities.append(categoryId)
        }
    }
    
    private func savePersonalityData() {
        isLoading = true
        
        let finalBreed = selectedBreed == "Other" ? (customBreed.isEmpty ? nil : customBreed) : (selectedBreed.isEmpty ? nil : selectedBreed)
        
        Task {
            do {
                let response = try await BackendService.shared.saveOnboardingData(
                    personalityCategories: selectedPersonalities,
                    breed: finalBreed
                )
                
                await MainActor.run {
                    isLoading = false
                    if response.success {
                        onComplete()
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
    PersonalitySelectionView(
        onComplete: { print("Complete") },
        onSkip: { print("Skip") }
    )
} 