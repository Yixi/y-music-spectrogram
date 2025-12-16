# Settings Guide

This document describes the new settings system for Y Music Spectrogram.

## Features

### 1. Settings Window

The application now includes a settings window that allows users to customize the spectrum visualization.

#### Opening Settings

- **Menu Bar**: Right-click on the spectrum visualization in the menu bar and select "Settings..."
- **Keyboard Shortcut**: ⌘, (Command + Comma)

### 2. Customizable Options

#### Number of Spectrum Bars

- **Range**: 8 to 64 bars
- **Step**: 4 bars at a time
- **Default**: 32 bars
- **Effect**: More bars = more detail but uses more CPU

#### Color Schemes

Five color schemes are available:

1. **Rainbow**: Full spectrum rainbow colors across all bars
2. **Green to Red**: Classic frequency visualization (default)
   - Low frequencies (bass) = Green
   - High frequencies (treble) = Red
3. **Blue to Red**: Cool to warm color transition
   - Low frequencies = Blue
   - High frequencies = Red
4. **Monochrome**: Single base color with varying brightness
   - Allows customization of the base color
5. **Custom**: User-defined base color with slight hue variation
   - Allows full customization of hue, saturation, and brightness

#### Custom Color Controls

When "Monochrome" or "Custom" color scheme is selected, additional controls appear:

- **Hue**: Color tone (0.0 = Red, 0.33 = Green, 0.66 = Blue, etc.)
- **Saturation**: Color intensity (0.0 = Gray, 1.0 = Vivid)
- **Brightness**: Color lightness (0.0 = Black, 1.0 = Bright)

### 3. Settings Persistence

All settings are automatically saved using macOS UserDefaults and persist across app restarts:

- Number of spectrum bars
- Selected color scheme
- Custom color values (hue, saturation, brightness)

Changes are applied immediately to the visualization.

## Technical Implementation

### Architecture

The settings system follows a clean architecture pattern:

```
┌─────────────────────────────────────────┐
│         SettingsManager (Singleton)      │
│  - Manages UserDefaults                  │
│  - Publishes settings changes           │
│  - Provides color calculation methods   │
└─────────────────────────────────────────┘
              │
              ├─────────────────────────────┐
              ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│    SettingsView      │      │ SpectrumAnalyzer     │
│  (Settings Window)   │      │  (FFT Processing)    │
│  - UI Controls       │      │  - Dynamic bands     │
│  - Color pickers     │      │  - Band updates      │
└──────────────────────┘      └──────────────────────┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │ SpectrumVisualizerView   │
                          │  (Menu Bar Display)      │
                          │  - Uses SettingsManager  │
                          │  - Color from settings   │
                          └──────────────────────────┘
```

### Key Components

#### 1. SettingsManager

- **Type**: Singleton ObservableObject
- **Location**: `YMusicSpectrogram/Sources/SettingsManager.swift`
- **Responsibilities**:
  - Store and retrieve user preferences
  - Publish changes for reactive UI updates
  - Calculate bar colors based on selected scheme
  - Provide peak colors based on magnitude

**Key Methods**:
```swift
func getBarColor(index: Int, totalBars: Int, magnitude: CGFloat) -> Color
func getPeakColor(magnitude: CGFloat) -> Color
```

#### 2. SettingsView

- **Type**: SwiftUI View
- **Location**: `YMusicSpectrogram/Sources/SettingsView.swift`
- **Responsibilities**:
  - Display settings UI
  - Handle user interactions
  - Update SettingsManager and SpectrumAnalyzer

**Features**:
- Slider for band count with live preview
- Segmented picker for color schemes
- Conditional color controls for custom schemes
- Info section with helpful tips

#### 3. MenuBarController Updates

- **Location**: `YMusicSpectrogram/Sources/MenuBarController.swift`
- **Changes**:
  - Added `settingsWindow` property
  - Added `openSettings()` method
  - Updated menu to include "Settings..." item
  - Window lifecycle management

#### 4. SpectrumAnalyzer Updates

- **Location**: `YMusicSpectrogram/Sources/SpectrumAnalyzer.swift`
- **Changes**:
  - Changed `numberOfBands` from `let` to `var`
  - Loads initial band count from SettingsManager
  - Added `updateBandCount(_ count: Int)` method
  - Dynamically recomputes frequency band boundaries

#### 5. SpectrumVisualizerView Updates

- **Location**: `YMusicSpectrogram/Sources/SpectrumVisualizerView.swift`
- **Changes**:
  - SpectrumBar now uses SettingsManager for colors
  - Removed hardcoded color calculations
  - Colors update reactively when settings change

## Usage Examples

### Example 1: Changing Band Count

1. Open Settings (⌘,)
2. Adjust the "Number of Spectrum Bars" slider
3. Observe the menu bar visualization update in real-time
4. Close settings - your preference is saved

### Example 2: Switching to Rainbow Colors

1. Open Settings
2. Select "Rainbow" from the color scheme picker
3. The spectrum immediately changes to rainbow colors
4. Your choice is remembered on next app launch

### Example 3: Creating a Custom Blue Theme

1. Open Settings
2. Select "Custom" color scheme
3. Adjust Hue slider to ~0.6 (blue region)
4. Adjust Saturation to ~0.9 (vivid)
5. Adjust Brightness to ~0.8 (bright but not blinding)
6. Watch the spectrum update with your custom blue theme

## Performance Considerations

### Band Count vs Performance

| Band Count | CPU Usage | Visual Detail | Recommended For |
|------------|-----------|---------------|-----------------|
| 8-16       | Very Low  | Low           | Battery saving, minimal detail |
| 20-32      | Low       | Medium        | Balanced (default) |
| 36-48      | Medium    | High          | Desktop use, more detail |
| 52-64      | Higher    | Very High     | High-end systems, maximum detail |

**Note**: The FFT size (4096) remains constant. Band count only affects grouping and display, not the underlying analysis quality.

### Color Scheme Performance

All color schemes have negligible performance impact. The color calculation is done per-frame per-bar, which is very lightweight compared to the FFT processing.

## Troubleshooting

### Settings Not Saving

If your settings aren't persisting:
1. Check macOS System Settings > Privacy & Security
2. Ensure the app has permissions to write to UserDefaults
3. Try resetting settings by quitting the app and deleting: `~/Library/Preferences/com.yixi.YMusicSpectrogram.plist`

### Window Not Opening

If the settings window doesn't open:
1. Try the keyboard shortcut (⌘,) instead of the menu
2. Check if the window is hidden behind other windows
3. Quit and restart the application

### Colors Not Updating

If color changes don't apply immediately:
1. Ensure you're selecting a different color scheme
2. For custom colors, move the sliders more substantially
3. The visualization should update within 1-2 frames (~16-33ms)

## Future Enhancements

Potential additions to the settings system:

1. **Audio Source Selection**: Choose between microphone and system audio
2. **FFT Size Configuration**: Trade off between frequency resolution and latency
3. **Smoothing Controls**: Adjust attack/release parameters
4. **Bar Spacing**: Customize gaps between bars
5. **Peak Indicators**: Optional peak hold markers
6. **Export/Import Settings**: Save and share configurations
7. **Preset Management**: Save multiple custom configurations

## Code Examples

### Adding a New Color Scheme

To add a new color scheme, update `SettingsManager.swift`:

```swift
enum ColorScheme: String, CaseIterable {
    case rainbow = "Rainbow"
    case greenToRed = "Green to Red"
    case blueToRed = "Blue to Red"
    case monochrome = "Monochrome"
    case custom = "Custom"
    case yourNewScheme = "Your New Scheme"  // Add here
}

// Then update getBarColor method:
func getBarColor(index: Int, totalBars: Int, magnitude: CGFloat) -> Color {
    let position = Double(index) / Double(totalBars)
    
    switch colorScheme {
    // ... existing cases ...
    case .yourNewScheme:
        // Your color calculation here
        return Color(hue: yourFormula, saturation: 0.8, brightness: 0.9)
    }
}
```

### Programmatically Changing Settings

```swift
// Get settings manager
let settings = SettingsManager.shared

// Change band count
settings.bandCount = 48

// Change color scheme
settings.colorScheme = .rainbow

// Set custom color
settings.baseColorHue = 0.5
settings.baseColorSaturation = 0.9
settings.baseColorBrightness = 0.8
```

## Conclusion

The settings system provides a clean, user-friendly way to customize the spectrum visualization while maintaining good performance and code organization. All settings are persistent and changes apply immediately without requiring an app restart.
