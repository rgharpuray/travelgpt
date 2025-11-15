import SwiftUI
import MapKit

struct TokiTripView: View {
    let trip: Trip
    @StateObject private var storage = TokiStorageService.shared
    @State private var selectedTab = 0
    @State private var showingCapture = false
    @State private var captureCardKind: CardKind = .photo
    @State private var selectedPlace: Place?
    @State private var showingPlaceSheet = false
    @State private var showingAllTrips = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Content Views
                Group {
                    if selectedTab == 0 {
                        TokiFeedView(trip: trip)
                    } else if selectedTab == 1 {
                        TokiMapView(trip: trip, selectedPlace: $selectedPlace, showingPlaceSheet: $showingPlaceSheet)
                    } else if selectedTab == 2 {
                        TokiSummaryView(trip: trip)
                    } else {
                        TokiTripSettingsView(trip: trip)
                    }
                }
                
                // Capture Orb
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CaptureOrb { cardKind in
                            captureCardKind = cardKind
                            showingCapture = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Above tab bar
                    }
                }
            }
            .navigationTitle(trip.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAllTrips = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Trips")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Custom Tab Bar
                TabBar(selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showingCapture) {
                NewCardView(trip: trip, initialKind: captureCardKind)
            }
            .sheet(item: $selectedPlace) { place in
                PlaceSheetView(place: place, trip: trip)
            }
            .fullScreenCover(isPresented: $showingAllTrips) {
                TokiHomeView()
            }
        }
    }
}

struct TabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        (name: "Feed", icon: "list.bullet"),
        (name: "Map", icon: "map"),
        (name: "Summary", icon: "chart.bar"),
        (name: "Settings", icon: "gearshape")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                        Text(tabs[index].name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

struct CaptureOrb: View {
    let action: (CardKind) -> Void
    @State private var isPressed = false
    @State private var showingRadialMenu = false
    
    var body: some View {
        ZStack {
            // Radial Menu
            if showingRadialMenu {
                RadialMenu(action: action, showingMenu: $showingRadialMenu)
            }
            
            // Main Button
            Button(action: {
                withAnimation {
                    showingRadialMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showingRadialMenu ? Color.red : Color.blue)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: showingRadialMenu ? "xmark" : "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }
}

struct RadialMenu: View {
    let action: (CardKind) -> Void
    @Binding var showingMenu: Bool
    
    private let options: [(icon: String, label: String, color: Color, kind: CardKind)] = [
        (icon: "photo", label: "Photo", color: Color.blue, kind: .photo),
        (icon: "note.text", label: "Note", color: Color.green, kind: .note),
        (icon: "waveform", label: "Audio", color: Color.orange, kind: .audio),
        (icon: "mappin", label: "Place", color: Color.purple, kind: .note)
    ]
    
    var body: some View {
        ZStack {
            backgroundOverlay
            menuButtons
        }
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    showingMenu = false
                }
            }
    }
    
    private var menuButtons: some View {
        ForEach(0..<options.count, id: \.self) { index in
            menuButton(for: index)
        }
    }
    
    private func menuButton(for index: Int) -> some View {
        let option = options[index]
        let angle = calculateAngle(for: index)
        let offset = calculateOffset(angle: angle)
        
        return Button(action: {
            withAnimation {
                showingMenu = false
            }
            action(option.kind)
        }) {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.title3)
                Text(option.label)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(12)
            .background(option.color)
            .clipShape(Circle())
            .shadow(radius: 4)
        }
        .offset(x: offset.x, y: offset.y)
    }
    
    private func calculateAngle(for index: Int) -> Double {
        let angleStep = 2 * Double.pi / Double(options.count)
        return Double(index) * angleStep - Double.pi / 2
    }
    
    private func calculateOffset(angle: Double) -> (x: CGFloat, y: CGFloat) {
        let radius: CGFloat = 90
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return (x: x, y: y)
    }
}

