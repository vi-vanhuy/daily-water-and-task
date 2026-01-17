// WorkSession.swift
// Work session timer and daily routine management

import Foundation
import Combine

// MARK: - Work Session Manager
class WorkSessionManager: ObservableObject {
    static let shared = WorkSessionManager()
    
    @Published var isWorking: Bool = false
    @Published var sessionStartTime: Date?
    @Published var remainingTime: TimeInterval = 0
    @Published var dailyRoutines: [DailyRoutine] = []
    
    private var timer: Timer?
    private let routinesKey = "dailyRoutines"
    private let sessionKey = "workSession"
    
    var profileManager: ProfileManager { ProfileManager.shared }
    
    /// Check if current time is within work hours
    var isWorkHours: Bool {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let startHour = profileManager.profile.workStartHour
        let endHour = profileManager.profile.workEndHour
        return hour >= startHour && hour < endHour
    }
    
    init() {
        loadRoutines()
        loadSession()
        startTimer()
        checkWorkHours()
    }
    
    /// Check current time and auto-start/stop work session
    func checkWorkHours() {
        if isWorkHours && !isWorking {
            // Auto-start if within work hours
            startWorkSession()
        } else if !isWorkHours && isWorking {
            // Auto-end if outside work hours
            endWorkSession()
        }
        
        // Update remaining time if working
        if isWorking {
            updateRemainingTime()
        }
    }
    
    // MARK: - Work Session
    func startWorkSession() {
        isWorking = true
        sessionStartTime = Date()
        saveSession()
        updateRemainingTime()
    }
    
    func endWorkSession() {
        isWorking = false
        sessionStartTime = nil
        remainingTime = 0
        saveSession()
    }
    
    private func updateRemainingTime() {
        let endHour = profileManager.profile.workEndHour
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = endHour
        components.minute = 0
        
        if let endTime = Calendar.current.date(from: components) {
            let remaining = endTime.timeIntervalSince(Date())
            remainingTime = max(0, remaining)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.isWorking else { return }
            self.updateRemainingTime()
            
            // Auto-end if past work end time
            if self.remainingTime <= 0 {
                self.endWorkSession()
            }
        }
    }
    
    var formattedRemainingTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var workProgressPercent: Double {
        let startHour = profileManager.profile.workStartHour
        let endHour = profileManager.profile.workEndHour
        let totalWorkMinutes = (endHour - startHour) * 60
        
        guard totalWorkMinutes > 0 else { return 0 }
        
        let now = Date()
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = startHour
        startComponents.minute = 0
        
        guard let workStart = calendar.date(from: startComponents) else { return 0 }
        
        let elapsedMinutes = now.timeIntervalSince(workStart) / 60
        return min(1, max(0, elapsedMinutes / Double(totalWorkMinutes)))
    }
    
    // MARK: - Session Persistence
    private func saveSession() {
        let data: [String: Any] = [
            "isWorking": isWorking,
            "startTime": sessionStartTime?.timeIntervalSince1970 ?? 0
        ]
        UserDefaults.standard.set(data, forKey: sessionKey)
    }
    
    private func loadSession() {
        guard let data = UserDefaults.standard.dictionary(forKey: sessionKey) else { return }
        
        if let working = data["isWorking"] as? Bool {
            isWorking = working
        }
        
        if let startInterval = data["startTime"] as? TimeInterval, startInterval > 0 {
            let startDate = Date(timeIntervalSince1970: startInterval)
            // Only restore if same day
            if Calendar.current.isDateInToday(startDate) {
                sessionStartTime = startDate
                if isWorking {
                    updateRemainingTime()
                }
            } else {
                // Reset for new day
                isWorking = false
                sessionStartTime = nil
            }
        }
    }
    
    // MARK: - Daily Routines
    func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: routinesKey),
           let decoded = try? JSONDecoder().decode([DailyRoutine].self, from: data) {
            dailyRoutines = decoded
        }
    }
    
    func saveRoutines() {
        if let encoded = try? JSONEncoder().encode(dailyRoutines) {
            UserDefaults.standard.set(encoded, forKey: routinesKey)
        }
    }
    
    func addRoutine(title: String, hour: Int, minute: Int) {
        let routine = DailyRoutine(title: title, hour: hour, minute: minute)
        dailyRoutines.append(routine)
        dailyRoutines.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
        saveRoutines()
    }
    
    func removeRoutine(_ routine: DailyRoutine) {
        dailyRoutines.removeAll { $0.id == routine.id }
        saveRoutines()
    }
    
    func applyRoutinesToToday() {
        let dataManager = DataManager.shared
        
        for routine in dailyRoutines {
            // Check if task already exists
            let exists = dataManager.currentData.tasks.contains { $0.title == routine.title }
            if !exists {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = routine.hour
                components.minute = routine.minute
                
                if let scheduledTime = Calendar.current.date(from: components) {
                    dataManager.addTask(title: routine.title, scheduledTime: scheduledTime)
                }
            }
        }
    }
}

// MARK: - Daily Routine Model
struct DailyRoutine: Codable, Identifiable {
    let id: UUID
    var title: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    
    init(title: String, hour: Int, minute: Int, isEnabled: Bool = true) {
        self.id = UUID()
        self.title = title
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }
    
    var formattedTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}
