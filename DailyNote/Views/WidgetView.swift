// WidgetView.swift
// Compact always-on-top widget view

import SwiftUI

struct WidgetView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var workSession = WorkSessionManager.shared
    var onTap: () -> Void
    
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            // Top row: Date or Work Timer
            HStack(spacing: DS.Spacing.sm) {
                if workSession.isWorking {
                    // Work timer countdown
                    WorkTimerDisplay()
                } else {
                    // Date display
                    CalendarIcon()
                        .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 14, height: 14)
                    
                    Text(dataManager.currentData.shortDate)
                        .font(DS.Typography.widgetDate)
                        .foregroundColor(DS.Colors.textPrimary)
                }
                
                Spacer()
            }
            
            // Progress bars
            HStack(spacing: DS.Spacing.md) {
                // Tasks progress
                ProgressItem(
                    icon: AnyView(
                        TaskIcon()
                            .stroke(DS.Colors.progress, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                            .frame(width: 12, height: 12)
                    ),
                    progress: dataManager.currentData.taskProgress,
                    color: DS.Colors.progress,
                    label: "\(dataManager.currentData.completedTasksCount)/\(dataManager.currentData.tasks.count)"
                )
                
                // Water progress
                ProgressItem(
                    icon: AnyView(
                        WaterDropIcon()
                            .stroke(DS.Colors.water, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                            .frame(width: 12, height: 12)
                    ),
                    progress: dataManager.currentData.waterProgress,
                    color: DS.Colors.water,
                    label: "\(dataManager.currentData.waterIntake)ml"
                )
            }
        }
        .padding(DS.Spacing.md)
        .frame(width: 200, height: 80)
        .background(DS.Colors.background)
        .cornerRadius(DS.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Work Timer Display (with seconds)
struct WorkTimerDisplay: View {
    @ObservedObject var workSession = WorkSessionManager.shared
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let remaining = workSession.remainingTime
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Animated dot
            Circle()
                .fill(DS.Colors.accentGreen)
                .frame(width: 6, height: 6)
                .opacity(currentTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 2) < 1 ? 1 : 0.3)
            
            Text(formattedTime)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(DS.Colors.accentGreen)
            
            Text("còn lại")
                .font(DS.Typography.small)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}

struct ProgressItem: View {
    let icon: AnyView
    let progress: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(spacing: DS.Spacing.xs) {
                icon
                Text(label)
                    .font(DS.Typography.widgetProgress)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DS.Colors.surfaceLight)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}
