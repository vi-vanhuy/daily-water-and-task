// NotificationManager.swift
// Handles macOS native notifications with smart water reminders

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        checkAuthorization()
        setupNotificationCategories()
    }
    
    func checkAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.scheduleSmartWaterReminders()
                }
            }
            
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Smart Water Reminders
    func scheduleSmartWaterReminders() {
        // Cancel existing water reminders
        center.removePendingNotificationRequests(withIdentifiers: waterReminderIds())
        
        guard isAuthorized else { return }
        
        let profile = ProfileManager.shared.profile
        let dataManager = DataManager.shared
        let startHour = profile.workStartHour
        let endHour = profile.workEndHour
        
        // Calculate water schedule based on goal and work hours
        let waterGoal = dataManager.settings.waterGoal // e.g., 2000ml
        let workHours = endHour - startHour
        guard workHours > 0 else { return }
        
        // Smart schedule: remind every 1-1.5 hours with appropriate amounts
        let reminderIntervalHours = 1.5
        var currentHour = Double(startHour)
        
        while currentHour < Double(endHour) {
            let hour = Int(currentHour)
            let minute = Int((currentHour - Double(hour)) * 60)
            
            // Calculate suggested amount based on time of day
            let suggestedAmount = calculateSuggestedWaterAmount(
                hour: hour,
                workStartHour: startHour,
                workEndHour: endHour,
                totalGoal: waterGoal
            )
            
            scheduleSmartWaterReminder(hour: hour, minute: minute, suggestedAmount: suggestedAmount)
            currentHour += reminderIntervalHours
        }
    }
    
    private func calculateSuggestedWaterAmount(hour: Int, workStartHour: Int, workEndHour: Int, totalGoal: Int) -> Int {
        // Morning (first 2 hours): Larger amounts to hydrate
        // Midday: Regular amounts
        // Afternoon: Moderate amounts
        // Evening: Smaller amounts
        
        let morningEnd = workStartHour + 2
        let middayEnd = 13
        let afternoonEnd = workEndHour - 1
        
        if hour < morningEnd {
            // Morning: 300-350ml (hydrate after sleep)
            return 300
        } else if hour < middayEnd {
            // Midday: 250ml
            return 250
        } else if hour < afternoonEnd {
            // Afternoon: 250ml
            return 250
        } else {
            // Late afternoon/evening: 200ml (smaller before end of day)
            return 200
        }
    }
    
    private func scheduleSmartWaterReminder(hour: Int, minute: Int, suggestedAmount: Int) {
        let content = UNMutableNotificationContent()
        
        // Vietnamese messages based on time
        let (title, body) = getWaterMessage(hour: hour, suggestedAmount: suggestedAmount)
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"
        content.userInfo = ["suggestedAmount": suggestedAmount]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let id = "water_\(hour)_\(minute)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule water reminder: \(error.localizedDescription)")
            }
        }
    }
    
    private func getWaterMessage(hour: Int, suggestedAmount: Int) -> (title: String, body: String) {
        // Use SmartToneEngine for context-aware messages
        return SmartToneEngine.shared.getWaterMessage(suggestedAmount: suggestedAmount)
    }
    
    private func getCalmWaterMessage(hour: Int, amount: Int) -> (String, String) {
        switch hour {
        case 6..<10:
            return ("Uống nước", "Bắt đầu ngày mới với \(amount)ml nước.")
        case 10..<12:
            return ("Nghỉ ngơi", "Uống \(amount)ml nước, thư giãn một chút.")
        case 12..<14:
            return ("Giờ trưa", "\(amount)ml nước trước bữa ăn.")
        case 14..<17:
            return ("Buổi chiều", "Nhấp một ngụm, \(amount)ml.")
        default:
            return ("Cuối ngày", "\(amount)ml nước cuối cùng.")
        }
    }
    
    private func getFocusWaterMessage(hour: Int, amount: Int) -> (String, String) {
        let current = DataManager.shared.currentData.waterIntake
        let goal = DataManager.shared.settings.waterGoal
        let remaining = max(0, goal - current)
        
        return ("Uống nước", "Uống \(amount)ml. Còn \(remaining)ml để đạt mục tiêu.")
    }
    
    private func getFriendlyWaterMessage(hour: Int, amount: Int, name: String) -> (String, String) {
        let current = DataManager.shared.currentData.waterIntake
        let goal = DataManager.shared.settings.waterGoal
        let progress = Double(current) / Double(goal)
        
        switch hour {
        case 6..<10:
            return ("Chào buổi sáng!", "Nạp \(amount)ml nước đi \(name)! Khởi động ngày mới ")
        case 10..<12:
            if progress < 0.3 {
                return ("Nhắc nhẹ nè!", "\(name) ơi, uống \(amount)ml đi, còn ít lắm ")
            } else {
                return ("Giỏi lắm!", "Tiếp tục uống \(amount)ml nha \(name)! ")
            }
        case 12..<14:
            return (" Giờ nghỉ trưa", "Uống \(amount)ml trước/sau bữa ăn nha!")
        case 14..<17:
            if progress >= 0.7 {
                return ("Sắp đủ rồi!", "Chỉ còn một chút nữa thôi \(name)! ")
            } else {
                return ("Chiều rồi!", "\(name) ơi, \(amount)ml nè!")
            }
        default:
            if progress >= 1 {
                return (" Tuyệt vời!", "\(name) đã uống đủ nước hôm nay! ")
            } else {
                return ("Cuối ngày", "Uống nốt \(amount)ml trước khi về \(name)!")
            }
        }
    }
    
    private func waterReminderIds() -> [String] {
        var ids: [String] = []
        for hour in 0..<24 {
            for minute in stride(from: 0, to: 60, by: 15) {
                ids.append("water_\(hour)_\(minute)")
            }
        }
        ids.append("water_snooze")
        return ids
    }
    
    // MARK: - Immediate Water Reminder (for testing)
    func sendImmediateWaterReminder() {
        guard isAuthorized else { return }
        
        // Update theme to match current context
        DispatchQueue.main.async {
            ThemeManager.shared.updateTheme()
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let suggestedAmount = calculateSuggestedWaterAmount(
            hour: hour,
            workStartHour: ProfileManager.shared.profile.workStartHour,
            workEndHour: ProfileManager.shared.profile.workEndHour,
            totalGoal: DataManager.shared.settings.waterGoal
        )
        
        let (title, body) = getWaterMessage(hour: hour, suggestedAmount: suggestedAmount)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "water_immediate", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    // MARK: - Task Reminders
    func scheduleTaskReminder(task: TaskItem, at date: Date) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Nhắc việc"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "task_\(task.id.uuidString)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule task reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelTaskReminder(taskId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: ["task_\(taskId.uuidString)"])
    }
    
    // MARK: - Water Goal Notifications
    func scheduleWaterGoalNotifications(goals: [WaterGoal]) {
        // Cancel existing water goal notifications
        let existingIds = goals.map { "water_goal_\($0.id.uuidString)" } + 
                         goals.map { "water_goal_overdue_\($0.id.uuidString)" }
        center.removePendingNotificationRequests(withIdentifiers: existingIds)
        
        guard isAuthorized else { return }
        
        let now = Date()
        
        for goal in goals {
            guard !goal.isCompleted else { continue }
            guard goal.scheduledTime > now else { continue }
            
            // Main notification at scheduled time
            let (title, body) = SmartToneEngine.shared.getWaterMessage(suggestedAmount: goal.amount)
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            content.userInfo = ["goalId": goal.id.uuidString, "amount": goal.amount]
            
            let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: goal.scheduledTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "water_goal_\(goal.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
            
            // Overdue notification 10 minutes after
            if let overdueTime = Calendar.current.date(byAdding: .minute, value: 10, to: goal.scheduledTime),
               overdueTime > now {
                let overdueContent = UNMutableNotificationContent()
                let (overdueTitle, overdueBody) = SmartToneEngine.shared.getOverdueWaterMessage(amount: goal.amount)
                overdueContent.title = overdueTitle
                overdueContent.body = overdueBody
                overdueContent.sound = .default
                overdueContent.categoryIdentifier = "WATER_REMINDER"
                
                let overdueTriggerDate = Calendar.current.dateComponents([.hour, .minute], from: overdueTime)
                let overdueTrigger = UNCalendarNotificationTrigger(dateMatching: overdueTriggerDate, repeats: false)
                
                let overdueRequest = UNNotificationRequest(
                    identifier: "water_goal_overdue_\(goal.id.uuidString)",
                    content: overdueContent,
                    trigger: overdueTrigger
                )
                center.add(overdueRequest)
            }
        }
    }
    
    // MARK: - Work Start/End Reminders
    func scheduleWorkHoursReminders() {
        // Cancel existing
        center.removePendingNotificationRequests(withIdentifiers: ["work_start", "work_end"])
        
        guard isAuthorized else { return }
        
        let profile = ProfileManager.shared.profile
        
        // Work Start Reminder
        var startComponents = DateComponents()
        startComponents.hour = profile.workStartHour
        startComponents.minute = 0
        
        let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: true)
        let (startTitle, startBody) = SmartToneEngine.shared.getWorkStartMessage()
        
        let startContent = UNMutableNotificationContent()
        startContent.title = startTitle
        startContent.body = startBody
        startContent.sound = .default
        
        let startRequest = UNNotificationRequest(identifier: "work_start", content: startContent, trigger: startTrigger)
        center.add(startRequest)
        
        // Work End Reminder
        var endComponents = DateComponents()
        endComponents.hour = profile.workEndHour
        endComponents.minute = 0
        
        let endTrigger = UNCalendarNotificationTrigger(dateMatching: endComponents, repeats: true)
        let (endTitle, endBody) = SmartToneEngine.shared.getWorkEndMessage()
        
        let endContent = UNMutableNotificationContent()
        endContent.title = endTitle
        endContent.body = endBody
        endContent.sound = .default
        
        let endRequest = UNNotificationRequest(identifier: "work_end", content: endContent, trigger: endTrigger)
        center.add(endRequest)
    }
    
    // MARK: - Daily Routine Reminder
    func scheduleDailyRoutineReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_routine"])
        
        guard isAuthorized else { return }
        
        let routineCount = WorkSessionManager.shared.dailyRoutines.count
        guard routineCount > 0 else { return }
        
        let profile = ProfileManager.shared.profile
        
        // Remind 15 minutes after work start
        var components = DateComponents()
        components.hour = profile.workStartHour
        components.minute = 15
        
        let (title, body) = SmartToneEngine.shared.getDailyRoutineMessage(routineCount: routineCount)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ROUTINE_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_routine", content: content, trigger: trigger)
        center.add(request)
    }
    
    // MARK: - Task Completion Notification
    func sendTaskCompletionNotification(taskTitle: String) {
        guard isAuthorized else { return }
        
        let remainingCount = DataManager.shared.currentData.tasks.filter { !$0.isCompleted }.count
        let (title, body) = SmartToneEngine.shared.getTaskCompletionMessage(taskTitle: taskTitle, remainingCount: remainingCount)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "task_complete_\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request)
    }
    
    // MARK: - Break Reminder
    func scheduleBreakReminders() {
        // Cancel existing break reminders
        center.removePendingNotificationRequests(withIdentifiers: ["break_1", "break_2", "break_3"])
        
        guard isAuthorized else { return }
        
        let profile = ProfileManager.shared.profile
        let startHour = profile.workStartHour
        
        // Schedule breaks every 2 hours
        let breakHours = [startHour + 2, startHour + 4, startHour + 6]
        
        for (index, hour) in breakHours.enumerated() {
            if hour < profile.workEndHour {
                var components = DateComponents()
                components.hour = hour
                components.minute = 0
                
                let hoursWorked = index + 1 * 2
                let (title, body) = SmartToneEngine.shared.getBreakReminderMessage(hoursWorked: hoursWorked)
                
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "break_\(index + 1)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
    
    // MARK: - Overdue Task Check & Notification
    func checkAndNotifyOverdueTasks() {
        guard isAuthorized else { return }
        
        let now = Date()
        let overdueTasks = DataManager.shared.currentData.tasks.filter { task in
            guard !task.isCompleted, let scheduledTime = task.scheduledTime else { return false }
            return scheduledTime < now
        }
        
        for task in overdueTasks {
            guard let scheduledTime = task.scheduledTime else { continue }
            let minutesOverdue = Int(now.timeIntervalSince(scheduledTime) / 60)
            
            // Only notify if overdue by at least 5 minutes and not already notified recently
            if minutesOverdue >= 5 {
                let (title, body) = SmartToneEngine.shared.getOverdueTaskMessage(taskTitle: task.title, minutesOverdue: minutesOverdue)
                
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                content.categoryIdentifier = "TASK_REMINDER"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "overdue_\(task.id.uuidString)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
    
    // MARK: - Schedule All Notifications (Call on app launch)
    func scheduleAllNotifications() {
        scheduleSmartWaterReminders()
        scheduleWorkHoursReminders()
        scheduleDailyRoutineReminder()
        scheduleBreakReminders()
    }
    
    // MARK: - Snooze
    func snoozeWaterReminder(minutes: Int = 10) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Nhắc lại"
        content.body = "Đã snooze xong, uống nước đi nào!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "water_snooze", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule snooze: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Setup Categories
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Nhắc sau 10 phút",
            options: []
        )
        
        let drinkAction = UNNotificationAction(
            identifier: "DRINK",
            title: "Đã uống",
            options: []
        )
        
        let waterCategory = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [drinkAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([waterCategory, taskCategory])
    }
}
