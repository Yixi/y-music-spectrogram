//
//  MenuBarController.swift
//  YMusicSpectrogram
//
//  Manages the menu bar status item and integrates with the audio system
//

import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    private let audioCaptureManager: AudioCaptureManager
    private let spectrumAnalyzer: SpectrumAnalyzer
    private let visualizerView: SpectrumVisualizerView
    private var hostingView: NSHostingView<SpectrumVisualizerView>?
    private var statusBarButton: NSStatusBarButton?
    
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
    
    func setupStatusBarButton(_ button: NSStatusBarButton) {
        self.statusBarButton = button
        
        // Create hosting view for SwiftUI content
        hostingView = NSHostingView(rootView: visualizerView)
        hostingView?.frame = NSRect(x: 0, y: 0, width: 150, height: 22)
        
        // Add hosting view to button
        if let hostingView = hostingView {
            button.addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
        }
        
        // Add menu
        let menu = NSMenu()
        
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
        
        button.menu = menu
    }
    
    @objc func startCapture() {
        audioCaptureManager.startCapture()
    }
    
    @objc func stopCapture() {
        audioCaptureManager.stopCapture()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
