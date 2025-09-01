import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showPremiumUpgrade = false
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.98, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Rectangle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 1: Welcome
                    OnboardingStepView(
                        title: "Hey there, dog lover! 🐕",
                        description: "Ever wondered what's going on in your pup's mind? We'll turn your dog photos into hilarious thought bubbles!",
                        systemImage: "pawprint.fill",
                        color: .blue
                    )
                    .tag(0)
                    
                    // Step 2: Free Credits
                    OnboardingStepView(
                        title: "Daily Treats 🦴",
                        description: "You get 3 free normal thoughts and 1 wild intrusive thought every day. Want more? We've got a special treat for you!",
                        systemImage: "gift.fill",
                        color: .green
                    )
                    .tag(1)
                    
                    // Step 3: How to Use
                    OnboardingStepView(
                        title: "Ready to Play? 📸",
                        description: "Just tap the camera button below to snap a photo of your dog. We'll do the mind-reading magic!",
                        systemImage: "camera.fill",
                        color: .orange
                    )
                    .tag(2)
                    
                    // Step 4: Community Guidelines
                    OnboardingStepView(
                        title: "Community Guidelines 🛡️",
                        description: "We're all about fun, but we take safety seriously! ✅ Only upload photos of dogs ✅ Keep content family-friendly ❌ NO malicious or harmful content ❌ NO spam, harassment, or bullying ⚠️ Violators will be BANNED immediately!",
                        systemImage: "shield.fill",
                        color: .red
                    )
                    .tag(3)
                    
                    // Step 5: Premium Features
                    OnboardingStepView(
                        title: "Go Premium! ⭐️",
                        description: "Unlock unlimited generations, priority processing, cool themes, and an ad-free experience. Your pup deserves the best!",
                        systemImage: "star.fill",
                        color: .purple
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

#Preview {
    OnboardingView()
} 