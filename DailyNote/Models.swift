// Models.swift
// Data models for DailyNote

import Foundation

// MARK: - Daily Data
struct DailyData: Codable {
    let date: Date
    var notes: String
    var tasks: [TaskItem]
    var waterIntake: Int  // in ml
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var taskProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(tasks.count)
    }
    
    var waterProgress: Double {
        min(Double(waterIntake) / 2000.0, 1.0)
    }
    
    static func newDay() -> DailyData {
        DailyData(
            date: Calendar.current.startOfDay(for: Date()),
            notes: "",
            tasks: [],
            waterIntake: 0
        )
    }
}

// MARK: - Task Item
struct TaskItem: Codable, Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var scheduledTime: Date?
    var createdAt: Date
    
    init(title: String, scheduledTime: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.scheduledTime = scheduledTime
        self.createdAt = Date()
    }
    
    var formattedTime: String? {
        guard let time = scheduledTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

// MARK: - Water Log Entry
struct WaterLogEntry: Codable, Identifiable {
    let id: UUID
    let amount: Int
    let timestamp: Date
    
    init(amount: Int) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = Date()
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Water Goal (Scheduled water intake)
struct WaterGoal: Codable, Identifiable {
    let id: UUID
    var amount: Int
    var scheduledTime: Date
    var isCompleted: Bool
    
    init(amount: Int, scheduledTime: Date) {
        self.id = UUID()
        self.amount = amount
        self.scheduledTime = scheduledTime
        self.isCompleted = false
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledTime)
    }
    
    var isOverdue: Bool {
        !isCompleted && scheduledTime < Date()
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var waterGoal: Int = 2000  // in ml
    var waterReminderInterval: Int = 60  // in minutes
    var launchAtLogin: Bool = false
    var workStartHour: Int = 9
    var workEndHour: Int = 18
}

// MARK: - Task Completion Record (History entry)
struct TaskCompletionRecord: Codable, Identifiable {
    let id: UUID
    let taskTitle: String
    let completedAt: Date
    let originalScheduledTime: Date?
    
    init(from task: TaskItem) {
        self.id = UUID()
        self.taskTitle = task.title
        self.completedAt = Date()
        self.originalScheduledTime = task.scheduledTime
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: completedAt)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: completedAt)
    }
}

// MARK: - Daily Summary (For history)
struct DailySummary: Codable, Identifiable {
    let id: UUID
    let date: Date
    var tasksCompleted: Int
    var tasksTotal: Int
    var waterIntake: Int
    var waterGoal: Int
    var completedTasks: [TaskCompletionRecord]
    
    init(from data: DailyData, waterGoal: Int) {
        self.id = UUID()
        self.date = data.date
        self.tasksCompleted = data.completedTasksCount
        self.tasksTotal = data.tasks.count
        self.waterIntake = data.waterIntake
        self.waterGoal = waterGoal
        self.completedTasks = data.tasks.filter { $0.isCompleted }.map { TaskCompletionRecord(from: $0) }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd/MM"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
    
    var taskProgress: Double {
        guard tasksTotal > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksTotal)
    }
    
    var waterProgress: Double {
        guard waterGoal > 0 else { return 0 }
        return min(Double(waterIntake) / Double(waterGoal), 1.0)
    }
}
