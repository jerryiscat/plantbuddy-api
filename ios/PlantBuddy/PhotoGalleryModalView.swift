import SwiftUI
import PhotosUI

struct PhotoGalleryModalView: View {
    let plant: Plant
    let photos: [PlantPhoto]
    let onPhotoSelected: (PlantPhoto) -> Void
    let onAddPhoto: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    // Add Photo Button
                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.plantBuddyMediumGreen)
                            Text("Add Photo")
                                .font(.caption)
                                .foregroundColor(Color.plantBuddyMediumGreen)
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Photo Grid
                    ForEach(photos) { photo in
                        PhotoGridItemView(
                            photo: photo,
                            isCover: plant.coverImageUrl == photo.imageUrl,
                            onTap: {
                                onPhotoSelected(photo)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .task(id: selectedPhotoItem) {
                guard let item = selectedPhotoItem else { return }
                await handlePhotoSelected(item)
            }
        }
    }
    
    @MainActor
    private func handlePhotoSelected(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
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
                    // Set as cover photo and reload
                    if let data = data,
                       let photoResponse = try? JSONDecoder().decode(PlantPhoto.self, from: data) {
                        setCoverPhoto(photoId: photoResponse.id)
                    }
                    onDismiss()
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
                onDismiss()
            }
        }.resume()
    }
}

struct PhotoGridItemView: View {
    let photo: PlantPhoto
    let isCover: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onTap) {
                AsyncImage(url: URL(string: photo.fullImageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCover ? Color.plantBuddyMediumGreen : Color.clear, lineWidth: 3)
                )
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if isCover {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.plantBuddyMediumGreen)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                        }
                        Spacer()
                    }
                )
            }
            
            Text(formatPhotoDate(photo.uploadedAt))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if isCover {
                Text("Cover Photo")
                    .font(.caption2)
                    .foregroundColor(.blue)
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

