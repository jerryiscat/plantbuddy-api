import SwiftUI

struct PlantHistoryView: View {
    let plant: Plant
    let activities: [ActivityLog]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if activities.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clock")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No activity history")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Start caring for your plant to see history here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        ForEach(activities, id: \.id) { activity in
                            ActivityRowView(activity: activity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Activity History")
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

struct ActivityRowView: View {
    let activity: ActivityLog
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundColor(activityColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.actionType.capitalized)
                    .font(.headline)
                
                Text(formatDate(activity.actionDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var activityIcon: String {
        switch activity.actionType {
        case "WATER": return "drop.fill"
        case "FERTILIZE": return "leaf.fill"
        case "REPOTTING": return "square.stack.3d.up.fill"
        case "PRUNE": return "scissors"
        case "SNOOZE": return "clock.fill"
        case "SKIPPED_RAIN": return "cloud.rain.fill"
        case "PHOTO": return "photo.fill"
        case "NOTE": return "note.text"
        default: return "checkmark.circle"
        }
    }
    
    private var activityColor: Color {
        switch activity.actionType {
        case "WATER": return Color.plantBuddyMediumGreen
        case "FERTILIZE": return .green
        case "REPOTTING": return .brown
        case "PRUNE": return .orange
        case "SNOOZE": return .orange
        case "SKIPPED_RAIN": return Color.plantBuddyMediumGreen
        case "PHOTO": return .purple
        case "NOTE": return .gray
        default: return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            if Calendar.current.isDateInToday(date) {
                return "Today at \(formatTime(date))"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday at \(formatTime(date))"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
                return dateFormatter.string(from: date)
            }
        }
        return dateString
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

