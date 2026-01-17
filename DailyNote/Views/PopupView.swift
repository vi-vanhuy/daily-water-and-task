// PopupView.swift
// Main popup panel with tabs for Notes and Water

import SwiftUI

struct PopupView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var workSession = WorkSessionManager.shared
    @ObservedObject var theme = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var showSettings = false
    var onClose: () -> Void
    
    var body: some View {
        Group {
            if !profileManager.hasCompletedOnboarding {
                // First-time onboarding
                OnboardingView()
            } else {
                // Main app content
                mainContent
            }
        }
        .frame(width: profileManager.hasCompletedOnboarding ? 320 : 380, 
               height: profileManager.hasCompletedOnboarding ? 520 : 480)
        .background(DS.Colors.background)
        .cornerRadius(DS.Radius.lg)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header with greeting and work timer
            HeaderView(
                greeting: profileManager.getGreeting(),
                date: dataManager.currentData.formattedDate,
                showSettings: $showSettings
            )
            
            // Tab selector
            TabSelector(selectedTab: $selectedTab)
            
            // Content
            ZStack {
                if selectedTab == 0 {
                    NotesSection()
                        .transition(.opacity)
                } else {
                    WaterSection()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .onAppear {
            theme.updateTheme()
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let greeting: String
    let date: String
    @Binding var showSettings: Bool
    @ObservedObject var workSession = WorkSessionManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    // Dynamic owl icon based on mode
    private var owlIconView: some View {
        OwlFaceIcon(mode: theme.currentMode, size: 24)
    }
    
    // Dynamic logo colors based on mode
    private var logoColors: [Color] {
        switch theme.currentMode {
        case .stressed: return [DS.Colors.stressed, Color(hex: "FF6B6B")]
        case .relaxed: return [Color(hex: "E5D848"), DS.Colors.relaxed]
        case .normal: return [DS.Colors.accent, DS.Colors.accentLight]
        }
    }
    
    // Mode badge (text, color) - nil for normal mode
    private var modeBadge: (String, Color)? {
        switch theme.currentMode {
        case .stressed: return ("FOCUS", DS.Colors.stressed)
        case .relaxed: return ("CHILL", DS.Colors.relaxed)
        case .normal: return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            // Top row: Logo + Mode indicator + Actions
            HStack {
                // Owl icon that changes based on mode
                owlIconView
                
                Text("DailyNote")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: logoColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Mode badge
                if let badge = modeBadge {
                    Text(badge.0)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badge.1)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Colors.textSecondary)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.surfaceLight)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Cài đặt")
            }
            
            // Greeting message
            Text(greeting)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .lineLimit(2)
            
            // Date and Work Timer Row
            HStack(spacing: DS.Spacing.md) {
                // Date
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Colors.accent)
                    Text(date)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
                
                Spacer()
                
                // Work Timer
                WorkTimerButton()
            }
        }
        .padding(DS.Spacing.lg)
        .background(DS.Colors.surface)
    }
}

// MARK: - Work Timer Button
struct WorkTimerButton: View {
    @ObservedObject var workSession = WorkSessionManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    
    var body: some View {
        Button(action: toggleWorkSession) {
            HStack(spacing: DS.Spacing.xs) {
                Circle()
                    .fill(workSession.isWorking ? DS.Colors.accentGreen : DS.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                
                if workSession.isWorking {
                    Text("Còn \(workSession.formattedRemainingTime)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.Colors.accentGreen)
                } else {
                    Text("Bắt đầu làm việc")
                        .font(DS.Typography.small)
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(workSession.isWorking ? DS.Colors.accentGreen.opacity(0.1) : DS.Colors.surfaceLight)
            .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(.plain)
    }
    
    private func toggleWorkSession() {
        if workSession.isWorking {
            workSession.endWorkSession()
        } else {
            workSession.startWorkSession()
            // Apply daily routines when starting work
            workSession.applyRoutinesToToday()
        }
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                icon: AnyShape(NotesIcon()),
                title: "Công việc",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabButton(
                icon: AnyShape(WaterDropIcon()),
                title: "Uống nước",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
        }
        .padding(DS.Spacing.sm)
        .background(DS.Colors.surface)
    }
}

struct TabButton: View {
    let icon: AnyShape
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                icon
                    .stroke(
                        isSelected ? DS.Colors.accent : DS.Colors.textSecondary,
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundColor(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .background(isSelected ? DS.Colors.surfaceLight : .clear)
            .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(.plain)
    }
}
