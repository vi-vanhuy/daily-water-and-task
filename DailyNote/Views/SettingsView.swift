// SettingsView.swift
// Settings sheet with profile customization

import SwiftUI

struct SettingsView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    // Optional callback for closing the view (useful when presented as a window)
    var customCloseAction: (() -> Void)? = nil
    
    @State private var nickname: String = ""
    @State private var workStartHour: Int = 9
    @State private var workEndHour: Int = 18
    @State private var selectedTone: AppTone = .friendly
    @State private var showSaved = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SettingsHeader(onClose: {
                if let action = customCloseAction {
                    action()
                } else {
                    dismiss()
                }
            })
            
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    // General Section
                    GeneralSection(launchAtLogin: $dataManager.settings.launchAtLogin)
                    
                    // Profile Section
                    ProfileSection(
                        nickname: $nickname,
                        workStartHour: $workStartHour,
                        workEndHour: $workEndHour
                    )
                    
                    // Tone Section
                    ToneSection(selectedTone: $selectedTone)
                    
                    // Save Button
                    SaveButton(showSaved: $showSaved, onSave: saveSettings)
                    
                    // Daily Routines Section
                    RoutinesSection()
                    
                    // Preview
                    PreviewSection()
                    
                    Spacer(minLength: DS.Spacing.xl)
                }
                .padding(DS.Spacing.md)
            }
        }
        .frame(width: 320, height: 600) // Increased height for new section
        .background(DS.Colors.background)
        .cornerRadius(DS.Radius.xl)
        .onAppear {
            loadProfile()
            // Sync launch at login status with system
            dataManager.settings.launchAtLogin = LaunchHelper.shared.isEnabled
        }
        .onChange(of: nickname) { newValue in
            profileManager.profile.nickname = newValue
        }
        .onChange(of: dataManager.settings.launchAtLogin) { newValue in
            LaunchHelper.shared.isEnabled = newValue
        }
        .onChange(of: workStartHour) { newValue in
            profileManager.profile.workStartHour = newValue
        }
        .onChange(of: workEndHour) { newValue in
            profileManager.profile.workEndHour = newValue
        }
        // Note: selectedTone is only applied when user clicks "Lưu cài đặt"
    }
    
    private func loadProfile() {
        nickname = profileManager.profile.nickname
        workStartHour = profileManager.profile.workStartHour
        workEndHour = profileManager.profile.workEndHour
        selectedTone = profileManager.profile.tone
    }
    
    private func saveSettings() {
        // Save all settings
        profileManager.profile.nickname = nickname
        profileManager.profile.workStartHour = workStartHour
        profileManager.profile.workEndHour = workEndHour
        profileManager.profile.tone = selectedTone
        
        // Settings are autosaved by DataManager when changed
        // Just trigger theme update and notification reschedule
        
        // Update theme with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            theme.updateTheme()
        }
        
        // Reschedule notifications
        NotificationManager.shared.scheduleAllNotifications()
        
        // Update work session timer based on new work hours
        WorkSessionManager.shared.checkWorkHours()
        
        // Show saved feedback
        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaved = false
            }
        }
    }
}

// MARK: - Save Button
struct SaveButton: View {
    @Binding var showSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack {
                if showSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Đã lưu!")
                        .font(DS.Typography.headline)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.white)
                    Text("Lưu cài đặt")
                        .font(DS.Typography.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.md)
            .background(
                Group {
                    if showSaved {
                        DS.Colors.completed
                    } else {
                        LinearGradient(
                            colors: [DS.Colors.accent, DS.Colors.accentLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(DS.Radius.md)
        }
        .buttonStyle(.plain)
        .disabled(showSaved)
    }
}

// MARK: - Settings Header
struct SettingsHeader: View {
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Text("Cài đặt")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(DS.Colors.textPrimary)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.lg)
        .background(DS.Colors.surface)
    }
}

// MARK: - General Section
struct GeneralSection: View {
    @Binding var launchAtLogin: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundColor(DS.Colors.textSecondary)
                
            VStack(alignment: .leading, spacing: 0) {
                Text("Khởi động cùng máy")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
            }
            
            Spacer()
            
            Toggle("", isOn: $launchAtLogin)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: DS.Colors.accent))
                .scaleEffect(0.8) // Make toggle slightly smaller
        }
        .padding(DS.Spacing.sm) // Reduced padding
        .background(DS.Colors.surface)
        .cornerRadius(DS.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .stroke(DS.Colors.surfaceLight, lineWidth: 1)
        )
    }
}

// MARK: - Profile Section
struct ProfileSection: View {
    @Binding var nickname: String
    @Binding var workStartHour: Int
    @Binding var workEndHour: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionTitle(title: "Hồ sơ", icon: "person.fill")
            
            // Nickname
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Tên / Nickname")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                
                TextField("Nhập tên của bạn...", text: $nickname)
                    .textFieldStyle(.plain)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colors.surfaceLight)
                    .cornerRadius(DS.Radius.sm)
            }
            
            // Work Hours
            HStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Bắt đầu")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    HourPicker(hour: $workStartHour)
                }
                
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Kết thúc")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    HourPicker(hour: $workEndHour)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Hour Picker
struct HourPicker: View {
    @Binding var hour: Int
    
    var body: some View {
        Picker("", selection: $hour) {
            ForEach(0..<24, id: \.self) { h in
                Text(String(format: "%02d:00", h))
                    .foregroundColor(DS.Colors.textPrimary)
                    .tag(h)
            }
        }
        .pickerStyle(.menu)
        .accentColor(DS.Colors.textPrimary)
        .foregroundColor(DS.Colors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.surfaceLight)
        .cornerRadius(DS.Radius.sm)
    }
}

// MARK: - Tone Section
struct ToneSection: View {
    @Binding var selectedTone: AppTone
    @ObservedObject var profileManager = ProfileManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionTitle(title: "Giọng điệu", icon: "bubble.left.fill")
            
            VStack(spacing: DS.Spacing.sm) {
                ForEach(AppTone.allCases, id: \.self) { tone in
                    ToneButton(
                        tone: tone,
                        isSelected: selectedTone == tone
                    ) {
                        selectedTone = tone
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

struct ToneButton: View {
    let tone: AppTone
    let isSelected: Bool
    let action: () -> Void
    
    // SVG icon for each tone
    @ViewBuilder
    private var toneIcon: some View {
        switch tone {
        case .calm:
            SmileIcon()
                .stroke(Color(hex: "E5D848"), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 22, height: 22)
        case .focus:
            BriefcaseIcon()
                .stroke(DS.Colors.textSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 22)
        case .friendly:
            FireIcon()
                .fill(DS.Colors.stressed)
                .frame(width: 22, height: 22)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                toneIcon
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tone.displayName)
                        .font(DS.Typography.body)
                        .foregroundColor(DS.Colors.textPrimary)
                    
                    Text(tone.description)
                        .font(DS.Typography.small)
                        .foregroundColor(DS.Colors.textTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DS.Colors.accent)
                }
            }
            .padding(DS.Spacing.sm)
            .background(isSelected ? DS.Colors.accent.opacity(0.1) : DS.Colors.surfaceLight)
            .cornerRadius(DS.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(isSelected ? DS.Colors.accent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Section
struct PreviewSection: View {
    @ObservedObject var profileManager = ProfileManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            SectionTitle(title: "Xem trước", icon: "eye.fill")
            
            Text(profileManager.getGreeting())
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .padding(DS.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Colors.surfaceLight)
                .cornerRadius(DS.Radius.sm)
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Section Title
struct SectionTitle: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(DS.Colors.accent)
            
            Text(title)
                .font(DS.Typography.headline)
                .foregroundColor(DS.Colors.textPrimary)
        }
    }
}

// MARK: - Routines Section
struct RoutinesSection: View {
    @ObservedObject var workSession = WorkSessionManager.shared
    @State private var newRoutineTitle = ""
    @State private var newRoutineHour = 9
    @State private var newRoutineMinute = 0
    @State private var showAddRoutine = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                SectionTitle(title: "Lịch trình hằng ngày", icon: "repeat")
                
                Spacer()
                
                Button(action: { showAddRoutine.toggle() }) {
                    Image(systemName: showAddRoutine ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(DS.Colors.accent)
                }
                .buttonStyle(.plain)
            }
            
            Text("Các task sẽ tự động được thêm khi bắt đầu làm việc")
                .font(DS.Typography.small)
                .foregroundColor(DS.Colors.textTertiary)
            
            // Add new routine form
            if showAddRoutine {
                VStack(spacing: DS.Spacing.sm) {
                    TextField("Tên công việc...", text: $newRoutineTitle)
                        .textFieldStyle(.plain)
                        .font(DS.Typography.body)
                        .foregroundColor(DS.Colors.textPrimary)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.surfaceLight)
                        .cornerRadius(DS.Radius.sm)
                    
                    HStack {
                        Text("Lúc:")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        
                        // Hour input
                        TextField("09", text: Binding(
                            get: { String(format: "%02d", newRoutineHour) },
                            set: { newValue in
                                if let hour = Int(newValue.prefix(2)), hour >= 0, hour <= 23 {
                                    newRoutineHour = hour
                                }
                            }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.Colors.textPrimary)
                        .frame(width: 32)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(DS.Colors.surfaceLight)
                        .cornerRadius(DS.Radius.sm)
                        
                        Text(":")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DS.Colors.textSecondary)
                        
                        // Minute input
                        TextField("00", text: Binding(
                            get: { String(format: "%02d", newRoutineMinute) },
                            set: { newValue in
                                if let minute = Int(newValue.prefix(2)), minute >= 0, minute <= 59 {
                                    newRoutineMinute = minute
                                }
                            }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.Colors.textPrimary)
                        .frame(width: 32)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(DS.Colors.surfaceLight)
                        .cornerRadius(DS.Radius.sm)
                        
                        Spacer()
                        
                        Button(action: addRoutine) {
                            Text("Thêm")
                                .font(DS.Typography.small)
                                .foregroundColor(.white)
                                .padding(.horizontal, DS.Spacing.md)
                                .padding(.vertical, DS.Spacing.xs)
                                .background(DS.Colors.accent)
                                .cornerRadius(DS.Radius.sm)
                        }
                        .buttonStyle(.plain)
                        .disabled(newRoutineTitle.isEmpty)
                    }
                }
                .padding(DS.Spacing.sm)
                .background(DS.Colors.surface)
                .cornerRadius(DS.Radius.sm)
            }
            
            // Existing routines list
            if workSession.dailyRoutines.isEmpty {
                Text("Chưa có lịch trình")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
            } else {
                ForEach(workSession.dailyRoutines) { routine in
                    RoutineRow(routine: routine)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
    
    private func addRoutine() {
        guard !newRoutineTitle.isEmpty else { return }
        workSession.addRoutine(title: newRoutineTitle, hour: newRoutineHour, minute: newRoutineMinute)
        newRoutineTitle = ""
        showAddRoutine = false
    }
}

struct RoutineRow: View {
    let routine: DailyRoutine
    @ObservedObject var workSession = WorkSessionManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.title)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                
                Text(routine.formattedTime)
                    .font(DS.Typography.small)
                    .foregroundColor(DS.Colors.accent)
            }
            
            Spacer()
            
            Button(action: { workSession.removeRoutine(routine) }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(DS.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.sm)
        .background(DS.Colors.surfaceLight)
        .cornerRadius(DS.Radius.sm)
    }
}

