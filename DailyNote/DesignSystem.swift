// DesignSystem.swift
// Centralized design tokens for DailyNote with dynamic theme support

import SwiftUI

// MARK: - Theme Mode
enum ThemeMode {
    case normal
    case relaxed    // Vui vẻ - warm yellow/pink
    case stressed   // Căng thẳng - dark/red
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentMode: ThemeMode = .normal
    
    var isStressedMode: Bool { currentMode == .stressed }
    var isRelaxedMode: Bool { currentMode == .relaxed }
    
    func updateTheme() {
        let context = SmartToneEngine.shared.getCurrentContext()
        let profile = ProfileManager.shared.profile
        
        // If user selected "Đừng đụng vào tao" tone, always use stressed mode
        if profile.isHarshModeEnabled {
            currentMode = .stressed
        } else if context == .stressed {
            // Auto-detect stressed context
            currentMode = .stressed
        } else if context == .relaxed {
            currentMode = .relaxed
        } else {
            currentMode = .normal
        }
    }
}

struct DS {
    // MARK: - Dynamic Colors
    struct Colors {
        private static var theme: ThemeManager { ThemeManager.shared }
        
        // Backgrounds
        static var background: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "1A1A1A")
            case .relaxed: return Color(hex: "FFF8E7")   // Warm cream
            case .normal: return Color(hex: "FDF6E9")
            }
        }
        static var surface: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "2D2D2D")
            case .relaxed: return Color(hex: "FFF0D4")   // Soft peach
            case .normal: return Color(hex: "F5EDD8")
            }
        }
        static var surfaceLight: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "3D3D3D")
            case .relaxed: return Color(hex: "FFE8C8")   // Light peach
            case .normal: return Color(hex: "EDE4CF")
            }
        }
        
        // Accent colors
        static var accent: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "E54848")
            case .relaxed: return Color(hex: "E5D848")   // Happy yellow
            case .normal: return Color(hex: "E6A800")
            }
        }
        static var accentLight: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "FF6B6B")
            case .relaxed: return Color(hex: "FFE066")   // Light yellow
            case .normal: return Color(hex: "FFD54F")
            }
        }
        static let accentOrange = Color(hex: "FF9500")
        static let accentGreen = Color(hex: "4CAF50")
        
        // Text
        static var textPrimary: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "FFFFFF")
            case .relaxed: return Color(hex: "4A3B2A")   // Warm brown
            case .normal: return Color(hex: "2D2A26")
            }
        }
        static var textSecondary: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "AAAAAA")
            case .relaxed: return Color(hex: "7A6B5A")   // Soft brown
            case .normal: return Color(hex: "6B5E4A")
            }
        }
        static var textTertiary: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "777777")
            case .relaxed: return Color(hex: "A79B8A")   // Light brown
            case .normal: return Color(hex: "9C8B73")
            }
        }
        
        // Borders & Effects
        static var border: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "444444")
            case .relaxed: return Color(hex: "E8D4B8")   // Soft border
            case .normal: return Color(hex: "D4C4A8")
            }
        }
        static var glow: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "E54848").opacity(0.3)
            case .relaxed: return Color(hex: "E5D848").opacity(0.3)
            case .normal: return Color(hex: "E6A800").opacity(0.3)
            }
        }
        
        // Functional colors
        static let water = Color(hex: "2196F3")
        static var progress: Color {
            switch theme.currentMode {
            case .stressed: return Color(hex: "E54848")
            case .relaxed: return Color(hex: "E5D848")
            case .normal: return Color(hex: "E6A800")
            }
        }
        static let completed = Color(hex: "4CAF50")
        
        // Mode specific
        static let stressed = Color(hex: "E54848")
        static let relaxed = Color(hex: "A77272")   // Soft pink
        static let stressedDark = Color(hex: "8B0000")
    }
    
    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let small = Font.system(size: 11, weight: .medium, design: .rounded)
        static let widgetDate = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let widgetProgress = Font.system(size: 10, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    @ObservedObject var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(DS.Colors.surface)
            .cornerRadius(DS.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
