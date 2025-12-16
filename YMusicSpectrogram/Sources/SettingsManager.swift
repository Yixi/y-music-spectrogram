//
//  SettingsManager.swift
//  YMusicSpectrogram
//
//  Manages user preferences for the spectrum visualizer
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // Settings keys
    private enum Keys {
        static let bandCount = "spectrumBandCount"
        static let colorScheme = "spectrumColorScheme"
        static let baseColorHue = "baseColorHue"
        static let baseColorSaturation = "baseColorSaturation"
        static let baseColorBrightness = "baseColorBrightness"
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
    
    // Color scheme options
    enum ColorScheme: String, CaseIterable {
        case rainbow = "Rainbow"
        case greenToRed = "Green to Red"
        case blueToRed = "Blue to Red"
        case monochrome = "Monochrome"
        case custom = "Custom"
    }
    
    private init() {
        // Load saved settings or use defaults
        self.bandCount = UserDefaults.standard.object(forKey: Keys.bandCount) as? Int ?? 32
        
        let colorSchemeRaw = UserDefaults.standard.string(forKey: Keys.colorScheme) ?? ColorScheme.greenToRed.rawValue
        self.colorScheme = ColorScheme(rawValue: colorSchemeRaw) ?? .greenToRed
        
        self.baseColorHue = UserDefaults.standard.object(forKey: Keys.baseColorHue) as? Double ?? 0.35
        self.baseColorSaturation = UserDefaults.standard.object(forKey: Keys.baseColorSaturation) as? Double ?? 0.8
        self.baseColorBrightness = UserDefaults.standard.object(forKey: Keys.baseColorBrightness) as? Double ?? 0.9
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
