import Foundation

struct MockData {
    static let plants: [Plant] = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let now = Date()
        
        let nextWater1 = Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now
        let nextWater2 = now
        
        return [
            Plant(
                id: 1,
                name: "Monstera",
                species: "Monstera Deliciosa",
                perenualId: nil,
                careLevel: "easy",
                imageUrl: "https://encrypted-tbn1.gstatic.com/licensed-image?q=tbn:ANd9GcRHQkxf2BzWYpnkAIp7exmT3CLxTRy5hV6tiCdPv2SU5sfaG5g80m6kf9HZxXIQE9kgNnX1AsfPXzPFmZRa21kqNzV3ZN3lrn_st7O4ZhdUZPCSoUw",   // NEW
                careTips: "Water when top inch of soil is dry",
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 1,
                        taskType: "WATER",
                        frequencyDays: 7,
                        nextDueDate: formatter.string(from: nextWater1),
                        isActive: true
                    )
                ],
                photos: [
                    PlantPhoto(
                        id: 101,
                        imageUrl: "https://encrypted-tbn1.gstatic.com/licensed-image?q=tbn:ANd9GcRHQkxf2BzWYpnkAIp7exmT3CLxTRy5hV6tiCdPv2SU5sfaG5g80m6kf9HZxXIQE9kgNnX1AsfPXzPFmZRa21kqNzV3ZN3lrn_st7O4ZhdUZPCSoUw",
                        uploadedAt: formatter.string(from: now),
                        isCover: true
                    ),
                ],
                coverImageUrl: "https://encrypted-tbn1.gstatic.com/licensed-image?q=tbn:ANd9GcRHQkxf2BzWYpnkAIp7exmT3CLxTRy5hV6tiCdPv2SU5sfaG5g80m6kf9HZxXIQE9kgNnX1AsfPXzPFmZRa21kqNzV3ZN3lrn_st7O4ZhdUZPCSoUw",
                nextWaterDate: formatter.string(from: nextWater1)
            ),
            Plant(
                id: 2,
                name: "Snake Plant",
                species: "Sansevieria",
                perenualId: nil,
                careLevel: "easy",
                imageUrl: "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcTu90gFkRP637Esu0OJrMLA0n8LTKlCbN0Wrm7MLuByM1lK5FG_42tWf8WARvWDGUDje8PuAHS88YhALzu9Oj4s3x4-K1sat8G1Dv9shha0qaskAv0",
                careTips: "Very low maintenance",
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 2,
                        taskType: "WATER",
                        frequencyDays: 14,
                        nextDueDate: formatter.string(from: nextWater2),
                        isActive: true
                    )
                ],
                photos: nil,
                coverImageUrl: "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcTu90gFkRP637Esu0OJrMLA0n8LTKlCbN0Wrm7MLuByM1lK5FG_42tWf8WARvWDGUDje8PuAHS88YhALzu9Oj4s3x4-K1sat8G1Dv9shha0qaskAv0",
                nextWaterDate: formatter.string(from: nextWater2)
            ),
            Plant(
                id: 3,
                name: "Pothos",
                species: "Epipremnum Aureum",
                perenualId: 300,
                careLevel: "easy",
                imageUrl: "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcSTtWKzWPF5fxK2TR1Jr2dvMVNSJMnbUr2XipOxqBcQM2UMx4eD6_N2IiaQ0MUgYmTVG_AEYnryOnpfKtoxpElG-ReUD1HXbu-E4mLzdZnM3uLlPo0",
                careTips: nil,
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 3,
                        taskType: "FERTILIZE",
                        frequencyDays: 30,
                        nextDueDate: formatter.string(from: Calendar.current.date(byAdding: .day, value: 15, to: now) ?? now),
                        isActive: true
                    )
                ],
                photos: [
                    PlantPhoto(
                        id: 103,
                        imageUrl: "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcSTtWKzWPF5fxK2TR1Jr2dvMVNSJMnbUr2XipOxqBcQM2UMx4eD6_N2IiaQ0MUgYmTVG_AEYnryOnpfKtoxpElG-ReUD1HXbu-E4mLzdZnM3uLlPo0",
                        uploadedAt: formatter.string(from: now),
                        isCover: true
                    ),
                    PlantPhoto(
                        id: 104,
                        imageUrl: "https://lh3.googleusercontent.com/gg-dl/ABS2GSm9A2cGNk0Aqf0IGFX5K0r3QL9lr4MdZsn8RwS7ySvXHoZ4Id_VYRHvnMiurPTGE_3lTP_q_WlIlShx713b32S7i-sSrIrKShrUygCKKgAoEpjn9CefRkfWd9-B4QEWXgOvSD4nVk9L8wNuUeQ6d6Mq_-hI8Fudl7iotenrNQVIaN3V=s1024-rj",
                        uploadedAt: formatter.string(from: now),
                        isCover: false
                    )
                ],
                coverImageUrl: "https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcSTtWKzWPF5fxK2TR1Jr2dvMVNSJMnbUr2XipOxqBcQM2UMx4eD6_N2IiaQ0MUgYmTVG_AEYnryOnpfKtoxpElG-ReUD1HXbu-E4mLzdZnM3uLlPo0",
                nextWaterDate: nil
            )
        ]
    }()
    
    static let tasks: [Task] = [
        Task(
            id: 1,
            plantId: 1,
            plantName: "Monstera",
            taskType: "WATER",
            dueDate: ISO8601DateFormatter().string(from: Date()),
            frequencyDays: 7,
            scheduleId: 1,
            isOverdue: false
        ),
        Task(
            id: 2,
            plantId: 2,
            plantName: "Snake Plant",
            taskType: "WATER",
            dueDate: ISO8601DateFormatter().string(from: Date()),
            frequencyDays: 14,
            scheduleId: 2,
            isOverdue: false
        )
    ]
    
    // Activity logs storage
    private static var activityLogs: [Int: [ActivityLog]] = [:]
    
    static func getActivitiesForPlant(plantId: Int) -> [ActivityLog] {
        return activityLogs[plantId] ?? []
    }
    
    static func addActivity(plantId: Int, activity: ActivityLog) {
        if activityLogs[plantId] == nil {
            activityLogs[plantId] = []
        }
        activityLogs[plantId]?.insert(activity, at: 0) // Add to beginning
    }
}

