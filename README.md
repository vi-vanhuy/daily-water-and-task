# DailyNote

A professional macOS always-on-top overlay app for daily notes and water reminders.

## 📥 Installation (Dành cho người dùng)

### Bước 1: Tải app
Tải file `DailyNote.app` hoặc `DailyNote.zip` về máy.

### Bước 2: Giải nén (nếu cần)
Nếu bạn tải file `.zip`, double-click để giải nén.

### Bước 3: Di chuyển vào Applications
Kéo `DailyNote.app` vào thư mục **Applications**.

### Bước 4: Mở app lần đầu ⚠️
Vì app chưa được đăng ký với Apple, macOS sẽ hiển thị cảnh báo. Làm theo các bước sau:

**Cách 1: Click chuột phải**
1. **Click chuột phải** (hoặc Control + Click) vào `DailyNote.app`
2. Chọn **"Open"** (Mở)
3. Trong hộp thoại cảnh báo, click **"Open"** để xác nhận

**Cách 2: Qua System Settings**
1. Mở **System Settings** (Cài đặt hệ thống)
2. Vào **Privacy & Security** (Quyền riêng tư & Bảo mật)
3. Cuộn xuống, tìm thông báo về DailyNote
4. Click **"Open Anyway"** (Vẫn mở)

> 💡 Sau lần mở đầu tiên, app sẽ mở bình thường mà không cần làm lại các bước trên.

---

## Features

- **Always-on-top Widget**: Small floating widget showing date, task progress, and water intake progress
- **Quick Popup**: Click widget to open detailed popup with notes, tasks, and water tracking
- **Daily Notes**: Quick notes section with auto-save
- **Task Management**: Add tasks with optional time reminders, checkboxes, and progress tracking
- **Water Tracking**: Track daily water intake with 2L goal, +250ml quick buttons
- **Native Notifications**: Water reminders and task time alerts with snooze support
- **Dark Theme**: Professional modern dark UI design
- **SVG Icons**: Custom vector icons throughout

## Requirements

- macOS 13.0+
- Xcode 15.0+

## Build & Run

### Using Xcode

1. Open `DailyNote.xcodeproj` in Xcode
2. Select the DailyNote target
3. Press ⌘+R to build and run

### Using Command Line

```bash
cd /path/to/DailyNote
xcodebuild -scheme DailyNote -configuration Debug build
```

The built app will be in `build/Debug/DailyNote.app`

## Usage

1. **Widget**: The app appears as a small floating widget in the top-right corner
2. **Click to Open**: Click the widget to open the detailed popup
3. **Notes Tab**: Write quick notes and manage your task list
4. **Water Tab**: Track water intake and view today's hydration log
5. **Close Popup**: Click outside the popup to close it

## Project Structure

```
DailyNote/
├── DailyNoteApp.swift      # App entry point
├── AppDelegate.swift       # Window management
├── DesignSystem.swift      # Colors, typography, spacing
├── Icons.swift             # Custom SVG icons
├── Models.swift            # Data models
├── DataManager.swift       # Persistence layer
├── NotificationManager.swift
├── LaunchHelper.swift      # Launch at login
└── Views/
    ├── WidgetView.swift    # Floating widget
    ├── PopupView.swift     # Main popup container
    ├── NotesSection.swift  # Notes & tasks tab
    └── WaterSection.swift  # Water tracking tab
```

## License

MIT
