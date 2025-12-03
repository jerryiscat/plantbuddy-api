import SwiftUI

struct CareView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var tasks: [Task] = MockData.tasks  // Using mock data - not fetching from API yet
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showUndoToast = false
    @State private var lastCompletedTask: Task?
    @State private var showUpcoming = false
    @State private var processingTaskId: Int?
    
    var todayTasks: [Task] {
        tasks.filter { Calendar.current.isDateInToday($0.dueDateParsed) }
    }
    
    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue }
    }
    
    var upcomingTasks: [Task] {
        tasks.filter { !$0.isOverdue && !Calendar.current.isDateInToday($0.dueDateParsed) }
            .sorted { $0.dueDateParsed < $1.dueDateParsed }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overdue Warning
                    if !overdueTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.plantBuddyDarkerGreen)
                                Text("Overdue")
                                    .font(.headline)
                                    .foregroundColor(Color.plantBuddyDarkerGreen)
                            }
                            
                            ForEach(overdueTasks) { task in
                                TaskRowView(
                                    task: task,
                                    isProcessing: processingTaskId == task.id,
                                    onAction: { actionType in
                                        performAction(task: task, actionType: actionType)
                                    }
                                )
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Today Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Color.plantBuddyDarkerGreen)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if todayTasks.isEmpty {
                            Text("No tasks for today! 🎉")
                                .foregroundColor(Color.plantBuddyDarkerGreen)
                                .padding(.horizontal)
                        } else {
                            ForEach(todayTasks) { task in
                                TaskRowView(
                                    task: task,
                                    isProcessing: processingTaskId == task.id,
                                    onAction: { actionType in
                                        performAction(task: task, actionType: actionType)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Upcoming Section
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            withAnimation {
                                showUpcoming.toggle()
                            }
                        }) {
                            HStack {
                                Text("Upcoming")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(Color(hex: "E2852E"))
                                Spacer()
                                Image(systemName: showUpcoming ? "chevron.up" : "chevron.down")
                            }
                            .padding(.horizontal)
                        }
                        
                        if showUpcoming {
                            if upcomingTasks.isEmpty {
                                Text("No upcoming tasks")
                                    .foregroundColor(Color.plantBuddyDarkerGreen)
                                    .padding(.horizontal)
                            } else {
                                ForEach(upcomingTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        isProcessing: processingTaskId == task.id,
                                        onAction: { actionType in
                                            performAction(task: task, actionType: actionType)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Care")
            // Note: API calls disabled - using mock data for now
            // Uncomment to enable API fetching:
            // .onAppear { fetchTasks() }
            // .refreshable { fetchTasks() }
            .overlay(
                // Undo Toast
                VStack {
                    Spacer()
                    if showUndoToast, let task = lastCompletedTask {
                        UndoToastView(task: task, onUndo: {
                            undoAction(task: task)
                        })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: showUndoToast)
            )
        }
    }
    
    private func fetchTasks() {
        guard let token = authManager.token else { return }
        
        isLoading = true
        errorMessage = nil
        
        TaskService.shared.fetchTodayTasks(token: token) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedTasks):
                    self.tasks = fetchedTasks
                case .failure(let error):
                    self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func performAction(task: Task, actionType: String) {
        guard let token = authManager.token else { return }
        
        processingTaskId = task.id
        
        PlantService.shared.performAction(
            plantId: task.plantId,
            actionType: actionType,
            notes: nil,
            token: token
        ) { result in
            DispatchQueue.main.async {
                processingTaskId = nil
                switch result {
                case .success:
                    // Refresh tasks
                    fetchTasks()
                    
                    // Show undo toast for WATER actions
                    if actionType == "WATER" {
                        lastCompletedTask = task
                        showUndoToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showUndoToast = false
                            }
                        }
                    }
                case .failure(let error):
                    errorMessage = "Failed to perform action: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func undoAction(task: Task) {
        guard let token = authManager.token else { return }
        
        PlantService.shared.undoAction(plantId: task.plantId, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showUndoToast = false
                    fetchTasks()
                case .failure(let error):
                    errorMessage = "Failed to undo: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let isProcessing: Bool
    let onAction: (String) -> Void
    @State private var showActionMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Task Icon
            Image(systemName: taskIcon)
                .font(.title2)
                .foregroundColor(taskColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.plantName)
                    .font(.headline)
                    .foregroundColor(Color.plantBuddyDarkerGreen)
                
                HStack(spacing: 8) {
                    Text(task.taskType.capitalized)
                        .font(.subheadline)
                        .foregroundColor(Color.plantBuddyDarkerGreen)
                    
                    Spacer()
                    
                    Text(task.formattedDueDate)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? Color.plantBuddyDarkerGreen : Color.plantBuddyDarkGreen)
                }
            }
            
            Spacer()
            
            // Action Menu
            Menu {
                Button(action: { onAction("WATER") }) {
                    Label("Water", systemImage: "drop.fill")
                }
                Button(action: { onAction("SNOOZE") }) {
                    Label("Snooze (1 day)", systemImage: "clock.fill")
                }
                Button(action: { onAction("SKIPPED_RAIN") }) {
                    Label("Skipped (Rain)", systemImage: "cloud.rain.fill")
                }
                Button(action: { onAction("NOTE") }) {
                    Label("Add Note", systemImage: "note.text")
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.plantBuddyMediumGreen)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var taskIcon: String {
        switch task.taskType {
        case "WATER":
            return "drop.fill"
        case "FERTILIZE":
            return "leaf.fill"
        case "REPOTTING":
            return "square.stack.3d.up.fill"
        case "PRUNE":
            return "scissors"
        default:
            return "checkmark.circle"
        }
    }
    
    private var taskColor: Color {
        switch task.taskType {
        case "WATER":
            return Color.waterBlue
        case "FERTILIZE":
            return Color.plantBuddyYellowGreen
        case "REPOTTING":
            return Color.plantBuddyOrange
        case "PRUNE":
            return Color.plantBuddyDarkGreen
        default:
            return Color.plantBuddyDarkerGreen
        }
    }
}

struct UndoToastView: View {
    let task: Task
    let onUndo: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.plantBuddyDarkerGreen)
            
            Text("\(task.taskType.capitalized)ed \(task.plantName)")
                .font(.subheadline)
                .foregroundColor(Color.plantBuddyDarkerGreen)
            
            Spacer()
            
            Button("Undo") {
                onUndo()
            }
            .font(.subheadline)
            .foregroundColor(Color.plantBuddyMediumGreen)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    CareView().environmentObject(AuthManager())
}
