// SmartToneEngine.swift
// Context-aware notification tone system with 3-day rotation

import Foundation

// MARK: - Context Tone (Auto-detected based on situation)
enum ContextTone: String {
    case relaxed = "relaxed"     // Thời gian rảnh - chill, no pressure
    case work = "work"           // Công việc hàng ngày - focused, neutral
    case stressed = "stressed"   // Siêu căng thẳng - urgent, direct
}

// MARK: - Smart Tone Engine
class SmartToneEngine {
    static let shared = SmartToneEngine()
    
    private var profileManager: ProfileManager { ProfileManager.shared }
    private var dataManager: DataManager { DataManager.shared }
    private var workSession: WorkSessionManager { WorkSessionManager.shared }
    
    // MARK: - Day Index for Message Rotation (0, 1, 2)
    /// Returns 0, 1, or 2 based on day of year - ensures 3 consecutive days use different messages
    private var dayIndex: Int {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return dayOfYear % 3
    }
    
    /// Select message based on day index to avoid repetition
    private func selectMessage<T>(_ messages: [T]) -> T {
        guard !messages.isEmpty else { fatalError("Messages array cannot be empty") }
        return messages[dayIndex % messages.count]
    }
    
    // MARK: - Determine Current Context
    func getCurrentContext() -> ContextTone {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        let profile = profileManager.profile
        let isWeekend = weekday == 1 || weekday == 7
        let isWorkHours = hour >= profile.workStartHour && hour < profile.workEndHour
        
        // Check stress indicators
        let stressLevel = calculateStressLevel()
        
        // Siêu căng thẳng: high stress, overdue tasks, or user selected harsh mode
        if stressLevel >= 0.7 || profile.isHarshModeEnabled {
            return .stressed
        }
        
        // Thời gian rảnh: weekend, outside work hours, or low task load
        if isWeekend || !isWorkHours || stressLevel < 0.3 {
            return .relaxed
        }
        
        // Default: Công việc hàng ngày
        return .work
    }
    
    // MARK: - Stress Level Calculation (0.0 - 1.0)
    private func calculateStressLevel() -> Double {
        let tasks = dataManager.currentData.tasks
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let overdueTasks = countOverdueTasks()
        
        guard totalTasks > 0 else { return 0.0 }
        
        var stress: Double = 0.0
        
        // Many incomplete tasks
        let incompleteRatio = 1.0 - (Double(completedTasks) / Double(totalTasks))
        stress += incompleteRatio * 0.3
        
        // Overdue tasks (heavily weighted)
        if overdueTasks > 0 {
            stress += min(Double(overdueTasks) * 0.2, 0.4)
        }
        
        // Task overload (> 5 incomplete tasks)
        let incompleteTasks = totalTasks - completedTasks
        if incompleteTasks > 5 {
            stress += 0.2
        }
        
        // Late in work day with many tasks left
        let hour = Calendar.current.component(.hour, from: Date())
        let endHour = profileManager.profile.workEndHour
        if hour >= endHour - 2 && incompleteTasks > 2 {
            stress += 0.1
        }
        
        return min(stress, 1.0)
    }
    
    private func countOverdueTasks() -> Int {
        let now = Date()
        return dataManager.currentData.tasks.filter { task in
            guard !task.isCompleted, let scheduledTime = task.scheduledTime else { return false }
            return scheduledTime < now
        }.count
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 💧 WATER MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getWaterMessage(suggestedAmount: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        let current = dataManager.currentData.waterIntake
        let goal = dataManager.settings.waterGoal
        let remaining = max(0, goal - current)
        let name = profileManager.profile.displayName
        
        switch context {
        case .relaxed:
            return getRelaxedWaterMessage(amount: suggestedAmount, name: name)
        case .work:
            return getWorkWaterMessage(amount: suggestedAmount, remaining: remaining)
        case .stressed:
            return getStressedWaterMessage(amount: suggestedAmount, remaining: remaining)
        }
    }
    
    private func getRelaxedWaterMessage(amount: Int, name: String) -> (String, String) {
        let messages: [(String, String)] = [
            ("💧 Nhẹ nhàng thôi", "Uống chút nước cho dễ chịu hơn nè \(name)."),
            ("💧 Gợi ý nhỏ", "Rảnh tay thì nhấp \(amount)ml nước nhé~"),
            ("💧 Thư giãn", "Bổ sung nước khi tiện, không vội đâu 😊")
        ]
        return selectMessage(messages)
    }
    
    private func getWorkWaterMessage(amount: Int, remaining: Int) -> (String, String) {
        let messages: [(String, String)] = [
            ("💧 Uống nước", "Uống \(amount)ml. Còn \(remaining)ml để đạt mục tiêu."),
            ("💧 Nhắc nước", "\(amount)ml nước. Target còn \(remaining)ml."),
            ("💧 Hydrate", "Bổ sung \(amount)ml. Tiến độ: \(remaining)ml còn lại.")
        ]
        return selectMessage(messages)
    }
    
    private func getStressedWaterMessage(amount: Int, remaining: Int) -> (String, String) {
        let messages: [(String, String)] = [
            ("💧 Uống nước đi", "Não khô rồi. Uống \(amount)ml ngay."),
            ("💧 Ê!", "Uống nước. Không negotiate. \(remaining)ml còn lại."),
            ("💧 Nhắc thẳng", "Bỏ qua mấy lần rồi. \(amount)ml. NGAY.")
        ]
        return selectMessage(messages)
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - ⏰ OVERDUE WATER MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getOverdueWaterMessage(amount: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("💧 Nhắc lại nè", "Bạn quên uống \(amount)ml nước rồi kìa 😊"),
                ("💧 Ơi ơi~", "10 phút rồi đó, uống \(amount)ml nước đi nào."),
                ("💧 Qua giờ rồi", "Không vội, nhưng \(amount)ml nước đang chờ~")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("⏰ Quá giờ", "Đã 10 phút. Uống \(amount)ml nước ngay nhé."),
                ("⏰ Trễ 10 phút", "\(amount)ml nước vẫn chưa uống. Check lại."),
                ("⏰ Nhắc lại", "10 phút trước đã nhắc. \(amount)ml. Uống đi.")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("⚠️ Chậm rồi!", "10 phút trước đã nhắc. Uống \(amount)ml ngay!"),
                ("💀 Ignoring?", "Lờ đi à? Uống nước không thì đừng than đau đầu."),
                ("🔥 Ê!", "\(amount)ml nước. NOW. Não cần nước để hoạt động.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 📋 TASK REMINDER MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getTaskReminderMessage(taskTitle: String) -> (title: String, body: String) {
        let context = getCurrentContext()
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("📋 Nhắc nhẹ", "Rảnh tay rồi đó, làm \"\(taskTitle)\" cũng được."),
                ("📋 Gợi ý", "Nếu muốn, mình xử lý \"\(taskTitle)\" nhé."),
                ("📋 Khi nào tiện", "Việc \"\(taskTitle)\" đang chờ, không gấp đâu.")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("📋 Nhắc việc", "Đến giờ: \(taskTitle)"),
                ("📋 Task", "\"\(taskTitle)\" - Đến lúc làm rồi."),
                ("📋 Reminder", "Lịch: \(taskTitle). Bắt đầu nhé.")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("📋 Việc này!", "Ê, \"\(taskTitle)\" - để nữa là toang đó."),
                ("📋 Làm ngay", "\"\(taskTitle)\" - Né hoài không giải quyết được."),
                ("📋 Không đùa", "\"\(taskTitle)\". Làm. Xong. Ngay.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - ⚠️ OVERDUE TASK MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getOverdueTaskMessage(taskTitle: String, minutesOverdue: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("⏰ Nhắc việc", "\"\(taskTitle)\" đã đến giờ (\(minutesOverdue)p trước)"),
                ("📋 Quên chưa", "\(minutesOverdue) phút rồi đó, \"\(taskTitle)\" nhé~"),
                ("💭 À này", "Việc \"\(taskTitle)\" bắt đầu từ \(minutesOverdue)p trước.")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("⏰ Quá giờ", "\"\(taskTitle)\" trễ \(minutesOverdue) phút."),
                ("⏰ Overdue", "Task \"\(taskTitle)\" - \(minutesOverdue)p late."),
                ("⏰ Nhắc lại", "\(minutesOverdue) phút. \"\(taskTitle)\" chưa xong.")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("⚠️ Quá hạn!", "\"\(taskTitle)\" đã trễ \(minutesOverdue) phút. Xử lý ngay!"),
                ("⚠️ Ê!", "Việc này mà để nữa là toang: \(taskTitle)"),
                ("⚠️ \(minutesOverdue)p rồi", "\"\(taskTitle)\" chờ bao lâu nữa? Làm đi.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - ☀️ WORK START MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getWorkStartMessage() -> (title: String, body: String) {
        let context = getCurrentContext()
        let name = profileManager.profile.displayName
        let tasks = dataManager.currentData.tasks.filter { !$0.isCompleted }.count
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("☀️ Chào buổi sáng", "\(name) ơi, sẵn sàng bắt đầu chưa?"),
                ("🌅 Ngày mới đến rồi", "Hôm nay mình làm gì nhỉ, \(name)?"),
                ("😊 Bắt đầu thôi", "Không vội đâu, từ từ thôi \(name)~")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("⏰ Bắt đầu làm việc", "Có \(tasks) việc cần làm hôm nay."),
                ("📋 Work time", "\(tasks) tasks scheduled. Bắt đầu."),
                ("🗓 Good morning", "Ready for \(tasks) tasks today.")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("🔥 Làm việc đi!", "Có \(tasks) việc. Bắt đầu ngay!"),
                ("⚡ Dậy chưa?", "Đã đến giờ. \(tasks) việc đang chờ."),
                ("🎯 Tập trung", "Không lười được đâu. Có \(tasks) việc.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 🌙 WORK END MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getWorkEndMessage() -> (title: String, body: String) {
        let context = getCurrentContext()
        let name = profileManager.profile.displayName
        let tasks = dataManager.currentData.tasks
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        let incomplete = total - completed
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("🌙 Hết giờ rồi", "Nghỉ ngơi đi \(name), mai làm tiếp."),
                ("✨ Kết thúc ngày", "Chill thôi, không vội đâu~"),
                ("🌿 Thư giãn nào", "Off máy, nghỉ ngơi \(name)!")
            ]
            return selectMessage(messages)
            
        case .work:
            if incomplete == 0 {
                let messages: [(String, String)] = [
                    ("✅ Xong việc", "Hoàn thành \(completed)/\(total) ✓ Nghỉ thôi."),
                    ("✅ Done for today", "All \(total) tasks completed. Good job."),
                    ("✅ 100%", "\(completed)/\(total) xong. Hết giờ làm việc.")
                ]
                return selectMessage(messages)
            } else {
                let messages: [(String, String)] = [
                    ("⏰ Hết giờ", "Còn \(incomplete) việc. Mai giải quyết."),
                    ("🌙 End of day", "\(incomplete) tasks remaining. Continue tomorrow."),
                    ("📋 Wrap up", "Còn \(incomplete)/\(total). Save progress, nghỉ thôi.")
                ]
                return selectMessage(messages)
            }
            
        case .stressed:
            if incomplete > 0 {
                let messages: [(String, String)] = [
                    ("⚠️ Hết giờ rồi đó", "Còn \(incomplete) việc. Nghĩ cách xử lý đi."),
                    ("🔥 Dừng lại", "Về nghỉ. Nhưng mai phải xử lý \(incomplete) việc."),
                    ("😤 Thôi được rồi", "Cố nữa cũng không xong. Mai tính.")
                ]
                return selectMessage(messages)
            } else {
                let messages: [(String, String)] = [
                    ("💪 Xong hết!", "Làm tốt lắm. Về nghỉ đi."),
                    ("🎉 DONE!", "Cuối cùng cũng xong. Thở đi."),
                    ("✅ Mission complete", "All tasks done. You earned this rest.")
                ]
                return selectMessage(messages)
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 📅 DAILY ROUTINE MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getDailyRoutineMessage(routineCount: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        let name = profileManager.profile.displayName
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("📅 Lịch hàng ngày", "Có \(routineCount) routine, áp dụng không \(name)?"),
                ("🌅 Sáng rồi", "Muốn thêm \(routineCount) routine vào task list?"),
                ("😊 Nhắc nhẹ", "\(routineCount) việc thường ngày đang chờ~")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("📋 Daily Routines", "Áp dụng \(routineCount) routine vào task list?"),
                ("📅 Routines", "\(routineCount) daily tasks ready to apply."),
                ("🔄 Daily setup", "Add \(routineCount) routines to today's list?")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("🔥 Routines đây!", "\(routineCount) việc. Apply ngay không để quên."),
                ("📋 Đừng quên", "Routines cần làm: \(routineCount). Áp dụng đi."),
                ("⚡ Ngay bây giờ", "Thêm \(routineCount) routine. Đừng để trễ.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - ✅ TASK COMPLETION MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getTaskCompletionMessage(taskTitle: String, remainingCount: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        let name = profileManager.profile.displayName
        
        switch context {
        case .relaxed:
            if remainingCount == 0 {
                let messages: [(String, String)] = [
                    ("🎉 Xong hết!", "Tuyệt vời \(name), nghỉ ngơi thôi nào~"),
                    ("✨ All done!", "Hết việc rồi! Relax time~"),
                    ("🌿 Hoàn thành", "Xong tất cả. Thư giãn đi \(name)!")
                ]
                return selectMessage(messages)
            } else {
                let messages: [(String, String)] = [
                    ("✅ Tốt lắm!", "Xong \"\(taskTitle)\". Còn \(remainingCount) việc thôi."),
                    ("👍 Nice!", "Làm tốt đó \(name)! Từ từ làm tiếp~"),
                    ("😊 Được rồi", "\"\(taskTitle)\" xong. Thư thả nhé.")
                ]
                return selectMessage(messages)
            }
            
        case .work:
            if remainingCount == 0 {
                let messages: [(String, String)] = [
                    ("✅ Hoàn thành", "Xong tất cả tasks hôm nay."),
                    ("✅ 100%", "All tasks completed."),
                    ("✅ Done", "Task list cleared. Great work.")
                ]
                return selectMessage(messages)
            } else {
                let messages: [(String, String)] = [
                    ("✅ Xong", "\"\(taskTitle)\" ✓ Còn \(remainingCount) việc."),
                    ("✅ Done", "1 task done. \(remainingCount) remaining."),
                    ("✅ +1", "\"\(taskTitle)\" completed. \(remainingCount) to go.")
                ]
                return selectMessage(messages)
            }
            
        case .stressed:
            if remainingCount == 0 {
                let messages: [(String, String)] = [
                    ("💪 XONG HẾT!", "Cuối cùng cũng xong. Thở đi."),
                    ("🔥 FINALLY!", "Done. Không còn gì nữa. NGHỈ."),
                    ("⚡ Xong rồi", "All tasks cleared. You made it.")
                ]
                return selectMessage(messages)
            } else {
                let messages: [(String, String)] = [
                    ("✅ Được 1!", "Xong \"\(taskTitle)\". Còn \(remainingCount). Tiếp!"),
                    ("⚡ Tiếp đi!", "\(remainingCount) việc nữa. Đừng dừng."),
                    ("🔥 Đừng nghỉ", "Xong 1 rồi. Còn \(remainingCount). Làm luôn.")
                ]
                return selectMessage(messages)
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - ⏸ BREAK REMINDER MESSAGES (3 per tone = 9 total)
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getBreakReminderMessage(hoursWorked: Int) -> (title: String, body: String) {
        let context = getCurrentContext()
        let name = profileManager.profile.displayName
        
        switch context {
        case .relaxed:
            let messages: [(String, String)] = [
                ("☕ Nghỉ chút đi", "\(name) ơi, làm \(hoursWorked) tiếng rồi đó."),
                ("🌿 Thư giãn nào", "Dậy đi lại, nhìn ra ngoài cửa sổ~"),
                ("😌 Relax", "\(hoursWorked) tiếng rồi, uống nước nghỉ ngơi.")
            ]
            return selectMessage(messages)
            
        case .work:
            let messages: [(String, String)] = [
                ("⏸ Nghỉ giải lao", "Đã làm \(hoursWorked) tiếng. Nghỉ 5-10 phút."),
                ("⏸ Break time", "\(hoursWorked)h worked. Take 5 minutes."),
                ("⏸ Stretch", "\(hoursWorked) hours in. Quick break recommended.")
            ]
            return selectMessage(messages)
            
        case .stressed:
            let messages: [(String, String)] = [
                ("🔥 NGHỈ ĐI!", "\(hoursWorked) tiếng rồi. Não cần nghỉ, dù bạn không muốn."),
                ("⚠️ Dừng lại", "Làm liên tục không hiệu quả. Nghỉ 5 phút."),
                ("💀 Seriously", "\(hoursWorked) tiếng không nghỉ? Dậy đi lại ngay.")
            ]
            return selectMessage(messages)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 💬 ENCOURAGEMENT MESSAGES
    // ═══════════════════════════════════════════════════════════════════════════
    
    func getEncouragementMessage() -> String? {
        let context = getCurrentContext()
        let tasks = dataManager.currentData.tasks
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        
        guard total > 0 else { return nil }
        
        let progress = Double(completed) / Double(total)
        
        switch context {
        case .relaxed:
            if progress >= 1 {
                let messages = ["Xong hết rồi! Nghỉ ngơi đi nào 🌿", "All done! Relax time~", "Hoàn thành! Thư giãn thôi 😊"]
                return selectMessage(messages)
            } else if progress >= 0.5 {
                let messages = ["Được nửa rồi, thư thả thôi~", "Halfway there! No rush~", "50%+ done. Chill 😎"]
                return selectMessage(messages)
            }
            return nil
            
        case .work:
            if progress >= 1 {
                let messages = ["Hoàn thành \(completed)/\(total) ✓", "All tasks done ✓", "\(completed)/\(total) completed"]
                return selectMessage(messages)
            }
            return nil
            
        case .stressed:
            if progress >= 1 {
                let messages = ["XONG! Đừng tự gây stress nữa nhé.", "DONE. Breathe.", "Finally. All cleared."]
                return selectMessage(messages)
            } else if completed > 0 {
                let messages = ["Được \(completed) rồi. Tiếp!", "\(completed) done. Keep going.", "\(completed)/\(total). Don't stop."]
                return selectMessage(messages)
            }
            return nil
        }
    }
}
