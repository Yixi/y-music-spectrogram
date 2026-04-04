//
//  SettingsManager.swift
//  YMusicSpectrogram
//
//  Manages user preferences for the spectrum visualizer
//

import Foundation
import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // Settings keys
    private enum Keys {
        static let bandCount = "spectrumBandCount"
        static let colorScheme = "spectrumColorScheme"
        static let baseColorHue = "baseColorHue"
        static let baseColorSaturation = "baseColorSaturation"
        static let baseColorBrightness = "baseColorBrightness"
        static let barSpacing = "barSpacing"
        static let sensitivity = "sensitivity"
        static let launchAtLogin = "launchAtLogin"
    }
    
    // Published properties for reactive UI updates
    @Published var bandCount: Int {
        didSet {
            UserDefaults.standard.set(bandCount, forKey: Keys.bandCount)
        }
    }
    
    @Published var colorScheme: ColorScheme {
        didSet {
            UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme)
        }
    }
    
    @Published var baseColorHue: Double {
        didSet {
            UserDefaults.standard.set(baseColorHue, forKey: Keys.baseColorHue)
        }
    }
    
    @Published var baseColorSaturation: Double {
        didSet {
            UserDefaults.standard.set(baseColorSaturation, forKey: Keys.baseColorSaturation)
        }
    }
    
    @Published var baseColorBrightness: Double {
        didSet {
            UserDefaults.standard.set(baseColorBrightness, forKey: Keys.baseColorBrightness)
        }
    }

    @Published var barSpacing: Double {
        didSet {
            UserDefaults.standard.set(barSpacing, forKey: Keys.barSpacing)
        }
    }

    @Published var sensitivity: Double {
        didSet {
            UserDefaults.standard.set(sensitivity, forKey: Keys.sensitivity)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLoginItem()
        }
    }

    // Color scheme options
    enum ColorScheme: String, CaseIterable {
        case rainbow = "Rainbow"
        case greenToRed = "Green to Red"
        case blueToRed = "Blue to Red"
        case monochrome = "Monochrome"
        case custom = "Custom"

        var displayName: String {
            switch self {
            case .rainbow: return "彩虹"
            case .greenToRed: return "绿→红"
            case .blueToRed: return "蓝→红"
            case .monochrome: return "单色"
            case .custom: return "自定义"
            }
        }
    }
    
    private init() {
        // Load saved settings or use defaults
        self.bandCount = UserDefaults.standard.object(forKey: Keys.bandCount) as? Int ?? 32

        let colorSchemeRaw = UserDefaults.standard.string(forKey: Keys.colorScheme) ?? ColorScheme.greenToRed.rawValue
        self.colorScheme = ColorScheme(rawValue: colorSchemeRaw) ?? .greenToRed

        self.baseColorHue = UserDefaults.standard.object(forKey: Keys.baseColorHue) as? Double ?? 0.35
        self.baseColorSaturation = UserDefaults.standard.object(forKey: Keys.baseColorSaturation) as? Double ?? 0.8
        self.baseColorBrightness = UserDefaults.standard.object(forKey: Keys.baseColorBrightness) as? Double ?? 0.9
        self.barSpacing = UserDefaults.standard.object(forKey: Keys.barSpacing) as? Double ?? 1.0
        self.sensitivity = UserDefaults.standard.object(forKey: Keys.sensitivity) as? Double ?? 1.0
        self.launchAtLogin = UserDefaults.standard.object(forKey: Keys.launchAtLogin) as? Bool ?? false
    }

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("⚠️ Failed to update login item: \(error.localizedDescription)")
        }
    }
    
    // Get color for a specific bar based on current color scheme
    func getBarColor(index: Int, totalBars: Int, magnitude: CGFloat) -> Color {
        let position = Double(index) / Double(totalBars)
        
        switch colorScheme {
        case .rainbow:
            // Full spectrum rainbow
            let hue = position
            return Color(hue: hue, saturation: 0.8, brightness: 0.9)
            
        case .greenToRed:
            // Green (0.35) to Red (0.0)
            let hue = 0.35 - (position * 0.35)
            return Color(hue: hue, saturation: 0.8, brightness: 0.9)
            
        case .blueToRed:
            // Blue (0.6) to Red (0.0)
            let hue = 0.6 - (position * 0.6)
            return Color(hue: hue, saturation: 0.8, brightness: 0.9)
            
        case .monochrome:
            // Single color with varying brightness
            return Color(hue: baseColorHue, saturation: baseColorSaturation, brightness: 0.5 + (position * 0.5))
            
        case .custom:
            // Custom base color with slight hue variation
            let hueVariation = (position - 0.5) * 0.1
            return Color(hue: baseColorHue + hueVariation, saturation: baseColorSaturation, brightness: baseColorBrightness)
        }
    }
    
    // Get peak color based on magnitude
    func getPeakColor(magnitude: CGFloat) -> Color {
        if magnitude > 0.8 {
            return Color(red: 1.0, green: 0.2, blue: 0.2)  // Bright red for high peaks
        } else if magnitude > 0.5 {
            return Color(red: 1.0, green: 0.6, blue: 0.1)  // Orange for medium-high
        } else if magnitude > 0.3 {
            return Color(red: 0.9, green: 0.9, blue: 0.2)  // Yellow for medium
        } else {
            return Color(red: 0.3, green: 0.9, blue: 0.4)  // Green for low
        }
    }
}
