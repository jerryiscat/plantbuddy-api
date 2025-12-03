import SwiftUI
import UIKit

struct ToolsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLightMeter = false
    @State private var showPlantDoctor = false
    @State private var showGraveyard = false
    @State private var archivedPlants: [Plant] = []
    @State private var isLoadingGraveyard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Light Meter
                    ToolCardView(
                        icon: "camera.metering.center.weighted",
                        title: "Light Meter",
                        description: "Measure light levels for optimal plant placement",
                        color: .yellow
                    ) {
                        showLightMeter = true
                    }
                    
                    // Plant Doctor
                    ToolCardView(
                        icon: "stethoscope",
                        title: "Plant Doctor",
                        description: "Diagnose plant health issues from photos",
                        color: .red
                    ) {
                        showPlantDoctor = true
                    }
                    
                    // The Graveyard
                    ToolCardView(
                        icon: "leaf.fill",
                        title: "The Graveyard",
                        description: "Archive of plants that didn't make it",
                        color: .gray,
                        badge: archivedPlants.count > 0 ? "\(archivedPlants.count)" : nil
                    ) {
                        showGraveyard = true
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Tools")
            .sheet(isPresented: $showLightMeter) {
                LightMeterView()
            }
            .sheet(isPresented: $showPlantDoctor) {
                PlantDoctorView()
            }
            .sheet(isPresented: $showGraveyard) {
                GraveyardView(plants: archivedPlants)
            }
            .onChange(of: showGraveyard) { isShowing in
                if isShowing {
                    fetchGraveyard()
                }
            }
        }
    }
    
    private func fetchGraveyard() {
        guard let token = authManager.token else { return }
        
        isLoadingGraveyard = true
        PlantService.shared.fetchGraveyard(token: token) { result in
            DispatchQueue.main.async {
                isLoadingGraveyard = false
                switch result {
                case .success(let plants):
                    self.archivedPlants = plants
                case .failure:
                    self.archivedPlants = []
                }
            }
        }
    }
}

struct ToolCardView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var badge: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Color.plantBuddyDarkerGreen)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.plantBuddyDarkerGreen)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color.plantBuddyDarkerGreen.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.plantBuddyDarkGreen.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

struct LightMeterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var lightLevel: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Light Meter")
                    .font(.title)
                    .bold()
                
                Text("Point your camera at the plant location to measure light levels")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                // Light Level Indicator
                VStack(spacing: 10) {
                    Text("\(Int(lightLevel))%")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(lightColor)
                    
                    Text(lightDescription)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Camera Button
                Button(action: {
                    // TODO: Open camera
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Start Measuring")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.plantBuddyMediumGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var lightColor: Color {
        if lightLevel < 30 {
            return .red
        } else if lightLevel < 70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var lightDescription: String {
        if lightLevel < 30 {
            return "Low Light"
        } else if lightLevel < 70 {
            return "Medium Light"
        } else {
            return "Bright Light"
        }
    }
}

struct PlantDoctorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Plant Doctor")
                    .font(.title)
                    .bold()
                
                Text("Upload a photo of your sick plant for diagnosis")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    Button(action: {
                        // TODO: Open photo picker
                    }) {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.plantBuddyMediumGreen)
                            Text("Select Photo")
                                .font(.headline)
                                .foregroundColor(Color.plantBuddyDarkGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                if selectedImage != nil {
                    Button(action: {
                        // TODO: Analyze image
                    }) {
                        Text("Diagnose Plant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GraveyardView: View {
    let plants: [Plant]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if plants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No archived plants")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Plants marked as dead will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach(plants) { plant in
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.name)
                                        .font(.headline)
                                    if let species = plant.species {
                                        Text(species)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("Added: \(plant.formattedCreatedAt)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("The Graveyard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ToolsView()
}

