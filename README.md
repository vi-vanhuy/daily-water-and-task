# 🦉 DailyNote

**Ứng dụng quản lý công việc và nhắc nhở uống nước cho macOS**

DailyNote là một ứng dụng nhỏ gọn, luôn hiển thị trên màn hình, giúp bạn theo dõi công việc hàng ngày và duy trì thói quen uống nước đủ 2 lít mỗi ngày.

---

## ✨ Tính năng chính

### 📋 Quản lý công việc
- **Thêm task nhanh**: Gõ tên công việc và thêm ngay
- **Đặt lịch nhắc**: Chọn thời gian để nhận thông báo nhắc việc
- **Sắp xếp theo thời gian**: Tasks tự động sắp xếp theo giờ đã đặt
- **Lịch hằng ngày**: Thiết lập các công việc lặp lại hàng ngày
- **Ghi chú nhanh**: Viết memo, ghi nhớ trong ngày

### 💧 Nhắc nhở uống nước
- **Lịch uống nước thông minh**: Tự động chia 2000ml thành các khung giờ phù hợp với thời gian làm việc
- **Thông báo nhắc nhở**: Nhận thông báo khi đến giờ uống nước
- **Theo dõi tiến độ**: Xem bạn đã uống bao nhiêu so với mục tiêu
- **Lịch sử theo ngày**: Xem log các lần uống nước trong ngày

### 🎨 Chế độ Tone
App có 3 chế độ tone, thay đổi cách thông báo và màu sắc giao diện:

| Tone | Mô tả | Màu sắc |
|------|-------|---------|
| **Vui vẻ** | Thư giãn, nhẹ nhàng, không gấp gáp | Cream ấm, nâu nhạt |
| **Công việc** | Ngắn gọn, rõ ràng, tập trung | Kem, cam |
| **Đừng đụng vào tao** | Thẳng thắn, không nể nang | Đen, đỏ |

### 🔔 Thông báo cá nhân hóa
- **30 thông báo task khác nhau**: Dựa trên tone, thời gian trong ngày, và tiến độ
- **18 thông báo nước khác nhau**: Dựa trên tone và tình trạng uống nước
- **Thông báo quá giờ**: Nhắc lại nếu bạn quên uống nước

### 🖥️ Giao diện
- **Widget always-on-top**: Hiển thị ngày, tiến độ task, tiến độ nước
- **Popup chi tiết**: Click widget để mở giao diện đầy đủ
- **Đóng mở dễ dàng**: Click ngoài popup để đóng
- **Work timer**: Đếm ngược thời gian làm việc còn lại

---

## 🔒 Bảo mật & Quyền riêng tư

### ✅ Dữ liệu lưu trữ local
- **Không có server**: Tất cả dữ liệu được lưu trên máy của bạn
- **Không upload**: App không gửi bất kỳ dữ liệu nào lên internet
- **Không analytics**: Không theo dõi hành vi người dùng

### ✅ Quyền truy cập tối thiểu
App chỉ yêu cầu quyền:
- **Notifications**: Để gửi thông báo nhắc việc và uống nước
- **Accessibility** (tùy chọn): Chỉ nếu bạn muốn dùng phím tắt global

### ✅ Dữ liệu được lưu
- Tasks và ghi chú hàng ngày
- Lịch sử uống nước
- Cài đặt cá nhân (tên, giờ làm việc, tone)
- Lịch hằng ngày

Tất cả được lưu trong `UserDefaults` của macOS, chỉ app DailyNote mới có thể truy cập.

---

## 📥 Cài đặt

### Bước 1: Tải app
Tải file `DailyNote.app` hoặc `DailyNote.zip` từ [Releases](../../releases).

### Bước 2: Giải nén (nếu cần)
Double-click file `.zip` để giải nén.

### Bước 3: Di chuyển vào Applications
Kéo `DailyNote.app` vào thư mục **Applications**.

### Bước 4: Mở app lần đầu ⚠️
Vì app chưa được đăng ký với Apple, macOS sẽ hiển thị cảnh báo:

**Cách 1: Click chuột phải**
1. **Control + Click** vào `DailyNote.app`
2. Chọn **"Open"**
3. Click **"Open"** trong hộp thoại cảnh báo

**Cách 2: Qua System Settings**
1. Mở **System Settings** → **Privacy & Security**
2. Cuộn xuống tìm thông báo về DailyNote
3. Click **"Open Anyway"**

> 💡 Sau lần mở đầu tiên, app sẽ mở bình thường.

---

## 🛠️ Build từ source

### Yêu cầu
- macOS 13.0+
- Xcode 15.0+

### Xcode
```bash
open DailyNote.xcodeproj
# Chọn target DailyNote → ⌘+R
```

### Command Line
```bash
xcodebuild -scheme DailyNote -configuration Debug build
```

---

## 📁 Cấu trúc dự án

```
DailyNote/
├── DailyNoteApp.swift      # Entry point
├── AppDelegate.swift       # Window management
├── DesignSystem.swift      # Dynamic theme colors
├── SmartToneEngine.swift   # Personalized messages
├── NotificationManager.swift
├── DataManager.swift       # Persistence
├── WorkSession.swift       # Work timer & routines
├── UserProfile.swift       # Profile & tone settings
└── Views/
    ├── WidgetView.swift    # Always-on-top widget
    ├── PopupView.swift     # Main popup
    ├── NotesSection.swift  # Tasks & notes
    ├── WaterSection.swift  # Water tracking
    ├── SettingsView.swift  # Settings
    └── OnboardingView.swift
```

---

## 📜 License

MIT License - Tự do sử dụng và chỉnh sửa.

---

**Made with 🦉 by DailyNote Team**
