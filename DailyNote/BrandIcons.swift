// BrandIcons.swift
// Owl-themed branded icons matching the app logo style

import SwiftUI

// MARK: - Owl Face Icon (Base)
struct OwlFaceIcon: View {
    var mode: ThemeMode = .normal
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Face background
            Circle()
                .fill(faceGradient)
            
            // Eyes container
            HStack(spacing: size * 0.08) {
                // Left eye
                OwlEye(size: size * 0.32, pupilSize: pupilSizeRatio)
                // Right eye
                OwlEye(size: size * 0.32, pupilSize: pupilSizeRatio)
            }
            .offset(y: -size * 0.05)
            
            // Beak
            OwlBeak()
                .fill(Color(hex: "F97316"))
                .frame(width: size * 0.28, height: size * 0.22)
                .offset(y: size * 0.22)
        }
        .frame(width: size, height: size)
    }
    
    private var faceGradient: LinearGradient {
        switch mode {
        case .stressed:
            return LinearGradient(
                colors: [Color(hex: "E54848"), Color(hex: "8B0000")],
                startPoint: .top, endPoint: .bottom
            )
        case .relaxed:
            return LinearGradient(
                colors: [Color(hex: "E5D848"), Color(hex: "A77272")],
                startPoint: .top, endPoint: .bottom
            )
        case .normal:
            return LinearGradient(
                colors: [Color(hex: "4F46E5"), Color(hex: "0F172A")],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
    
    private var pupilSizeRatio: CGFloat {
        switch mode {
        case .stressed: return 0.25  // Small angry pupils
        case .relaxed: return 0.6    // Big relaxed pupils
        case .normal: return 0.45    // Normal pupils
        }
    }
}

// MARK: - Owl Eye
struct OwlEye: View {
    var size: CGFloat
    var pupilSize: CGFloat = 0.45  // Ratio of pupil to eye
    
    var body: some View {
        ZStack {
            // Outer white
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            
            // Golden iris
            Circle()
                .fill(Color(hex: "FFD700"))
                .frame(width: size * 0.85, height: size * 0.85)
            
            // Pupil
            Circle()
                .fill(Color(hex: "0F172A"))
                .frame(width: size * pupilSize, height: size * pupilSize)
            
            // Highlight
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.2, height: size * 0.2)
                .offset(x: size * 0.12, y: -size * 0.12)
        }
    }
}

// MARK: - Owl Beak
struct OwlBeak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Owl Ears (for full logo)
struct OwlEars: View {
    var size: CGFloat
    var mode: ThemeMode = .normal
    
    var body: some View {
        HStack(spacing: size * 0.5) {
            // Left ear
            OwlEar()
                .fill(earColor)
                .frame(width: size * 0.15, height: size * 0.25)
                .rotationEffect(.degrees(-15))
            
            Spacer()
            
            // Right ear
            OwlEar()
                .fill(earColor)
                .frame(width: size * 0.15, height: size * 0.25)
                .rotationEffect(.degrees(15))
        }
        .frame(width: size * 0.8)
    }
    
    private var earColor: Color {
        Color(hex: "E2E8F0")
    }
}

struct OwlEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h * 0.6))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Mode Badge Icons
struct FireIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.55),
            control1: CGPoint(x: w * 0.7, y: h * 0.1),
            control2: CGPoint(x: w * 0.9, y: h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.85, y: h * 0.8),
            control2: CGPoint(x: w * 0.7, y: h)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.55),
            control1: CGPoint(x: w * 0.3, y: h),
            control2: CGPoint(x: w * 0.15, y: h * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.1, y: h * 0.35),
            control2: CGPoint(x: w * 0.3, y: h * 0.1)
        )
        
        return path
    }
}

struct SunIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let innerRadius = min(rect.width, rect.height) * 0.25
        let outerRadius = min(rect.width, rect.height) * 0.45
        
        // Center circle
        path.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        
        // Rays
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let startX = center.x + cos(angle) * innerRadius * 1.3
            let startY = center.y + sin(angle) * innerRadius * 1.3
            let endX = center.x + cos(angle) * outerRadius
            let endY = center.y + sin(angle) * outerRadius
            
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        
        return path
    }
}

struct BriefcaseIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Main body
        path.addRoundedRect(
            in: CGRect(x: w * 0.05, y: h * 0.3, width: w * 0.9, height: h * 0.6),
            cornerSize: CGSize(width: w * 0.08, height: h * 0.08)
        )
        
        // Handle
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.15))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.15),
            control: CGPoint(x: w * 0.5, y: h * 0.05)
        )
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.3))
        
        // Middle clasp
        path.move(to: CGPoint(x: w * 0.05, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.55))
        
        return path
    }
}

struct SmileIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Face circle
        path.addEllipse(in: rect.insetBy(dx: w * 0.1, dy: h * 0.1))
        
        // Left eye
        path.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.32, width: w * 0.12, height: h * 0.12))
        
        // Right eye  
        path.addEllipse(in: CGRect(x: w * 0.6, y: h * 0.32, width: w * 0.12, height: h * 0.12))
        
        // Smile
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.58))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.58),
            control: CGPoint(x: w * 0.5, y: h * 0.78)
        )
        
        return path
    }
}

// MARK: - Helper View for Branded Icons
struct BrandedIconView: View {
    enum IconType {
        case owl(ThemeMode)
        case fire
        case sun
        case briefcase
        case smile
        case task
        case water
        case notes
        case calendar
        case bell
    }
    
    let type: IconType
    var size: CGFloat = 20
    var color: Color = DS.Colors.textSecondary
    
    var body: some View {
        switch type {
        case .owl(let mode):
            OwlFaceIcon(mode: mode, size: size)
        case .fire:
            FireIcon()
                .fill(DS.Colors.stressed)
                .frame(width: size, height: size)
        case .sun:
            SunIcon()
                .stroke(Color(hex: "E5D848"), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: size, height: size)
        case .briefcase:
            BriefcaseIcon()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        case .smile:
            SmileIcon()
                .stroke(Color(hex: "E5D848"), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: size, height: size)
        case .task:
            TaskIcon()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        case .water:
            WaterDropIcon()
                .fill(DS.Colors.water)
                .frame(width: size, height: size)
        case .notes:
            NotesIcon()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        case .calendar:
            CalendarIcon()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        case .bell:
            BellIcon()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
        }
    }
}
