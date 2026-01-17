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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
        
        // Setup notification permissions
        notificationManager.requestPermission()
        
        // Create widget window
        setupWidgetWindow()
        
        // Create popup window (hidden initially)
        setupPopupWindow()
        
        // Monitor for clicks outside popup to close it
        setupEventMonitor()
        
        // Schedule smart water reminders
        notificationManager.scheduleAllNotifications()
    }
    
    private func setupWidgetWindow() {
        let widgetView = WidgetView(onTap: { [weak self] in
            self?.togglePopup()
        })
        
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
    }
}
