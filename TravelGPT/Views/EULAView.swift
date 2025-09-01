import SwiftUI

struct EULAView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasAcceptedEULA: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Terms of Service & Community Guidelines")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Please read and accept our terms before using BarkRodeo")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Content Guidelines Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Guidelines")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By using BarkRodeo, you agree to:")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("✅ ONLY upload photos of dogs")
                                Text("✅ Keep content family-friendly and appropriate")
                                Text("✅ Respect other users and the community")
                                Text("❌ NEVER upload malicious, harmful, or inappropriate content")
                                Text("❌ NEVER upload spam, harassment, or bullying content")
                                Text("❌ NEVER upload content promoting violence or illegal activities")
                                Text("❌ NEVER upload content that could harm others")
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples of PROHIBITED content:")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Malicious, harmful, or offensive images")
                                Text("• Content that could harm or harass others")
                                Text("• Spam, repetitive, or low-quality content")
                                Text("• Content promoting violence or illegal activities")
                                Text("• Any content that violates community standards")
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Zero Tolerance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🚨 ZERO TOLERANCE POLICY")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("BarkRodeo has a ZERO TOLERANCE policy for malicious, inappropriate, or harmful content. We will:")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• IMMEDIATELY BAN users who upload malicious content")
                            Text("• Remove any content that violates our guidelines")
                            Text("• Act on reports within 24 hours")
                            Text("• Take legal action if necessary")
                            Text("• Report illegal content to authorities")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                        
                        Text("⚠️ WARNING: Uploading malicious, inappropriate, or harmful content will result in immediate account termination and potential legal consequences.")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    
                    // Reporting Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reporting Inappropriate Content")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("If you encounter inappropriate content:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Use the report button on any card")
                            Text("• Select the appropriate reason for reporting")
                            Text("• Provide additional details if needed")
                            Text("• We will review all reports within 24 hours")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    
                    // Privacy Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• We collect and process your data as described in our Privacy Policy")
                        Text("• Your photos are used to generate dog thoughts and may be stored")
                        Text("• We do not share your personal information with third parties")
                        Text("• You can delete your account and data at any time")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    
                    // Legal Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Legal Terms")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("• By using this app, you agree to these terms")
                        Text("• We may update these terms from time to time")
                        Text("• Continued use after changes constitutes acceptance")
                        Text("• These terms are governed by applicable law")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Us")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("If you have questions about these terms or need to report issues, please contact us at support@argosventures.pro")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Accept") {
                        hasAcceptedEULA = true
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Decline") {
                        // Exit app or show alert
                        exit(0)
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    EULAView(hasAcceptedEULA: .constant(false))
} 