// UserProfile.swift
// User profile and personalization settings

import Foundation

// MARK: - User Profile
struct UserProfile: Codable {
    var nickname: String = ""
    var workStartHour: Int = 9
    var workEndHour: Int = 18
    var tone: AppTone = .focus
    var hasCompletedOnboarding: Bool = false
    
    var displayName: String {
        nickname.isEmpty ? "bạn" : nickname
    }
    
    // If user selects "Đừng đụng" tone, always use harsh mode
    var isHarshModeEnabled: Bool {
        tone == .friendly  // friendly = "Đừng đụng vào tao"
    }
}

// MARK: - App Tone
enum AppTone: String, Codable, CaseIterable {
    case calm = "calm"        // Vui vẻ (relaxed/happy)
    case focus = "focus"      // Công việc (work)
    case friendly = "friendly" // Đừng đụng vào tao (harsh)
    
    var displayName: String {
        switch self {
        case .calm: return "Vui vẻ"
        case .focus: return "Công việc"
        case .friendly: return "Đừng đụng vào tao"
        }
    }
    
    var icon: String {
        switch self {
        case .calm: return "😊"
        case .focus: return "💼"
        case .friendly: return "🔥"
        }
    }
    
    var description: String {
        switch self {
        case .calm: return "Thư giãn, vui vẻ"
        case .focus: return "Ngắn gọn, rõ ràng"
        case .friendly: return "Thẳng thắn, không nể nang"
        }
    }
}

// MARK: - Profile Manager
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profile: UserProfile {
        didSet { saveProfile() }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey) }
    }
    
    private let profileKey = "userProfile"
    private let onboardingKey = "hasCompletedOnboarding"
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    // MARK: - Greeting Messages
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile.displayName
        
        switch profile.tone {
        case .calm:
            return getCalmGreeting(hour: hour, name: name)
        case .focus:
            return getFocusGreeting(hour: hour, name: name)
        case .friendly:
            return getFriendlyGreeting(hour: hour, name: name)
        }
    }
    
    private func getCalmGreeting(hour: Int, name: String) -> String {
        switch hour {
        case 5..<12:
            return "Chào \(name), một ngày mới bắt đầu."
        case 12..<14:
            return "Nghỉ ngơi một chút, \(name)."
        case 14..<18:
            return "Tiếp tục nhẹ nhàng, \(name)."
        case 18..<22:
            return "Buông bỏ công việc, \(name)."
        default:
            return "Thư giãn đi, \(name)."
        }
    }
    
    private func getFocusGreeting(hour: Int, name: String) -> String {
        switch hour {
        case 5..<12:
            return "Sáng tốt lành, \(name). Bắt đầu thôi."
        case 12..<14:
            return "Nghỉ trưa. Nạp năng lượng."
        case 14..<18:
            return "Chiều rồi. Hoàn thành nốt, \(name)."
        case 18..<22:
            return "Kết thúc ngày làm việc."
        default:
            return "Nghỉ ngơi đi, \(name)."
        }
    }
    
    private func getFriendlyGreeting(hour: Int, name: String) -> String {
        switch hour {
        case 5..<12:
            return "Chào \(name)! Bắt đầu ngày mới thôi nào 💪"
        case 12..<14:
            return "Nghỉ trưa chút đi \(name)! 🍜"
        case 14..<18:
            return "Chiều rồi \(name), cố lên một chút nữa! ✨"
        case 18..<22:
            return "Xong việc chưa \(name)? Nghỉ ngơi thôi 🌙"
        default:
            return "Khuya rồi \(name), ngủ sớm nha 😴"
        }
    }
    
    // MARK: - Task Messages
    func getTaskEncouragement(completedCount: Int, totalCount: Int) -> String? {
        guard totalCount > 0 else { return nil }
        
        let progress = Double(completedCount) / Double(totalCount)
        
        switch profile.tone {
        case .calm:
            if progress >= 1 {
                return "Đã xong. Tốt lắm."
            } else if progress >= 0.5 {
                return "Đang tốt."
            }
            return nil
            
        case .focus:
            if progress >= 1 {
                return "Hoàn thành \(completedCount)/\(totalCount) ✓"
            }
            return nil
            
        case .friendly:
            if progress >= 1 {
                return "Tuyệt vời! Xong hết rồi \(profile.displayName)! 🎉"
            } else if progress >= 0.7 {
                return "Sắp xong rồi, cố lên! 💪"
            } else if progress >= 0.5 {
                return "Được nửa rồi đó! ✨"
            }
            return nil
        }
    }
    
    // MARK: - Water Messages
    func getWaterEncouragement(current: Int, goal: Int) -> String? {
        let progress = Double(current) / Double(goal)
        
        switch profile.tone {
        case .calm:
            if progress >= 1 {
                return "Đủ nước rồi."
            } else if progress >= 0.75 {
                return "Gần đủ."
            }
            return nil
            
        case .focus:
            if progress >= 1 {
                return "Đủ \(goal)ml ✓"
            }
            return nil
            
        case .friendly:
            if progress >= 1 {
                return "Uống đủ nước rồi! Giỏi lắm 💧"
            } else if progress >= 0.75 {
                return "Một chút nữa là đủ 2L rồi! 💧"
            } else if progress >= 0.5 {
                return "Được nửa rồi, uống tiếp nha!"
            }
            return nil
        }
    }
}
