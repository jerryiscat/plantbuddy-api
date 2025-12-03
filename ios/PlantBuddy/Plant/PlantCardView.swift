import SwiftUI

struct PlantCardView: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plant Image
            ZStack {
                if let imageUrl = plant.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.plantBuddyMediumGreen)
                        .padding(20)
                }
            }
            .frame(width: 150, height: 150)
            .aspectRatio(1, contentMode: .fill) // Square crop
            .background(Color.plantBuddyLightGreen.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Plant Name
            Text(plant.name)
                .font(.headline)
                .foregroundColor(Color.plantBuddyDarkerGreen)
                .lineLimit(1)
            
            // Next Water Date
            if let nextWater = plant.nextWaterDateParsed {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(Color.plantBuddyMediumGreen)
                    Text("Water: \(formatDate(nextWater))")
                        .font(.caption)
                        .foregroundColor(Color.plantBuddyDarkerGreen)
                }
            } else {
                Text("No schedule")
                    .font(.caption)
                    .foregroundColor(Color.plantBuddyDarkerGreen.opacity(0.6))
            }
            
            // Care Level Badge
            if let careLevel = plant.careLevel {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(careLevel.capitalized)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(careLevelColor(careLevel).opacity(0.2))
                .foregroundColor(careLevelColor(careLevel))
                .cornerRadius(4)
            }
            
            // Species
            if let species = plant.species {
                Text(species)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.plantBuddyDarkGreen.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < Date() {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days) day\(days == 1 ? "" : "s") overdue"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func careLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "easy":
            return Color.plantBuddyMediumGreen
        case "moderate":
            return Color.plantBuddyOrange
        case "hard":
            return Color.plantBuddyDarkerGreen
        default:
            return Color.plantBuddyDarkGreen
        }
    }
}

#Preview("Plant Card") {
    PlantCardView(plant: MockData.plants.first!)
}
