import SwiftUI
import PhotosUI

struct CheckInView: View {
    let card: TravelCard
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkInStore = CheckInStore()
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Check In")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("You're at \(card.destination_name)!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Card preview
                    VStack(spacing: 16) {
                        Text("Location")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        AsyncImage(url: URL(string: card.image_url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.destination_name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(card.thought)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Check-in form
                    VStack(spacing: 20) {
                        // Photo section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📸 Add a Photo (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        Button(action: {
                                            self.selectedImage = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.7))
                                                .clipShape(Circle())
                                        }
                                        .padding(12),
                                        alignment: .topTrailing
                                    )
                            } else {
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    VStack(spacing: 16) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue)
                                        
                                        Text("Add Photo")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        Text("Capture your moment")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                }
                            }
                        }
                        
                        // Caption section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("💭 Caption (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Share your experience...", text: $caption, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    // Submit button
                    Button(action: submitCheckIn) {
                        HStack(spacing: 12) {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Check In")
                            }
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green)
                        )
                    }
                    .disabled(isSubmitting)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, onImageSelected: { _ in })
            }
        }
    }
    
    private func submitCheckIn() {
        isSubmitting = true
        
        Task {
            do {
                let response = try await TravelCardAPIService.shared.checkIn(
                    cardId: card.id,
                    photo: selectedImage,
                    caption: caption.isEmpty ? nil : caption,
                    coordinates: nil
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
                
                print("Check-in successful: \(response.id)")
                
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error checking in: \(error)")
                }
            }
        }
    }
}

@MainActor
class CheckInStore: ObservableObject {
    @Published var checkIns: [CheckInResponse] = []
    @Published var isLoading = false
    
    func loadCheckIns(for cardId: Int) async {
        isLoading = true
        do {
            checkIns = try await TravelCardAPIService.shared.getCheckIns(cardId: cardId)
        } catch {
            print("Error loading check-ins: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    CheckInView(card: TravelCard(
        id: 1,
        destination_name: "Sagrada Familia",
        image_url: "https://example.com/image.jpg",
        is_valid_destination: true,
        thought: "Amazing architecture!",
        created_at: "2025-01-15T10:30:00Z",
        updated_at: nil,
        like_count: 42,
        is_liked: false,
        is_owner: false,
        is_intrusive_mode: false,
        device_destination_name: "Sagrada Familia",
        owner_destination_name: "Sagrada Familia",
        rarity: "epic",
        collection_tags: ["Barcelona"],
        category: "Museums",
        isVerified: true,
        checkInPhotos: [],
        s3_url: nil,
        location: "Barcelona, Spain",
        coordinates: nil,
        admin_review_status: "approved",
        admin_reviewer_id: nil,
        admin_reviewed_at: nil,
        admin_notes: nil,
        check_in_count: 15,
        comment_count: 8,
        is_liked_by_user: false,
        is_checked_in_by_user: false,
        moods: [],
        user: nil
    ))
}

