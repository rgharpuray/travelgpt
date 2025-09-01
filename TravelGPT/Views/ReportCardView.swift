import SwiftUI

struct ReportCardView: View {
    let card: TravelCard
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportCard.ReportReason = .inappropriate
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var isBlocking = false
    @State private var showBlockSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Report Card")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help us keep the community safe by reporting inappropriate content.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Card preview
                TravelCardView(card: card)
                    .frame(width: 280, height: 380)
                    .scaleEffect(0.8)
                
                // Block User Button (separate operation)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Block User")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: blockUser) {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                                .foregroundColor(.white)
                            Text("Block this user")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(isBlocking)
                    
                    Text("Hide all future posts from this user")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Report Section (separate from blocking)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Content")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(ReportCard.ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedReason == reason ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Optional description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Details (Optional)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Provide more details about your report...", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Submit report button
                Button(action: submitReport) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "flag.fill")
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSubmitting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Report Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Report Submitted", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for helping keep our community safe. We'll review your report within 24 hours.")
        }
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK") {
                // Don't dismiss, let user continue with report if they want
            }
        } message: {
            Text("This user has been blocked. You won't see their posts anymore.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func blockUser() {
        isBlocking = true
        
        Task {
            do {
                let blockResponse = try await BackendService.shared.blockUser(cardId: card.id)
                print("✅ User blocked successfully: \(blockResponse.message)")
                
                await MainActor.run {
                    isBlocking = false
                    showBlockSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    errorMessage = "Failed to block user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let reportResponse = try await BackendService.shared.reportCard(
                    cardId: card.id,
                    reason: selectedReason,
                    description: description.isEmpty ? nil : description
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
