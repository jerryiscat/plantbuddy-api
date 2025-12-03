import Foundation

struct PlantPhoto: Identifiable, Codable {
    let id: Int
    let imageUrl: String
    let uploadedAt: String
    let isCover: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case uploadedAt = "uploaded_at"
        case isCover = "is_cover"
    }
    
    var fullImageUrl: String {
        // If URL is relative (starts with /), prepend base URL
        if imageUrl.hasPrefix("/") {
            return "http://192.168.4.23:8000\(imageUrl)"
        }
        return imageUrl
    }
}

struct Schedule: Codable {
    let id: Int
    let taskType: String
    let frequencyDays: Int
    let nextDueDate: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskType = "task_type"
        case frequencyDays = "frequency_days"
        case nextDueDate = "next_due_date"
        case isActive = "is_active"
    }
}

struct Plant: Identifiable, Codable {
    let id: Int
    let name: String
    let species: String?
    let perenualId: Int?
    let careLevel: String?
    let imageUrl: String?
    let careTips: String?
    let isDead: Bool
    let createdAt: String
    let updatedAt: String
    let schedules: [Schedule]?
    let photos: [PlantPhoto]?
    let coverImageUrl: String?
    let nextWaterDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, species, schedules, photos
        case perenualId = "perenual_id"
        case careLevel = "care_level"
        case imageUrl = "image_url"
        case careTips = "care_tips"
        case isDead = "is_dead"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coverImageUrl = "cover_image_url"
        case nextWaterDate = "next_water_date"
    }
    
    var nextWaterDateParsed: Date? {
        guard let dateString = nextWaterDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: dateString)
    }
    
    var displayImageUrl: String? {
        // Use cover image, or first photo, or legacy imageUrl
        if let coverUrl = coverImageUrl {
            return coverUrl
        }
        if let firstPhoto = photos?.first {
            return firstPhoto.imageUrl
        }
        return imageUrl
    }
    
    var formattedCreatedAt: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

struct Task: Identifiable, Codable {
    let id: Int
    let plantId: Int
    let plantName: String
    let taskType: String
    let dueDate: String
    let frequencyDays: Int
    let scheduleId: Int
    let isOverdue: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case plantId = "plant_id"
        case plantName = "plant_name"
        case taskType = "task_type"
        case dueDate = "due_date"
        case frequencyDays = "frequency_days"
        case scheduleId = "schedule_id"
        case isOverdue = "is_overdue"
    }
    
    var dueDateParsed: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: dueDate) ?? Date()
    }
    
    var formattedDueDate: String {
        let date = dueDateParsed
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < Date() {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct ActionResponse: Codable {
    let message: String
    let activityLog: ActivityLog?
    let nextDueDate: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case activityLog = "activity_log"
        case nextDueDate = "next_due_date"
    }
}

struct ActivityLog: Codable {
    let id: Int
    let actionType: String
    let actionDate: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case actionType = "action_type"
        case actionDate = "action_date"
        case notes
    }
}
