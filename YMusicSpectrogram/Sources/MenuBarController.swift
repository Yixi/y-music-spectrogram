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

class MenuBarController: NSObject, NSMenuDelegate {
    private let audioCaptureManager: AudioCaptureManager
    private let spectrumAnalyzer: SpectrumAnalyzer
    private let visualizerView: SpectrumVisualizerView
    private var hostingView: NSView?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var settingsWindowCloseObserver: NSObjectProtocol?
    private var aboutWindowCloseObserver: NSObjectProtocol?

    override init() {
        // Initialize spectrum analyzer
        spectrumAnalyzer = SpectrumAnalyzer()

        // Initialize visualizer view
        visualizerView = SpectrumVisualizerView(spectrumAnalyzer: spectrumAnalyzer)

        // Initialize audio capture manager
        audioCaptureManager = AudioCaptureManager(spectrumAnalyzer: spectrumAnalyzer)

        super.init()

        // Set up error handling callback
        audioCaptureManager.onError = { [weak self] error in
            self?.handleCaptureError(error)
        }

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

        // Create menu with delegate for dynamic updates
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Settings item
        let settingsItem = NSMenuItem(title: "频谱设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "设置")
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Capture control — show only one based on current state
        if audioCaptureManager.isCapturing {
            let stopItem = NSMenuItem(title: "停止捕获", action: #selector(stopCapture), keyEquivalent: "")
            stopItem.target = self
            stopItem.image = NSImage(systemSymbolName: "stop.circle", accessibilityDescription: "停止")
            menu.addItem(stopItem)
        } else {
            let startItem = NSMenuItem(title: "开始捕获", action: #selector(startCapture), keyEquivalent: "")
            startItem.target = self
            startItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: "开始")
            menu.addItem(startItem)
        }

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(title: "关于 Y Music Spectrogram", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "关于")
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc func startCapture() {
        // Restore visualizer view if it was hidden due to error
        hostingView?.isHidden = false
        statusItem?.button?.image = nil
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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "频谱设置"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false

        // Store reference to window
        settingsWindow = window

        // Handle window close to release reference
        settingsWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.settingsWindow = nil
            if let observer = self?.settingsWindowCloseObserver {
                NotificationCenter.default.removeObserver(observer)
                self?.settingsWindowCloseObserver = nil
            }
        }

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAbout() {
        // If about window already exists, just bring it to front
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let aboutView = AboutView()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "关于"
        window.contentView = NSHostingView(rootView: aboutView)
        window.center()
        window.isReleasedWhenClosed = false

        aboutWindow = window

        aboutWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.aboutWindow = nil
            if let observer = self?.aboutWindowCloseObserver {
                NotificationCenter.default.removeObserver(observer)
                self?.aboutWindowCloseObserver = nil
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Error Handling

    private func handleCaptureError(_ error: AudioCaptureManager.CaptureError) {
        switch error {
        case .permissionDenied:
            showPermissionDeniedAlert()
        case .permissionNotDecided:
            showPermissionGuideAlert()
        case .captureFailed:
            showCaptureFailedState()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = "Y Music Spectrogram 需要屏幕录制权限来捕获系统音频。\n\n请在「系统设置 → 隐私与安全性 → 屏幕录制」中允许本应用。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后再说")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showPermissionGuideAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "音频捕获需要权限"
        alert.informativeText = "Y Music Spectrogram 使用屏幕录制权限捕获系统音频进行频谱分析。\n\n授权后即可在菜单栏看到实时音频频谱。"
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func showCaptureFailedState() {
        // Show error icon in menu bar instead of spectrum
        hostingView?.isHidden = true
        statusItem?.button?.image = NSImage(
            systemSymbolName: "exclamationmark.triangle",
            accessibilityDescription: "捕获异常"
        )
    }

    deinit {
        if let observer = settingsWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = aboutWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Y Music Spectrogram")
                .font(.title2)
                .fontWeight(.bold)

            Text("版本 \(bundleVersion)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer().frame(height: 4)

            Text("macOS 菜单栏实时音频频谱可视化")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Copyright © 2026 Yixi")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(width: 300, height: 200)
    }

    private var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
