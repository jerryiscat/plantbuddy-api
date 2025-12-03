import SwiftUI
import PhotosUI
import UIKit

struct MyJungleView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var plants: [Plant] = MockData.plants  // Using mock data - not fetching from API yet
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedSort: SortOption = .name
    @State private var showAddPlant = false
    @State private var selectedPlant: Plant?
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case easy = "Easy"
        case moderate = "Moderate"
        case hard = "Hard"
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case species = "Species"
        case careLevel = "Care Level"
    }
    
    var filteredAndSortedPlants: [Plant] {
        var filtered = plants.filter { !$0.isDead }
        
        // Filter by care level
        if selectedFilter != .all {
            filtered = filtered.filter { $0.careLevel == selectedFilter.rawValue.lowercased() }
        }
        
        // Sort
        switch selectedSort {
        case .name:
            filtered.sort { $0.name < $1.name }
        case .species:
            filtered.sort { ($0.species ?? "") < ($1.species ?? "") }
        case .careLevel:
            filtered.sort { ($0.careLevel ?? "") < ($1.careLevel ?? "") }
        }
        
        return filtered
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and Sort Buttons
                HStack(spacing: 15) {
                    // Filter Menu
                    Menu {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if selectedFilter == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedFilter.rawValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.plantBuddyLightGreen.opacity(0.5))
                        .foregroundColor(Color.plantBuddyDarkerGreen)
                        .cornerRadius(8)
                    }
                    
                    // Sort Menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedSort = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if selectedSort == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(selectedSort.rawValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.plantBuddyLightGreen.opacity(0.5))
                        .foregroundColor(Color.plantBuddyDarkerGreen)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.appBackground)
                
                // Plant Grid
                if isLoading {
                    ProgressView("Loading Plants...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            fetchPlants()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredAndSortedPlants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No plants found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first plant!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(filteredAndSortedPlants) { plant in
                                PlantCardView(plant: plant)
                                    .onTapGesture {
                                        selectedPlant = plant
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("My Jungle")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddPlant = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Color.plantBuddyMediumGreen)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddPlant) {
                AddPlantView { newPlant in
                    // Add to local list (will save to backend when API is enabled)
                    plants.append(newPlant)
                }
                .environmentObject(authManager)
            }
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
            // Note: API calls disabled - using mock data for now
            // Uncomment to enable API fetching:
            // .onAppear { fetchPlants() }
            // .refreshable { fetchPlants() }
        }
    }
    
    private func fetchPlants() {
        guard let token = authManager.token else { return }
        
        isLoading = true
        errorMessage = nil
        
        PlantService.shared.fetchPlants(token: token) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedPlants):
                    self.plants = fetchedPlants
                case .failure(let error):
                    self.errorMessage = "Failed to load plants: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var showHistory = false
    @State private var showScheduleManager = false
    @State private var showActivityLog = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoForAction: PhotosPickerItem?
    @State private var plantActivities: [ActivityLog] = []
    @State private var plantPhotos: [PlantPhoto] = []
    @State private var selectedPhoto: PlantPhoto?
    @State private var showPhotoGalleryModal = false
    @State private var refreshingPlant = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    coverImageView
                    plantInfoView
                    careTipsView
                    schedulesView
                    photoGalleryView
                    quickActionsView
                    manageSectionsView
                }
            }
            .navigationTitle("Plant Details")
            .toolbarBackground(Color.plantBuddyDarkerGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                PlantHistoryView(plant: plant, activities: plantActivities)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showScheduleManager) {
                ScheduleManagerView(plant: plant)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showActivityLog) {
                LogActivityView(plant: plant) {
                    loadActivities()
                }
                .environmentObject(authManager)
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoForAction, matching: .images)
            .task(id: selectedPhotoForAction) {
                guard let photo = selectedPhotoForAction else { return }
                await handlePhotoSelected(photo)
            }
            .onAppear {
                loadActivities()
                loadPhotos()
            }
        }
    }
    
    private var coverImageView: some View {
        Group {
            if let imageUrl = plant.displayImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 400, height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    showPhotoGalleryModal = true
                }
            } else {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipped()
                    .foregroundColor(.green)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        showPhotoGalleryModal = true
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(isPresented: $showPhotoGalleryModal) {
            PhotoGalleryModalView(
                plant: plant,
                photos: plantPhotos,
                onPhotoSelected: { photo in
                    setCoverPhoto(photoId: photo.id)
                },
                onAddPhoto: {
                    showPhotoPicker = true
                },
                onDismiss: {
                    loadPhotos()
                }
            )
            .environmentObject(authManager)
        }
    }
    
    private var plantInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plant.name)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                if let careLevel = plant.careLevel {
                    Text(careLevel.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(careLevelColor(careLevel).opacity(0.2))
                        .foregroundColor(careLevelColor(careLevel))
                        .cornerRadius(8)
                }
            }
            
            if let species = plant.species {
                Text(species)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                if let perenualId = plant.perenualId {
                    Label("Perenual ID: \(perenualId)", systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Label("Added: \(plant.formattedCreatedAt)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var careTipsView: some View {
        Group {
            if let careTips = plant.careTips, !careTips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Care Tips")
                        .font(.headline)
                    Text(careTips)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    private var schedulesView: some View {
        Group {
            if let schedules = plant.schedules, !schedules.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Care Schedule")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(schedules, id: \.id) { schedule in
                        if schedule.isActive {
                            HStack {
                                Image(systemName: scheduleIcon(schedule.taskType))
                                    .foregroundColor(scheduleColor(schedule.taskType))
                                VStack(alignment: .leading) {
                                    Text(schedule.taskType.capitalized)
                                        .font(.subheadline)
                                        .bold()
                                    Text("Every \(schedule.frequencyDays) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(formatScheduleDate(schedule.nextDueDate))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    private var photoGalleryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photo Gallery")
                    .font(.headline)
                Spacer()
                Button(action: { showPhotoPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.plantBuddyMediumGreen)
                }
            }
            .padding(.horizontal)
            
            if !plantPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(plantPhotos) { photo in
                            PhotoThumbnailView(
                                photo: photo,
                                isCover: plant.coverImageUrl == photo.imageUrl,
                                onTap: {
                                    selectedPhoto = photo
                                },
                                onDoubleTap: {
                                    setCoverPhoto(photoId: photo.id)
                                },
                                onSetCover: {
                                    setCoverPhoto(photoId: photo.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No photos yet. Tap + to add photos.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
    }
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ActionButton(icon: "drop.fill", title: "Water", color: .blue) {
                    performAction("WATER")
                }
                ActionButton(icon: "leaf.fill", title: "Fertilize", color: .green) {
                    performAction("FERTILIZE")
                }
                ActionButton(icon: "square.stack.3d.up.fill", title: "Repot", color: .brown) {
                    performAction("REPOTTING")
                }
                ActionButton(icon: "scissors", title: "Prune", color: .orange) {
                    performAction("PRUNE")
                }
                ActionButton(icon: "clock.fill", title: "Snooze", color: .orange) {
                    performAction("SNOOZE")
                }
                ActionButton(icon: "cloud.rain.fill", title: "Skipped", color: .blue) {
                    performAction("SKIPPED_RAIN")
                }
                ActionButton(icon: "photo.fill", title: "Photo", color: .pink) {
                    showPhotoPicker = true
                }
                ActionButton(icon: "note.text", title: "Note", color: .gray) {
                    showActivityLog = true
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var manageSectionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showScheduleManager = true }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.black)
                    Text("Manage Schedules")
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Button(action: { showHistory = true }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.black)
                    Text("View History")
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
    
    private func loadActivities() {
        // For now, use mock data. Later can fetch from API
        plantActivities = MockData.getActivitiesForPlant(plantId: plant.id)
    }
    
    private func loadPhotos() {
        // Load initial photos from plant model into state
        plantPhotos = plant.photos ?? []
    }
    
    @MainActor
    private func handlePhotoSelected(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Upload photo directly to plant gallery
                uploadPhotoToPlant(image: image)
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
    
    private func uploadPhotoToPlant(image: UIImage) {
        guard let token = authManager.token else { return }
        
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/\(plant.id)/photos/") else { return }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"plant.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    // Append newly uploaded photo so gallery updates immediately
                    if let data = data,
                       let photoResponse = try? JSONDecoder().decode(PlantPhoto.self, from: data) {
                        plantPhotos.append(photoResponse)
                    }
                }
            }
        }.resume()
    }
    
    private func setCoverPhoto(photoId: Int) {
        guard let token = authManager.token else { return }
        
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/\(plant.id)/photos/\(photoId)/set_cover/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Reload photos to reflect cover photo change
                loadPhotos()
            }
        }.resume()
    }
    
    private func performAction(_ actionType: String, imageUrl: String? = nil) {
        guard let token = authManager.token else { return }
        
        var notes: String? = nil
        if let imageUrl = imageUrl {
            // Store image URL in notes for PHOTO action
            notes = imageUrl
        }
        
        PlantService.shared.performAction(
            plantId: plant.id,
            actionType: actionType,
            notes: notes,
            imageUrl: imageUrl,
            token: token
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Add to local activity log
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    let activity = ActivityLog(
                        id: Int.random(in: 1000...9999),
                        actionType: actionType,
                        actionDate: formatter.string(from: Date()),
                        notes: notes
                    )
                    
                    MockData.addActivity(plantId: plant.id, activity: activity)
                    loadActivities()
                    
                    // If PHOTO action, refresh photos
                    if actionType == "PHOTO" {
                        loadPhotos()
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    private func careLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "easy": return Color.plantBuddyDarkGreen
        case "moderate": return Color.plantBuddyOrange
        case "hard": return Color.plantBuddyDarkerGreen
        default: return Color.plantBuddyDarkGreen
        }
    }
    
    private func scheduleIcon(_ type: String) -> String {
        switch type {
        case "WATER": return "drop.fill"
        case "FERTILIZE": return "leaf.fill"
        case "REPOTTING": return "square.stack.3d.up.fill"
        case "PRUNE": return "scissors"
        default: return "checkmark.circle"
        }
    }
    
    private func scheduleColor(_ type: String) -> Color {
        switch type {
        case "WATER": return Color.waterBlue
        case "FERTILIZE": return Color.plantBuddyYellowGreen
        case "REPOTTING": return Color.plantBuddyOrange
        case "PRUNE": return Color.plantBuddyDarkGreen
        default: return Color.plantBuddyDarkerGreen
        }
    }
    
    private func formatScheduleDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: PlantPhoto
    let isCover: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onSetCover: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: photo.fullImageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCover ? Color.plantBuddyMediumGreen : Color.clear, lineWidth: 3)
                )
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
            .onTapGesture {
                onTap()
            }
            
            // Timestamp
            Text(formatPhotoDate(photo.uploadedAt))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if isCover {
                Text("Cover")
                    .font(.caption2)
                    .foregroundColor(Color.plantBuddyMediumGreen)
            } else {
                Button("Set Cover") {
                    onSetCover()
                }
                .font(.caption2)
                .foregroundColor(Color.plantBuddyMediumGreen)
            }
        }
    }
    
    private func formatPhotoDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        
        // Try alternative format
        let altFormatter = ISO8601DateFormatter()
        altFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    MyJungleView()
}

