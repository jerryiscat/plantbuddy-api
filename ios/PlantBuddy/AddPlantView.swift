import SwiftUI
import PhotosUI
import UIKit

struct AddPlantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    let onPlantAdded: (Plant) -> Void
    
    @State private var name = ""
    @State private var species = ""
    @State private var careLevel: CareLevel = .easy
    @State private var careTips = ""
    @State private var frequencyDays = 7
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum CareLevel: String, CaseIterable {
        case easy = "easy"
        case moderate = "moderate"
        case hard = "hard"
        
        var displayName: String {
            switch self {
            case .easy: return "Easy"
            case .moderate: return "Moderate"
            case .hard: return "Hard"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                            Text(selectedImage == nil ? "Select Photo" : "Change Photo")
                        }
                    }
                    .task(id: selectedPhoto) {
                        await loadPhotoTask()
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    TextField("Plant Name *", text: $name)
                    TextField("Species (optional)", text: $species)
                    
                    Picker("Care Level", selection: $careLevel) {
                        ForEach(CareLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                Section(header: Text("Care Schedule")) {
                    HStack {
                        Text("Water every")
                        Spacer()
                        Stepper("\(frequencyDays) days", value: $frequencyDays, in: 1...30)
                    }
                }
                
                Section(header: Text("Care Tips (optional)")) {
                    TextEditor(text: $careTips)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @MainActor
    private func loadPhotoTask() async {
        guard let item = selectedPhoto else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.selectedImage = image
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
    
    private func savePlant() {
        guard !name.isEmpty else { return }
        
        isSubmitting = true
        
        guard let token = authManager.token else {
            errorMessage = "Not authenticated"
            showError = true
            isSubmitting = false
            return
        }
        
        // Upload image first if selected
        if let image = selectedImage {
            uploadImageAndCreatePlant(image: image, token: token)
        } else {
            createPlant(imageUrl: nil, token: token)
        }
    }
    
    private func uploadImageAndCreatePlant(image: UIImage, token: String) {
        // Create plant first, then upload photo in the completion handler
        createPlant(imageUrl: nil, token: token)
    }
    
    private func createPlant(imageUrl: String?, token: String) {
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/") else {
            errorMessage = "Invalid URL"
            showError = true
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "name": name,
            "care_level": careLevel.rawValue,
            "frequency_days": frequencyDays
        ]
        
        if !species.isEmpty {
            body["species"] = species
        }
        
        if !careTips.isEmpty {
            body["care_tips"] = careTips
        }
        
        if let imageUrl = imageUrl {
            body["image_url"] = imageUrl
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    showError = true
                    return
                }
                
                if httpResponse.statusCode == 201 {
                    if let data = data,
                       let plant = try? JSONDecoder().decode(Plant.self, from: data) {
                        onPlantAdded(plant)
                        // If we have an image, upload it after plant creation
                        if let image = self.selectedImage {
                            self.uploadPhotoToPlant(plantId: plant.id, image: image, token: token)
                        } else {
                            self.dismiss()
                        }
                    } else {
                        // If decode fails, create a mock plant for local display
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
                        let now = Date()
                        let nextWater = Calendar.current.date(byAdding: .day, value: frequencyDays, to: now) ?? now
                        
                        let newPlant = Plant(
                            id: Int.random(in: 1000...9999),
                            name: name,
                            species: species.isEmpty ? nil : species,
                            perenualId: nil,
                            careLevel: careLevel.rawValue,
                            imageUrl: imageUrl,
                            careTips: careTips.isEmpty ? nil : careTips,
                            isDead: false,
                            createdAt: formatter.string(from: now),
                            updatedAt: formatter.string(from: now),
                            schedules: [
                                Schedule(
                                    id: Int.random(in: 1000...9999),
                                    taskType: "WATER",
                                    frequencyDays: frequencyDays,
                                    nextDueDate: formatter.string(from: nextWater),
                                    isActive: true
                                )
                            ],
                            photos: nil,
                            coverImageUrl: imageUrl,
                            nextWaterDate: formatter.string(from: nextWater)
                        )
                        onPlantAdded(newPlant)
                        // If we have an image, upload it after plant creation
                        if let image = self.selectedImage {
                            self.uploadPhotoToPlant(plantId: newPlant.id, image: image, token: token)
                        } else {
                            self.dismiss()
                        }
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? String {
                        errorMessage = error
                    } else {
                        errorMessage = "Failed to create plant"
                    }
                    showError = true
                }
            }
        }.resume()
    }
    
    private func uploadPhotoToPlant(plantId: Int, image: UIImage, token: String) {
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/\(plantId)/photos/") else {
            errorMessage = "Invalid URL for photo upload"
            showError = true
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to convert image"
            showError = true
            return
        }
        
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
                if let error = error {
                    print("Photo upload error: \(error.localizedDescription)")
                    // Don't show error to user, just log it
                } else if let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 201 {
                    print("Photo uploaded successfully")
                }
                // Dismiss regardless of photo upload success
                self.dismiss()
            }
        }.resume()
    }
}

