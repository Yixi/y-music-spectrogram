//
//  YMusicSpectrogramApp.swift
//  YMusicSpectrogram
//
//  A macOS menu bar application that displays real-time audio spectrum visualization
//

import SwiftUI
import AppKit

@main
struct YMusicSpectrogramApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock (LSUIElement is set in Info.plist)
        NSApp.setActivationPolicy(.accessory)
        
        // Create menu bar controller
        menuBarController = MenuBarController()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: 150)
        
        if let button = statusItem?.button {
            // The button will be replaced by custom view
            button.title = ""
            menuBarController?.setupStatusBarButton(button)
        }
    }
}
