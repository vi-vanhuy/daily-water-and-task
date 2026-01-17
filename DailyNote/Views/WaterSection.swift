// WaterSection.swift
// Water tracking tab content

import SwiftUI

struct WaterSection: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                // Main progress display
                WaterProgressCard()
                
                // Combined water hub (schedule)
                WaterHubCard()
                
                // Today's log
                WaterLogCard()
            }
            .padding(DS.Spacing.md)
        }
    }
}

// MARK: - Water Timeline Card
struct WaterTimelineCard: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    
    private var startHour: Int { profileManager.profile.workStartHour }
    private var endHour: Int { profileManager.profile.workEndHour }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Dòng thời gian")
                    .font(DS.Typography.headline)
                    .foregroundColor(DS.Colors.textPrimary)
                
                Spacer()
                
                Text("\(startHour):00 - \(endHour):00")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            
            // Timeline visualization
            GeometryReader { geo in
                let totalHours = CGFloat(endHour - startHour)
                let hourWidth = geo.size.width / totalHours
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Colors.surfaceLight)
                        .frame(height: 32)
                    
                    // Hour markers
                    ForEach(0..<Int(totalHours + 1), id: \.self) { i in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(DS.Colors.border)
                                .frame(width: 1, height: 8)
                            
                            if i % 2 == 0 || totalHours <= 6 {
                                Text("\(startHour + i)")
                                    .font(.system(size: 8))
                                    .foregroundColor(DS.Colors.textTertiary)
                            }
                        }
                        .offset(x: CGFloat(i) * hourWidth - 4, y: 20)
                    }
                    
                    // Water intake dots
                    ForEach(dataManager.waterLog) { entry in
                        let hour = Calendar.current.component(.hour, from: entry.timestamp)
                        let minute = Calendar.current.component(.minute, from: entry.timestamp)
                        
                        if hour >= startHour && hour < endHour {
                            let position = (CGFloat(hour - startHour) + CGFloat(minute) / 60.0) * hourWidth
                            
                            WaterDot(amount: entry.amount)
                                .offset(x: position - 8)
                        }
                    }
                    
                    // Current time indicator
                    CurrentTimeIndicator(
                        startHour: startHour,
                        endHour: endHour,
                        hourWidth: hourWidth
                    )
                }
            }
            .frame(height: 50)
            
            // Legend
            HStack(spacing: DS.Spacing.lg) {
                LegendItem(color: DS.Colors.water.opacity(0.5), text: "≤200ml")
                LegendItem(color: DS.Colors.water.opacity(0.75), text: "≤350ml")
                LegendItem(color: DS.Colors.water, text: ">350ml")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Water Dot
struct WaterDot: View {
    let amount: Int
    
    private var opacity: Double {
        if amount <= 200 { return 0.5 }
        else if amount <= 350 { return 0.75 }
        else { return 1.0 }
    }
    
    private var size: CGFloat {
        if amount <= 200 { return 12 }
        else if amount <= 350 { return 14 }
        else { return 16 }
    }
    
    var body: some View {
        Circle()
            .fill(DS.Colors.water.opacity(opacity))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(DS.Colors.water, lineWidth: 1)
            )
            .offset(y: -8)
    }
}

// MARK: - Current Time Indicator
struct CurrentTimeIndicator: View {
    let startHour: Int
    let endHour: Int
    let hourWidth: CGFloat
    
    var body: some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        
        if hour >= startHour && hour < endHour {
            let position = (CGFloat(hour - startHour) + CGFloat(minute) / 60.0) * hourWidth
            
            VStack(spacing: 0) {
                Triangle()
                    .fill(DS.Colors.accent)
                    .frame(width: 8, height: 6)
                
                Rectangle()
                    .fill(DS.Colors.accent)
                    .frame(width: 2, height: 26)
            }
            .offset(x: position - 4, y: -3)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 9))
                .foregroundColor(DS.Colors.textTertiary)
        }
    }
}

// MARK: - Water Progress Card
struct WaterProgressCard: View {
    @ObservedObject var dataManager = DataManager.shared
    
    private var progress: Double {
        dataManager.currentData.waterProgress
    }
    
    private var currentAmount: Int {
        dataManager.currentData.waterIntake
    }
    
    private var goalAmount: Int {
        dataManager.settings.waterGoal
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(DS.Colors.surfaceLight, lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [DS.Colors.water, Color(hex: "29B6F6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: progress)
                
                // Center content
                VStack(spacing: DS.Spacing.xs) {
                    WaterDropIcon()
                        .fill(DS.Colors.water)
                        .frame(width: 24, height: 24)
                    
                    Text("\(currentAmount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Colors.textPrimary)
                    
                    Text("of \(goalAmount)ml")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            
            // Percentage
            Text("\(Int(progress * 100))% complete")
                .font(DS.Typography.headline)
                .foregroundColor(progress >= 1 ? DS.Colors.progress : DS.Colors.textSecondary)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: - Water Hub Card (Unified: Schedule + Quick Add)
struct WaterHubCard: View {
    @ObservedObject var dataManager = DataManager.shared
    
    private let quickAmounts = [150, 250, 350, 500]
    
    private var current: Int { dataManager.currentData.waterIntake }
    private var goal: Int { dataManager.settings.waterGoal }
    
    private var completedGoals: Int {
        dataManager.waterGoals.filter { $0.isCompleted }.count
    }
    
    private var totalGoals: Int {
        dataManager.waterGoals.count
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            // Header
            HStack {
                WaterDropIcon()
                    .fill(DS.Colors.water)
                    .frame(width: 16, height: 16)
                
                Text("\(current)/\(goal)ml")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Colors.textPrimary)
                
                Spacer()
                
                // Generate/Refresh button
                Button(action: { dataManager.generateDailyWaterSchedule() }) {
                    HStack(spacing: 4) {
                        Image(systemName: totalGoals == 0 ? "wand.and.stars" : "arrow.clockwise")
                            .font(.system(size: 11))
                        Text(totalGoals == 0 ? "Tạo lịch" : "\(completedGoals)/\(totalGoals)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DS.Colors.water)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DS.Colors.water.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            // Simple goal list
            if !dataManager.waterGoals.isEmpty {
                VStack(spacing: 6) {
                    ForEach(dataManager.waterGoals) { goal in
                        WaterGoalListItem(goal: goal)
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Water Goal List Item (Simple row)
struct WaterGoalListItem: View {
    let goal: WaterGoal
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dataManager.toggleWaterGoal(goal)
            }
        }) {
            HStack(spacing: DS.Spacing.sm) {
                // Time
                Text(goal.formattedTime)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(goal.isOverdue && !goal.isCompleted ? DS.Colors.stressed : DS.Colors.textSecondary)
                    .frame(width: 40, alignment: .leading)
                
                Text("-")
                    .foregroundColor(DS.Colors.textTertiary)
                
                // Amount
                Text("\(goal.amount)ml")
                    .font(.system(size: 12))
                    .foregroundColor(goal.isCompleted ? DS.Colors.textTertiary : DS.Colors.textPrimary)
                    .strikethrough(goal.isCompleted)
                
                Spacer()
                
                // Checkbox icon
                ZStack {
                    Circle()
                        .stroke(goal.isCompleted ? DS.Colors.completed : (goal.isOverdue ? DS.Colors.stressed : DS.Colors.water), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if goal.isCompleted {
                        Circle()
                            .fill(DS.Colors.completed)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Water Timeline Dots
struct WaterTimelineDots: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    
    private var startHour: Int { profileManager.profile.workStartHour }
    private var endHour: Int { profileManager.profile.workEndHour }
    
    var body: some View {
        GeometryReader { geo in
            let totalHours = CGFloat(endHour - startHour)
            let hourWidth = geo.size.width / totalHours
            let now = Date()
            let currentHour = Calendar.current.component(.hour, from: now)
            let currentMinute = Calendar.current.component(.minute, from: now)
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(DS.Colors.surfaceLight)
                    .frame(height: 6)
                
                // Hour labels
                HStack(spacing: 0) {
                    ForEach(0..<Int(totalHours + 1), id: \.self) { i in
                        if i < Int(totalHours) {
                            Text("\(startHour + i)")
                                .font(.system(size: 8))
                                .foregroundColor(DS.Colors.textTertiary)
                                .frame(width: hourWidth, alignment: .leading)
                        }
                    }
                }
                .offset(y: 14)
                
                // Current time indicator
                if currentHour >= startHour && currentHour < endHour {
                    let position = (CGFloat(currentHour - startHour) + CGFloat(currentMinute) / 60.0) * hourWidth
                    
                    Triangle()
                        .fill(DS.Colors.accent)
                        .frame(width: 8, height: 6)
                        .offset(x: position - 4, y: -8)
                }
                
                // Goal dots
                ForEach(dataManager.waterGoals) { goal in
                    let hour = Calendar.current.component(.hour, from: goal.scheduledTime)
                    let minute = Calendar.current.component(.minute, from: goal.scheduledTime)
                    
                    if hour >= startHour && hour < endHour {
                        let position = (CGFloat(hour - startHour) + CGFloat(minute) / 60.0) * hourWidth
                        
                        WaterGoalDot(goal: goal)
                            .offset(x: position - 8)
                    }
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Water Goal Dot (Tappable)
struct WaterGoalDot: View {
    let goal: WaterGoal
    @ObservedObject var dataManager = DataManager.shared
    @State private var showTooltip = false
    
    private var dotColor: Color {
        if goal.isCompleted {
            return DS.Colors.completed
        } else if goal.isOverdue {
            return DS.Colors.stressed
        } else {
            return DS.Colors.water
        }
    }
    
    private var dotStyle: some View {
        ZStack {
            if goal.isCompleted {
                // Filled dot for completed
                Circle()
                    .fill(dotColor)
                    .frame(width: 16, height: 16)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            } else if goal.isOverdue {
                // Half-filled for overdue
                Circle()
                    .stroke(dotColor, lineWidth: 2)
                    .frame(width: 16, height: 16)
                
                Circle()
                    .fill(dotColor.opacity(0.5))
                    .frame(width: 10, height: 10)
            } else {
                // Empty dot for pending
                Circle()
                    .stroke(dotColor, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dataManager.toggleWaterGoal(goal)
            }
        }) {
            dotStyle
        }
        .buttonStyle(.plain)
        .help("\(goal.formattedTime) - \(goal.amount)ml")
    }
}

// MARK: - Water Log Card
struct WaterLogCard: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text("Today's Log")
                    .font(DS.Typography.headline)
                    .foregroundColor(DS.Colors.textPrimary)
                
                Spacer()
                
                Text("\(dataManager.waterLog.count) entries")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            
            if dataManager.waterLog.isEmpty {
                Text("No water logged yet")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.lg)
            } else {
                ForEach(dataManager.waterLog.reversed()) { entry in
                    WaterLogRow(entry: entry)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Water Log Row
struct WaterLogRow: View {
    let entry: WaterLogEntry
    
    var body: some View {
        HStack {
            WaterDropIcon()
                .stroke(DS.Colors.water, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                .frame(width: 14, height: 14)
            
            Text("+\(entry.amount)ml")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
            
            Spacer()
            
            Text(entry.formattedTime)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}
