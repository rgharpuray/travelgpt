import SwiftUI

struct OnboardingFlowView: View {
    var onFinish: (() -> Void)? = nil
    enum Step {
        case welcome, dailyTreats, camera, contentGuidelines, personality, premium, finish
    }
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var step: Step = .welcome
    @State private var isGuest: Bool? = nil
    @State private var petName: String = ""
    @State private var petImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var animateOut = false
    @State private var showBounce = false
    
    // Modern gradient colors
    let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.5, blue: 0.9), // Deep blue
            Color(red: 0.4, green: 0.7, blue: 1.0), // Light blue
            Color(red: 0.6, green: 0.8, blue: 1.0)  // Sky blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.9, green: 0.4, blue: 0.6), // Pink
            Color(red: 1.0, green: 0.6, blue: 0.8)  // Light pink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Modern gradient background
            primaryGradient.ignoresSafeArea()
            
            // Subtle geometric pattern
            GeometricPattern()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern progress indicator
                ModernProgressIndicator(currentStep: step)
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Main content
                content
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Navigation controls
                controls
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
            .opacity(animateOut ? 0 : 1)
            .offset(y: animateOut ? 100 : 0)
            .animation(.easeInOut(duration: 0.7), value: animateOut)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $petImage, onImageSelected: { img in
                petImage = img
            })
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch step {
        case .welcome:
            ModernWelcomeScreen()
        case .dailyTreats:
            ModernDailyTreatsScreen()
        case .camera:
            ModernCameraScreen()
        case .contentGuidelines:
            ModernContentGuidelinesScreen()
        case .personality:
            ModernPersonalitySelectionView(
                onComplete: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .premium
                    }
                },
                onSkip: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .premium
                    }
                }
            )
        case .premium:
            ModernPremiumScreen()
        case .finish:
            ModernFinishScreen()
        }
    }
    
    @ViewBuilder
    var controls: some View {
        HStack(spacing: 16) {
            if step != .welcome {
                ModernButton(title: "Back", isBack: true) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        switch step {
                        case .dailyTreats: step = .welcome
                        case .camera: step = .dailyTreats
                        case .contentGuidelines: step = .camera
                        case .personality: step = .contentGuidelines
                        case .premium: step = .personality
                        case .finish: step = .premium
                        default: break
                        }
                    }
                }
            }
            switch step {
            case .welcome:
                ModernPrimaryButton(title: "Get Started") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .dailyTreats
                    }
                }
            case .dailyTreats:
                ModernPrimaryButton(title: "Continue") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .camera
                    }
                }
            case .camera:
                ModernPrimaryButton(title: "Continue") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .contentGuidelines
                    }
                }
            case .contentGuidelines:
                ModernPrimaryButton(title: "Continue") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .personality
                    }
                }
            case .personality:
                ModernPrimaryButton(title: "Continue") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .premium
                    }
                }
            case .premium:
                ModernPrimaryButton(title: "Continue") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step = .finish
                    }
                }
            case .finish:
                ModernPrimaryButton(title: "Start Exploring") {
                    withAnimation {
                        animateOut = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            hasCompletedOnboarding = true
                            onFinish?()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Modern Screen Components

struct ModernWelcomeScreen: View {
    @State private var showBounce = false
    @State private var titleScale = 0.8
    @State private var showMascot = false
    
    var body: some View {
        VStack(spacing: 40) {
            // App icon with modern styling
            if let logo = UIImage(named: "AppIcon") {
                Image(uiImage: logo)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .scaleEffect(showBounce ? 1.05 : 1.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true), value: showBounce)
                    .onAppear {
                        showBounce = true
                    }
            }
            
            VStack(spacing: 20) {
                Text("Welcome to BarkRodeo")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .scaleEffect(titleScale)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: titleScale)
                    .onAppear {
                        titleScale = 1.0
                    }
                
                Text("Discover what your dog is really thinking with AI-powered thought bubbles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Modern dog illustration
            ModernDogIllustration()
                .opacity(showMascot ? 1.0 : 0.0)
                .offset(y: showMascot ? 0 : 30)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: showMascot)
                .onAppear {
                    showMascot = true
                }
        }
    }
}

struct ModernDailyTreatsScreen: View {
    @State private var treatJarRotation = 0.0
    @State private var treatBounce = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Modern animated icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(treatJarRotation))
                    .scaleEffect(treatBounce ? 1.1 : 1.0)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: treatJarRotation)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true), value: treatBounce)
                    .onAppear {
                        treatJarRotation = 360
                        treatBounce = true
                    }
            }
            
            VStack(spacing: 20) {
                Text("Daily Generations")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("Free users get 3 normal thoughts and 1 wild thought per day")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Text("Premium users enjoy unlimited generations")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ModernCameraScreen: View {
    @State private var cameraWiggle = false
    @State private var cameraPulse = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Modern camera icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 160, height: 120)
                    .blur(radius: 15)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 100)
                    .scaleEffect(cameraPulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: cameraPulse)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .offset(x: cameraWiggle ? -3 : 3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: cameraWiggle)
            }
            .onAppear {
                cameraWiggle = true
                cameraPulse = true
            }
            
            VStack(spacing: 20) {
                Text("Ready to Create")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Simply upload a photo of your dog and watch the magic happen")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

struct ModernContentGuidelinesScreen: View {
    @State private var shieldScale = 1.0
    @State private var warningOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 40) {
            // Modern shield icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(shieldScale)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: shieldScale)
                
                // Warning indicator
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(.orange)
                    .offset(x: 30, y: -30)
                    .opacity(warningOpacity)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: warningOpacity)
            }
            .onAppear {
                shieldScale = 1.1
                warningOpacity = 1.0
            }
            
            VStack(spacing: 20) {
                Text("Community Guidelines")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("We maintain a safe and enjoyable environment for everyone")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        GuidelineRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            text: "Only upload photos of dogs",
                            isPositive: true
                        )
                        
                        GuidelineRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            text: "Keep content family-friendly",
                            isPositive: true
                        )
                        
                        GuidelineRow(
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            text: "No harmful or inappropriate content",
                            isPositive: false
                        )
                        
                        GuidelineRow(
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            text: "No spam or harassment",
                            isPositive: false
                        )
                    }
                    .padding(.top, 8)
                }
                
                Text("Violations result in immediate account suspension")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
    }
}

struct ModernPremiumScreen: View {
    @State private var tagRotation = 0.0
    @State private var sparkleOpacity = 0.0
    @State private var tagFloat = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Modern premium icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(tagRotation))
                    .offset(y: tagFloat ? -5 : 5)
                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: tagRotation)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: tagFloat)
                
                // Sparkles
                ForEach(0..<6) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.yellow)
                        .offset(
                            x: 50 * cos(Double(index) * .pi / 3),
                            y: 50 * sin(Double(index) * .pi / 3)
                        )
                        .opacity(sparkleOpacity)
                        .scaleEffect(sparkleOpacity > 0 ? 1.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: sparkleOpacity
                        )
                }
            }
            .onAppear {
                tagRotation = 360
                sparkleOpacity = 1.0
                tagFloat = true
            }
            
            VStack(spacing: 20) {
                Text("Unlock Premium")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("Get unlimited generations and premium features")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "infinity")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            
                            Text("Unlimited daily generations")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            
                            Text("Priority processing")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            
                            Text("Exclusive themes and styles")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                                .frame(width: 20)
                            
                            Text("Ad-free experience")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct ModernFinishScreen: View {
    @State private var confettiScale = 0.0
    @State private var confettiRotation = 0.0
    
    var body: some View {
        VStack(spacing: 40) {
            // Modern celebration icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(confettiScale)
                    .rotationEffect(.degrees(confettiRotation))
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: confettiScale)
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: confettiRotation)
            }
            .onAppear {
                confettiScale = 1.0
                confettiRotation = 360
            }
            
            VStack(spacing: 20) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Ready to discover what your dog is really thinking? Let's create some amazing content together!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Modern Components

struct ModernProgressIndicator: View {
    let currentStep: OnboardingFlowView.Step
    @State private var waggingPaw = false
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<6) { index in
                ModernProgressDot(
                    isFilled: isStepCompleted(index),
                    isCurrent: isCurrentStep(index)
                )
                .frame(width: 12, height: 12)
                .scaleEffect(isStepCompleted(index) ? 1.3 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isStepCompleted(index))
            }
        }
        .onAppear {
            waggingPaw = true
        }
    }
    
    private func isStepCompleted(_ index: Int) -> Bool {
        let stepOrder: [OnboardingFlowView.Step] = [.welcome, .dailyTreats, .camera, .contentGuidelines, .personality, .premium]
        guard let currentIndex = stepOrder.firstIndex(of: currentStep) else { return false }
        return index <= currentIndex
    }
    
    private func isCurrentStep(_ index: Int) -> Bool {
        let stepOrder: [OnboardingFlowView.Step] = [.welcome, .dailyTreats, .camera, .contentGuidelines, .personality, .premium]
        guard let currentIndex = stepOrder.firstIndex(of: currentStep) else { return false }
        return index == currentIndex
    }
}

struct ModernProgressDot: View {
    let isFilled: Bool
    let isCurrent: Bool
    
    var body: some View {
        Circle()
            .fill(isFilled ? Color.white : Color.white.opacity(0.3))
            .shadow(color: isCurrent ? .white.opacity(0.5) : .clear, radius: 3)
    }
}

struct ModernPrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(minWidth: 140, maxWidth: 240)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct ModernButton: View {
    let title: String
    let isBack: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isBack ? "chevron.left" : "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct GeometricPattern: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Subtle geometric shapes
                ForEach(0..<8) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
                
                // Subtle circles
                ForEach(0..<12) { index in
                    Circle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: CGFloat.random(in: 20...80))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

struct ModernDogIllustration: View {
    @State private var tailWag = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Modern dog silhouette
            Image(systemName: "dog.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
                .rotationEffect(.degrees(-10))
            
            // Wagging tail
            Image(systemName: "tail")
                .font(.system(size: 25, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
                .rotationEffect(.degrees(tailWag ? 15 : -15))
                .offset(x: -8, y: -12)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: tailWag)
        }
        .onAppear {
            tailWag = true
        }
    }
}

struct GuidelineRow: View {
    let icon: String
    let iconColor: Color
    let text: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}



// MARK: - Modern Personality Selection View

struct ModernPersonalitySelectionView: View {
    @State private var selectedPersonalities: [String] = []
    @State private var selectedBreed: String = ""
    @State private var customBreed: String = ""
    @State private var showCustomBreedField = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Tell us about your dog")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Select up to 5 personality traits that best describe your dog")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Personality Categories using card-style layout
                VStack(spacing: 20) {
                    HStack {
                        Text("Personality Traits")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(selectedPersonalities.count)/5")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedPersonalities.count >= 5 ? .orange : .secondary)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(PersonalityCategories.allCategories) { category in
                            ModernPersonalityCard(
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
                VStack(spacing: 20) {
                    HStack {
                        Text("Breed (Optional)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
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
                                    .foregroundColor(selectedBreed.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Custom breed option
                        if selectedBreed == "Other" || showCustomBreedField {
                            TextField("Enter custom breed", text: $customBreed)
                                .textFieldStyle(ModernTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        // "Other" option
                        if selectedBreed.isEmpty || (selectedBreed != "Other" && !showCustomBreedField) {
                            Button("Or enter a custom breed") {
                                selectedBreed = "Other"
                                showCustomBreedField = true
                            }
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: savePersonalityData) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Saving..." : "Save & Continue")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedPersonalities.isEmpty ? Color.gray : Color.blue)
                        )
                    }
                    .disabled(selectedPersonalities.isEmpty || isLoading)
                    
                    Button("Skip for now") {
                        onSkip()
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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

struct ModernPersonalityCard: View {
    let category: PersonalityCategory
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    // Get icon and color for each personality type
    private var personalityIcon: String {
        switch category.id {
        case "cuddle_comfort":
            return "heart.fill"
        case "food_obsessed":
            return "fork.knife"
        case "socialites_extroverts":
            return "person.2.fill"
        case "drama_sass":
            return "theatermasks.fill"
        case "oddballs_daydreamers":
            return "sparkles"
        case "chaos_crew":
            return "tornado"
        case "planners_plotters":
            return "chart.line.uptrend.xyaxis"
        case "low_energy_legends":
            return "moon.zzz.fill"
        default:
            return "pawprint.fill"
        }
    }
    
    private var personalityColor: Color {
        switch category.id {
        case "cuddle_comfort":
            return Color(red: 0.95, green: 0.3, blue: 0.5) // Vibrant pink
        case "food_obsessed":
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Bright orange
        case "socialites_extroverts":
            return Color(red: 0.2, green: 0.7, blue: 0.9) // Electric blue
        case "drama_sass":
            return Color(red: 0.8, green: 0.2, blue: 0.8) // Magenta
        case "oddballs_daydreamers":
            return Color(red: 0.4, green: 0.8, blue: 0.4) // Lime green
        case "chaos_crew":
            return Color(red: 0.9, green: 0.3, blue: 0.2) // Fire red
        case "planners_plotters":
            return Color(red: 0.3, green: 0.5, blue: 0.9) // Royal blue
        case "low_energy_legends":
            return Color(red: 0.6, green: 0.6, blue: 0.8) // Slate blue
        default:
            return Color.blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: personalityIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : personalityColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : personalityColor.opacity(0.1))
                    )
                
                // Title
                Text(category.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Description
                Text(category.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [personalityColor, personalityColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isDisabled ? 0.4 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? personalityColor : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? personalityColor.opacity(0.3) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .disabled(isDisabled)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .foregroundColor(.primary)
    }
}

#Preview {
    OnboardingFlowView()
} 