// NotesSection.swift
// Notes and Tasks tab content

import SwiftUI

struct NotesSection: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var newTaskText = ""
    @State private var showTimePicker = false
    @State private var selectedTime = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.md) {
                // Quick notes
                NotesCard()
                
                // Task input
                TaskInputCard(
                    newTaskText: $newTaskText,
                    showTimePicker: $showTimePicker,
                    selectedTime: $selectedTime,
                    onAdd: addTask
                )
                
                // Apply daily routines button
                ApplyRoutinesButton()
                
                // Tasks list
                TasksListCard()
            }
            .padding(DS.Spacing.md)
        }
    }
    
    private func addTask() {
        let time = showTimePicker ? selectedTime : nil
        dataManager.addTask(title: newTaskText, scheduledTime: time)
        newTaskText = ""
        showTimePicker = false
    }
}

// MARK: - Notes Card
struct NotesCard: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var notesText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                NotesIcon()
                    .stroke(DS.Colors.textSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 14)
                
                Text("Quick Notes")
                    .font(DS.Typography.headline)
                    .foregroundColor(DS.Colors.textPrimary)
            }
            
            TextEditor(text: $notesText)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.surfaceLight)
                .cornerRadius(DS.Radius.sm)
                .frame(height: 80)
                .onChange(of: notesText) { newValue in
                    dataManager.updateNotes(newValue)
                }
                .onAppear {
                    notesText = dataManager.currentData.notes
                }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Task Input Card
struct TaskInputCard: View {
    @Binding var newTaskText: String
    @Binding var showTimePicker: Bool
    @Binding var selectedTime: Date
    let onAdd: () -> Void
    
    // Quick times that are still in the future
    private var futureQuickTimes: [(label: String, hour: Int)] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let times = [(label: "9:00", hour: 9), (label: "12:00", hour: 12), 
                     (label: "15:00", hour: 15), (label: "18:00", hour: 18), (label: "21:00", hour: 21)]
        return times.filter { $0.hour > currentHour }
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                TextField("Thêm công việc...", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(DS.Spacing.sm)
                    .background(DS.Colors.surfaceLight)
                    .cornerRadius(DS.Radius.sm)
                    .onSubmit {
                        if !newTaskText.isEmpty {
                            onAdd()
                        }
                    }
                
                // Time toggle
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTimePicker.toggle() 
                    }
                }) {
                    HStack(spacing: 4) {
                        BellIcon()
                            .stroke(
                                showTimePicker ? DS.Colors.accent : DS.Colors.textSecondary,
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 16, height: 16)
                        
                        if showTimePicker {
                            Text(formatTime(selectedTime))
                                .font(DS.Typography.small)
                                .foregroundColor(DS.Colors.accent)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(showTimePicker ? DS.Colors.accent.opacity(0.15) : .clear)
                    .cornerRadius(DS.Radius.sm)
                }
                .buttonStyle(.plain)
                
                // Add button
                Button(action: onAdd) {
                    PlusIcon()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 16, height: 16)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colors.accent)
                        .cornerRadius(DS.Radius.sm)
                }
                .buttonStyle(.plain)
                .disabled(newTaskText.isEmpty)
                .opacity(newTaskText.isEmpty ? 0.5 : 1)
            }
            
            // Time picker section
            if showTimePicker {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Nhắc lúc:")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    HStack {
                        // Only allow future times
                        DatePicker("", selection: $selectedTime, in: Date()..., displayedComponents: .hourAndMinute)
                            .datePickerStyle(.stepperField)
                            .labelsHidden()
                        
                        Spacer()
                        
                        // Quick time buttons - only show future times
                        HStack(spacing: DS.Spacing.xs) {
                            ForEach(futureQuickTimes, id: \.hour) { time in
                                QuickTimeButton(label: time.label, hour: time.hour, minute: 0, selectedTime: $selectedTime)
                            }
                        }
                    }
                }
                .padding(DS.Spacing.sm)
                .background(DS.Colors.surfaceLight)
                .cornerRadius(DS.Radius.sm)
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// Quick time button
struct QuickTimeButton: View {
    let label: String
    let hour: Int
    let minute: Int
    @Binding var selectedTime: Date
    
    var body: some View {
        Button(action: {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            if let newTime = Calendar.current.date(from: components) {
                selectedTime = newTime
            }
        }) {
            Text(label)
                .font(DS.Typography.small)
                .foregroundColor(DS.Colors.textSecondary)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(DS.Colors.surface)
                .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tasks List Card
struct TasksListCard: View {
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                TaskIcon()
                    .stroke(DS.Colors.textSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 14)
                
                Text("Tasks")
                    .font(DS.Typography.headline)
                    .foregroundColor(DS.Colors.textPrimary)
                
                Spacer()
                
                Text("\(dataManager.currentData.completedTasksCount)/\(dataManager.currentData.tasks.count)")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            
            if dataManager.currentData.tasks.isEmpty {
                Text("No tasks yet")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.lg)
            } else {
                ForEach(dataManager.currentData.tasks) { task in
                    TaskRow(task: task)
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: TaskItem
    @ObservedObject var dataManager = DataManager.shared
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Checkbox
            Button(action: { dataManager.toggleTask(task) }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(task.isCompleted ? DS.Colors.completed : DS.Colors.textSecondary, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if task.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DS.Colors.completed)
                            .frame(width: 20, height: 20)
                        
                        CheckmarkIcon()
                            .stroke(DS.Colors.background, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(DS.Typography.body)
                    .foregroundColor(task.isCompleted ? DS.Colors.textTertiary : DS.Colors.textPrimary)
                    .strikethrough(task.isCompleted, color: DS.Colors.textTertiary)
                
                if let time = task.formattedTime {
                    Text(time)
                        .font(DS.Typography.small)
                        .foregroundColor(DS.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: { dataManager.deleteTask(task) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DS.Colors.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - Apply Routines Button
struct ApplyRoutinesButton: View {
    @ObservedObject var workSession = WorkSessionManager.shared
    @State private var showApplied = false
    @State private var showSettings = false
    
    var body: some View {
        if workSession.dailyRoutines.isEmpty {
            // No routines - show button to add in Settings
            Button(action: { showSettings = true }) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    Text("Thêm lịch hằng ngày")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundColor(DS.Colors.textTertiary)
                }
                .padding(DS.Spacing.sm)
                .background(DS.Colors.surfaceLight)
                .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        } else {
            // Has routines - show apply button
            Button(action: applyRoutines) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: showApplied ? "checkmark.circle.fill" : "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(showApplied ? DS.Colors.completed : DS.Colors.accent)
                    
                    Text(showApplied ? "Đã áp dụng!" : "Áp dụng lịch hằng ngày (\(workSession.dailyRoutines.count))")
                        .font(DS.Typography.caption)
                        .foregroundColor(showApplied ? DS.Colors.completed : DS.Colors.accent)
                    
                    Spacer()
                    
                    if !showApplied {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(DS.Colors.textTertiary)
                    }
                }
                .padding(DS.Spacing.sm)
                .background(showApplied ? DS.Colors.completed.opacity(0.1) : DS.Colors.accent.opacity(0.1))
                .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(.plain)
            .disabled(showApplied)
        }
    }
    
    private func applyRoutines() {
        workSession.applyRoutinesToToday()
        withAnimation {
            showApplied = true
        }
        
        // Reset after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showApplied = false
            }
        }
    }
}
