//
//  MenuBarController.swift
//  YMusicSpectrogram
//
//  Manages the menu bar status item and integrates with the audio system
//

import Cocoa
import SwiftUI

/// Custom NSHostingView subclass that allows mouse events to pass through
class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return nil to let clicks pass through to the parent button
        return nil
    }
}

class MenuBarController: NSObject {
    private let audioCaptureManager: AudioCaptureManager
    private let spectrumAnalyzer: SpectrumAnalyzer
    private let visualizerView: SpectrumVisualizerView
    private var hostingView: NSView?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var windowCloseObserver: NSObjectProtocol?
    
    override init() {
        // Initialize spectrum analyzer
        spectrumAnalyzer = SpectrumAnalyzer()
        
        // Initialize visualizer view
        visualizerView = SpectrumVisualizerView(spectrumAnalyzer: spectrumAnalyzer)
        
        // Initialize audio capture manager
        audioCaptureManager = AudioCaptureManager(spectrumAnalyzer: spectrumAnalyzer)
        
        super.init()
        
        // Auto-start capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startCapture()
        }
    }
    
    func setupStatusItem(_ statusItem: NSStatusItem) {
        self.statusItem = statusItem
        
        guard let button = statusItem.button else { return }
        
        // Create hosting view for SwiftUI content using click-through subclass
        let clickThroughView = ClickThroughHostingView(rootView: visualizerView)
        clickThroughView.frame = NSRect(x: 0, y: 0, width: 150, height: 22)
        hostingView = clickThroughView
        
        // Add hosting view to button
        button.addSubview(clickThroughView)
        clickThroughView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clickThroughView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            clickThroughView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            clickThroughView.topAnchor.constraint(equalTo: button.topAnchor),
            clickThroughView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        
        // Create and set menu on the status item (not on button)
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let startItem = NSMenuItem(title: "Start Capture", action: #selector(startCapture), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
        
        let stopItem = NSMenuItem(title: "Stop Capture", action: #selector(stopCapture), keyEquivalent: "")
        stopItem.target = self
        menu.addItem(stopItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Set menu on status item - this makes it appear on any click
        statusItem.menu = menu
    }
    
    @objc func startCapture() {
        audioCaptureManager.startCapture()
    }
    
    @objc func stopCapture() {
        audioCaptureManager.stopCapture()
    }
    
    @objc func openSettings() {
        // If settings window already exists, just bring it to front
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create settings view
        let settingsView = SettingsView(spectrumAnalyzer: spectrumAnalyzer)
        
        // Create window with hosting view
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Spectrum Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        
        // Store reference to window
        settingsWindow = window
        
        // Handle window close to release reference
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settingsWindow = nil
            if let observer = self?.windowCloseObserver {
                NotificationCenter.default.removeObserver(observer)
                self?.windowCloseObserver = nil
            }
        }
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        // Clean up observer if still present
        if let observer = windowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
