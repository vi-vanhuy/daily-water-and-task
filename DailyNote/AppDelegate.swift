// AppDelegate.swift
// Manages floating widget window and popup panel

import SwiftUI
import AppKit

// Custom window class that accepts keyboard input
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var widgetWindow: NSWindow!
    var popupWindow: KeyableWindow!
    var dataManager = DataManager.shared
    var notificationManager = NotificationManager.shared
    
    private var eventMonitor: Any?
    private var localEventMonitor: Any?
    
    // Menu Bar Icon
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar icon
        setupMenuBarIcon()
        
        // Setup notification permissions
        notificationManager.requestPermission()
        
        // Create widget window
        setupWidgetWindow()
        
        // Create popup window (hidden initially)
        setupPopupWindow()
        
        // Monitor for clicks outside popup to close it
        setupEventMonitor()
        
        // Setup keyboard shortcut monitor (intercept Cmd+Q)
        setupKeyboardMonitor()
        
        // Schedule smart water reminders
        notificationManager.scheduleAllNotifications()
        
        // Check for first launch
        checkFirstLaunch()
    }
    
    // Intercept Cmd+Q to hide popup instead of quitting
    private var keyboardMonitor: Any?
    
    private func setupKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Cmd+Q
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                // Hide popup instead of quitting
                self?.hidePopup()
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func checkFirstLaunch() {
        let key = "hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            
            // First time launch - show Settings to encourage "Launch at Login"
            // Wait a bit for app to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                // Opening Settings is equivalent to right click context menu -> Settings
                // But we don't have a direct method exposed easily. 
                // Let's implement a showSettings method in AppDelegate that creates the view if needed.
                self?.showSettingsWindow()
            }
        }
    }
    
    // Manage settings window instance
    private var settingsWindow: NSWindow?
    
    func showSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingView = NSHostingView(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 600),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Cài đặt DailyNote"
            window.center()
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Menu Bar Icon
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use custom menu bar icon from Assets
            if let menuBarIcon = NSImage(named: "MenuBarIcon") {
                menuBarIcon.size = NSSize(width: 18, height: 18)
                button.image = menuBarIcon
            }
            button.action = #selector(menuBarIconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func menuBarIconClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            // Right click - show menu
            showStatusMenu()
        } else {
            // Left click - show widget (popup is opened by clicking widget)
            showWidget()
        }
    }
    
    // Show widget if hidden
    func showWidget() {
        if !widgetWindow.isVisible {
            widgetWindow.orderFrontRegardless()
        }
    }
    
    private func showStatusMenu() {
        let menu = NSMenu()
        
        // Water progress
        let waterProgress = dataManager.currentData.waterIntake
        let waterGoal = dataManager.settings.waterGoal
        menu.addItem(NSMenuItem(title: "Nước: \(waterProgress)/\(waterGoal)ml", action: nil, keyEquivalent: ""))
        
        // Task progress
        let completed = dataManager.currentData.completedTasksCount
        let total = dataManager.currentData.tasks.count
        menu.addItem(NSMenuItem(title: "Tasks: \(completed)/\(total)", action: nil, keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Cài đặt", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Toggle widget visibility
        let widgetItem = NSMenuItem(title: widgetWindow.isVisible ? "Ẩn Widget" : "Hiện Widget", action: #selector(toggleWidgetVisibility), keyEquivalent: "w")
        widgetItem.target = self
        menu.addItem(widgetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Thoát", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil  // Reset so left click works again
    }
    
    @objc func openSettings() {
        showSettingsWindow()
    }
    
    @objc private func toggleWidgetVisibility() {
        if widgetWindow.isVisible {
            widgetWindow.orderOut(nil)
        } else {
            widgetWindow.orderFrontRegardless()
        }
    }
    
    // Public method to hide widget from WidgetView
    func hideWidget() {
        widgetWindow.orderOut(nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func setupWidgetWindow() {
        let widgetView = WidgetView(
            onTap: { [weak self] in
                self?.togglePopup()
            },
            onHide: { [weak self] in
                self?.hideWidget()
            }
        )
        
        let hostingView = NSHostingView(rootView: widgetView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 80)
        
        widgetWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        widgetWindow.contentView = hostingView
        widgetWindow.isOpaque = false
        widgetWindow.backgroundColor = .clear
        widgetWindow.level = .floating
        widgetWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        widgetWindow.isMovableByWindowBackground = true
        widgetWindow.hasShadow = true
        
        // Position at top-right corner
        positionWidgetWindow()
        
        widgetWindow.orderFrontRegardless()
    }
    
    private func positionWidgetWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = widgetWindow.frame
        
        let x = screenFrame.maxX - windowFrame.width - 20
        let y = screenFrame.maxY - windowFrame.height - 20
        
        widgetWindow.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func setupPopupWindow() {
        let popupView = PopupView(onClose: { [weak self] in
            self?.hidePopup()
        })
        
        let hostingView = NSHostingView(rootView: popupView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 500)
        
        // Use custom KeyableWindow instead of NSPanel
        popupWindow = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 500),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        popupWindow.contentView = hostingView
        popupWindow.isOpaque = false
        popupWindow.backgroundColor = .clear
        popupWindow.level = .floating
        popupWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        popupWindow.hasShadow = true
        popupWindow.isMovableByWindowBackground = false
        
        popupWindow.orderOut(nil)
    }
    
    private func setupEventMonitor() {
        // Global monitor for clicks outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.popupWindow.isVisible else { return }
            
            let clickLocation = NSEvent.mouseLocation
            if !self.popupWindow.frame.contains(clickLocation) && !self.widgetWindow.frame.contains(clickLocation) {
                self.hidePopup()
            }
        }
        
        // Local monitor for clicks inside to maintain focus
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            if self.popupWindow.isVisible {
                self.popupWindow.makeKey()
            }
            return event
        }
    }
    
    func togglePopup() {
        if popupWindow.isVisible {
            hidePopup()
        } else {
            showPopup()
        }
    }
    
    func showPopup() {
        // Position popup below widget
        let widgetFrame = widgetWindow.frame
        let popupFrame = popupWindow.frame
        
        let x = widgetFrame.origin.x + widgetFrame.width - popupFrame.width
        let y = widgetFrame.origin.y - popupFrame.height - 10
        
        popupWindow.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Animate appearance
        popupWindow.alphaValue = 0
        popupWindow.orderFrontRegardless()
        
        // Make key window to accept keyboard input
        popupWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Make the content view first responder
        if let contentView = popupWindow.contentView {
            popupWindow.makeFirstResponder(contentView)
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.popupWindow.animator().alphaValue = 1
        }
    }
    
    func hidePopup() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.popupWindow.animator().alphaValue = 0
        }, completionHandler: {
            self.popupWindow.orderOut(nil)
        })
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
