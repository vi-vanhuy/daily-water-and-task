// Icons.swift
// Custom SVG icons as SwiftUI Shapes

import SwiftUI

// MARK: - Water Drop Icon
struct WaterDropIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.9, y: height * 0.4),
            control2: CGPoint(x: width * 0.9, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.1, y: height * 0.8),
            control2: CGPoint(x: width * 0.1, y: height * 0.4)
        )
        
        return path
    }
}

// MARK: - Checkmark Icon
struct CheckmarkIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.7))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))
        
        return path
    }
}

// MARK: - Plus Icon
struct PlusIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Horizontal line
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.5))
        
        // Vertical line
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.8))
        
        return path
    }
}

// MARK: - Calendar Icon
struct CalendarIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Main body
        path.addRoundedRect(
            in: CGRect(x: width * 0.1, y: height * 0.2, width: width * 0.8, height: height * 0.7),
            cornerSize: CGSize(width: width * 0.1, height: height * 0.1)
        )
        
        // Header line
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.4))
        
        // Hangers
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.3))
        
        path.move(to: CGPoint(x: width * 0.7, y: height * 0.1))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.3))
        
        return path
    }
}

// MARK: - Bell Icon
struct BellIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Bell body
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.1))
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.6),
            control1: CGPoint(x: width * 0.25, y: height * 0.1),
            control2: CGPoint(x: width * 0.2, y: height * 0.35)
        )
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.6))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.1),
            control1: CGPoint(x: width * 0.8, y: height * 0.35),
            control2: CGPoint(x: width * 0.75, y: height * 0.1)
        )
        
        // Clapper
        path.addEllipse(in: CGRect(
            x: width * 0.4, y: height * 0.8,
            width: width * 0.2, height: height * 0.15
        ))
        
        return path
    }
}

// MARK: - Task Icon (Checkbox outline)
struct TaskIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.addRoundedRect(
            in: CGRect(x: width * 0.15, y: height * 0.15, width: width * 0.7, height: height * 0.7),
            cornerSize: CGSize(width: width * 0.1, height: height * 0.1)
        )
        
        return path
    }
}

// MARK: - Notes Icon
struct NotesIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Paper
        path.addRoundedRect(
            in: CGRect(x: width * 0.15, y: height * 0.1, width: width * 0.7, height: height * 0.8),
            cornerSize: CGSize(width: width * 0.05, height: height * 0.05)
        )
        
        // Lines
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.35))
        
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.5))
        
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.65))
        path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.65))
        
        return path
    }
}

// MARK: - Icon View Wrapper
struct IconView: View {
    let icon: AnyShape
    var size: CGFloat = 20
    var color: Color = DS.Colors.textSecondary
    var strokeWidth: CGFloat = 1.5
    
    var body: some View {
        icon
            .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

// MARK: - AnyShape wrapper for type erasure
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
