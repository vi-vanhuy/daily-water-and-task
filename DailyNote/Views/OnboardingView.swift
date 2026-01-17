// OnboardingView.swift
// First-time user onboarding experience

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var dataManager = DataManager.shared
    @State private var currentStep = 0
    @State private var nickname = ""
    @State private var workStartHour = 9
    @State private var workEndHour = 18
    @State private var selectedTone: AppTone = .calm
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? DS.Colors.accent : DS.Colors.surfaceLight)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.lg)
            
            Spacer()
            
            // Content
            switch currentStep {
            case 0:
                welcomeStep
            case 1:
                setupStep
            case 2:
                toneStep
            default:
                EmptyView()
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: DS.Spacing.md) {
                if currentStep > 0 {
                    Button(action: { withAnimation { currentStep -= 1 } }) {
                        Text("Quay lại")
                            .font(DS.Typography.body)
                            .foregroundColor(DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.md)
                            .background(DS.Colors.surfaceLight)
                            .cornerRadius(DS.Radius.md)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: nextStep) {
                    Text(currentStep == 2 ? "Bắt đầu" : "Tiếp theo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.md)
                        .background(DS.Colors.accent)
                        .cornerRadius(DS.Radius.md)
                }
                .buttonStyle(.plain)
            }
            .padding(DS.Spacing.lg)
        }
        .frame(width: 380, height: 480)
        .background(DS.Colors.background)
    }
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Owl icon
            OwlFaceIcon(mode: .normal, size: 80)
                .frame(width: 80, height: 80)
            
            Text("Chào mừng đến với")
                .font(.system(size: 16))
                .foregroundColor(DS.Colors.textSecondary)
            
            Text("DailyNote")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DS.Colors.textPrimary)
            
            Text("Ứng dụng giúp bạn theo dõi công việc,\nuống nước và ghi chú hàng ngày.")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
    }
    
    private var setupStep: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("🌟 Cài đặt cơ bản")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                // Nickname
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Tên của bạn")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    TextField("VD: Huy, Mai, Minh...", text: $nickname)
                        .textFieldStyle(.plain)
                        .font(DS.Typography.body)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.surfaceLight)
                        .cornerRadius(DS.Radius.sm)
                }
                
                // Work hours
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Giờ làm việc")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    HStack(spacing: DS.Spacing.sm) {
                        Picker("", selection: $workStartHour) {
                            ForEach(5..<13, id: \.self) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                        .frame(width: 80)
                        
                        Text("đến")
                            .foregroundColor(DS.Colors.textSecondary)
                        
                        Picker("", selection: $workEndHour) {
                            ForEach(14..<23, id: \.self) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
    }
    
    private var toneStep: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("🎨 Chọn phong cách")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
            
            Text("Cách app giao tiếp với bạn")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
            
            VStack(spacing: DS.Spacing.sm) {
                ForEach(AppTone.allCases, id: \.self) { tone in
                    Button(action: { selectedTone = tone }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tone.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DS.Colors.textPrimary)
                                
                                Text(tone.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedTone == tone {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DS.Colors.accent)
                            }
                        }
                        .padding(DS.Spacing.md)
                        .background(selectedTone == tone ? DS.Colors.accent.opacity(0.1) : DS.Colors.surfaceLight)
                        .cornerRadius(DS.Radius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .stroke(selectedTone == tone ? DS.Colors.accent : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
    }
    
    // MARK: - Actions
    
    private func nextStep() {
        if currentStep < 2 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            // Save settings and complete onboarding
            if !nickname.isEmpty {
                profileManager.profile.nickname = nickname
            }
            profileManager.profile.workStartHour = workStartHour
            profileManager.profile.workEndHour = workEndHour
            profileManager.profile.tone = selectedTone
            
            // Generate initial water schedule
            dataManager.generateDailyWaterSchedule()
            
            // Mark onboarding complete
            profileManager.completeOnboarding()
            
            // Update theme
            ThemeManager.shared.updateTheme()
        }
    }
}
