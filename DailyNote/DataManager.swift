// DataManager.swift
// Handles data persistence for DailyNote

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var currentData: DailyData
    @Published var waterLog: [WaterLogEntry] = []
    @Published var waterGoals: [WaterGoal] = []
    @Published var settings: AppSettings
    @Published var dailyHistory: [DailySummary] = []
    
    private let dataKey = "dailyNoteData"
    private let waterLogKey = "waterLog"
    private let waterGoalsKey = "waterGoals"
    private let settingsKey = "appSettings"
    private let historyKey = "dailyHistory"
    private var cancellables = Set<AnyCancellable>()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        // Load settings
        if let settingsData = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? decoder.decode(AppSettings.self, from: settingsData) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
        
        // Load or create today's data
        if let savedData = UserDefaults.standard.data(forKey: dataKey),
           let decoded = try? decoder.decode(DailyData.self, from: savedData) {
            // Check if it's a new day
            if Calendar.current.isDateInToday(decoded.date) {
                self.currentData = decoded
            } else {
                self.currentData = DailyData.newDay()
            }
        } else {
            self.currentData = DailyData.newDay()
        }
        
        // Load water log
        if let waterData = UserDefaults.standard.data(forKey: waterLogKey),
           let decoded = try? decoder.decode([WaterLogEntry].self, from: waterData) {
            // Filter only today's entries
            self.waterLog = decoded.filter { Calendar.current.isDateInToday($0.timestamp) }
        }
        
        // Load water goals
        if let goalsData = UserDefaults.standard.data(forKey: waterGoalsKey),
           let decoded = try? decoder.decode([WaterGoal].self, from: goalsData) {
            // Filter only today's goals
            self.waterGoals = decoded.filter { Calendar.current.isDateInToday($0.scheduledTime) }
        }
        
        // Load daily history
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? decoder.decode([DailySummary].self, from: historyData) {
            self.dailyHistory = decoded
        }
        
        // Setup auto-save
        setupAutoSave()
        
        // Check for daily reset periodically
        setupDailyResetCheck()
    }
    
    private func setupAutoSave() {
        $currentData
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] data in
                self?.saveData()
            }
            .store(in: &cancellables)
        
        $waterLog
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveWaterLog()
            }
            .store(in: &cancellables)
        
        $settings
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    private func setupDailyResetCheck() {
        // Check every minute if we've crossed into a new day
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForDailyReset()
        }
    }
    
    private func checkForDailyReset() {
        if !Calendar.current.isDateInToday(currentData.date) {
            DispatchQueue.main.async {
                self.performDailyReset()
            }
        }
    }
    
    private func performDailyReset() {
        // 1. Save yesterday's completed tasks to history
        let summary = DailySummary(from: currentData, waterGoal: settings.waterGoal)
        if currentData.tasks.count > 0 || currentData.waterIntake > 0 {
            dailyHistory.insert(summary, at: 0)
            // Keep only last 30 days
            if dailyHistory.count > 30 {
                dailyHistory = Array(dailyHistory.prefix(30))
            }
            saveHistory()
        }
        
        // 2. Carry over incomplete tasks
        let incompleteTasks = currentData.tasks.filter { !$0.isCompleted }.map { task -> TaskItem in
            var newTask = TaskItem(title: task.title, scheduledTime: nil)
            // Reset to no scheduled time for carried-over tasks
            return newTask
        }
        
        // 3. Create new day with carried-over tasks
        var newData = DailyData.newDay()
        newData.tasks = incompleteTasks
        currentData = newData
        
        // 4. Reset water data
        waterLog = []
        waterGoals = []
        
        // 5. Regenerate water schedule
        generateDailyWaterSchedule()
    }
    
    // MARK: - Save Methods
    private func saveData() {
        if let encoded = try? encoder.encode(currentData) {
            UserDefaults.standard.set(encoded, forKey: dataKey)
        }
    }
    
    private func saveWaterLog() {
        if let encoded = try? encoder.encode(waterLog) {
            UserDefaults.standard.set(encoded, forKey: waterLogKey)
        }
    }
    
    private func saveSettings() {
        if let encoded = try? encoder.encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func saveWaterGoals() {
        if let encoded = try? encoder.encode(waterGoals) {
            UserDefaults.standard.set(encoded, forKey: waterGoalsKey)
        }
    }
    
    private func saveHistory() {
        if let encoded = try? encoder.encode(dailyHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    // MARK: - Task Methods
    func addTask(title: String, scheduledTime: Date? = nil) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let task = TaskItem(title: title, scheduledTime: scheduledTime)
        currentData.tasks.append(task)
        
        // Schedule notification if time is set
        if let time = scheduledTime {
            NotificationManager.shared.scheduleTaskReminder(task: task, at: time)
        }
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = currentData.tasks.firstIndex(where: { $0.id == task.id }) {
            currentData.tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        currentData.tasks.removeAll { $0.id == task.id }
        NotificationManager.shared.cancelTaskReminder(taskId: task.id)
    }
    
    // MARK: - Water Methods
    func addWater(amount: Int = 250) {
        currentData.waterIntake += amount
        waterLog.append(WaterLogEntry(amount: amount))
    }
    
    // MARK: - Water Goals Methods
    func generateDailyWaterSchedule() {
        // Clear existing goals for today
        waterGoals.removeAll()
        
        let profile = ProfileManager.shared.profile
        let startHour = profile.workStartHour
        let endHour = profile.workEndHour
        let workHours = endHour - startHour
        
        // Science-based water intake schedule
        // Total = 2000ml distributed throughout the day
        var schedule: [(hour: Int, minute: Int, amount: Int, label: String)] = []
        
        // Early morning (before work or at start) - 300ml
        schedule.append((startHour, 0, 300, "Sáng sớm - hydrate sau giấc ngủ"))
        
        // Mid-morning - 300ml
        let midMorning = startHour + max(1, workHours / 4)
        schedule.append((midMorning, 30, 300, "Giữa buổi sáng"))
        
        // Before lunch (around noon) - 250ml
        let beforeLunch = min(12, startHour + workHours / 2)
        schedule.append((beforeLunch, 0, 250, "Trước bữa trưa"))
        
        // After lunch - 300ml
        schedule.append((13, 30, 300, "Sau bữa trưa - giúp tiêu hóa"))
        
        // Afternoon - 300ml
        let afternoon = 15
        if afternoon < endHour {
            schedule.append((afternoon, 0, 300, "Buổi chiều"))
        }
        
        // Late afternoon - 300ml
        let lateAfternoon = min(17, endHour - 1)
        if lateAfternoon > 15 && lateAfternoon < endHour {
            schedule.append((lateAfternoon, 0, 300, "Cuối buổi chiều"))
        }
        
        // Before dinner / end of work - 250ml (nhẹ hơn để không ảnh hưởng giấc ngủ)
        if endHour >= 18 {
            schedule.append((endHour, 0, 250, "Kết thúc ngày làm việc"))
        }
        
        // Create goals
        let today = Calendar.current.startOfDay(for: Date())
        for item in schedule {
            if let goalTime = Calendar.current.date(bySettingHour: item.hour, minute: item.minute, second: 0, of: today) {
                var goal = WaterGoal(amount: item.amount, scheduledTime: goalTime)
                // Check if already passed today
                if goalTime < Date() {
                    // Don't create goals for past times that user didn't complete
                }
                waterGoals.append(goal)
            }
        }
        
        waterGoals.sort { $0.scheduledTime < $1.scheduledTime }
        saveWaterGoals()
        
        // Schedule notifications
        NotificationManager.shared.scheduleWaterGoalNotifications(goals: waterGoals)
    }
    
    func toggleWaterGoal(_ goal: WaterGoal) {
        if let index = waterGoals.firstIndex(where: { $0.id == goal.id }) {
            waterGoals[index].isCompleted.toggle()
            // If completing, also add to water intake
            if waterGoals[index].isCompleted {
                addWater(amount: goal.amount)
                // Send encouragement notification
                NotificationManager.shared.sendTaskCompletionNotification(taskTitle: "\(goal.amount)ml nước")
            }
            saveWaterGoals()
        }
    }
    
    func deleteWaterGoal(_ goal: WaterGoal) {
        waterGoals.removeAll { $0.id == goal.id }
        saveWaterGoals()
    }
    
    func hasGeneratedScheduleToday() -> Bool {
        guard !waterGoals.isEmpty else { return false }
        return waterGoals.first.map { Calendar.current.isDateInToday($0.scheduledTime) } ?? false
    }
    
    // MARK: - Notes Methods
    func updateNotes(_ notes: String) {
        currentData.notes = notes
    }
}


