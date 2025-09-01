import SwiftUI

struct IntrusiveModeTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Namespace private var brainIconNamespace
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon with animation
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 120))
                    .foregroundColor(.purple)
                    .matchedGeometryEffect(id: "brainIcon", in: brainIconNamespace)
                    .modifier(GlowingEffect(glow: true))
                
                // Content
                VStack(spacing: 24) {
                    Text("Intrusive Mode Activated! 🧠")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 16) {
                        Text("You've discovered the wild side of dog thoughts!")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "brain.head.profile", text: "Darker, more chaotic thoughts")
                            FeatureRow(icon: "exclamationmark.triangle", text: "Unfiltered canine consciousness")
                            FeatureRow(icon: "flame", text: "Pure doggy chaos unleashed")
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Action button
                Button("Got it!") {
                    completeTutorial()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeTutorial() {
        UserDefaults.standard.set(true, forKey: "hasCompletedIntrusiveTutorial")
        dismiss()
    }
}

#Preview {
    IntrusiveModeTutorialView()
} 
 