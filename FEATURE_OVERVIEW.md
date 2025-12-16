# Feature Overview: Settings & Customization

## Quick Start

### Opening Settings

**Method 1**: Right-click on the spectrum visualization in the menu bar
```
┌─────────────────────────────────┐
│  [▂▃▅▆▇▆▅▃▂] ← Right-click here │
└─────────────────────────────────┘
         ↓
┌──────────────────────┐
│  Settings...     ⌘,  │
│  ──────────────────  │
│  Start Capture       │
│  Stop Capture        │
│  ──────────────────  │
│  Quit            ⌘Q  │
└──────────────────────┘
```

**Method 2**: Keyboard shortcut `⌘,` (Command + Comma)

## Settings Window Layout

```
┌────────────────────────────────────────────────┐
│  Spectrum Settings                       [×]   │
├────────────────────────────────────────────────┤
│                                                │
│  Number of Spectrum Bars                       │
│  ━━━━━━━━━━━━●━━━━━━━━━━━━━━  32             │
│  More bars = more detail (uses more CPU)       │
│                                                │
│  ──────────────────────────────────────────    │
│                                                │
│  Color Scheme                                  │
│  ┌────────┬────────┬────────┬────────┬──────┐ │
│  │Rainbow │Green to│Blue to │Monochr.│Custom│ │
│  │        │  Red   │  Red   │        │      │ │
│  └────────┴────────┴────────┴────────┴──────┘ │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │  Custom Color                             │ │
│  │  Hue:        ━━━━━━●━━━━━━━━━  🔵       │ │
│  │  Saturation: ━━━━━━━━●━━━━━━━━           │ │
│  │  Brightness: ━━━━━━━━━●━━━━━━            │ │
│  └──────────────────────────────────────────┘ │
│                                                │
│  ──────────────────────────────────────────    │
│                                                │
│  Info                                          │
│  Changes are applied immediately               │
│  Settings are saved automatically              │
│                                                │
└────────────────────────────────────────────────┘
```

## Color Schemes

### 1. Rainbow 🌈
```
Bar Index:  0    8    16   24   32
Color:      Red  Orange Yellow Green Blue
            🟥 → 🟧 → 🟨 → 🟩 → 🟦
```
Full spectrum from red to blue across all bars.

### 2. Green to Red (Default) 🎵
```
Bar Index:  0    8    16   24   32
Frequency:  Low        Mid        High
Color:      Green  Yellow Orange Red
            🟩 → 🟡 → 🟠 → 🟥
```
Classic audio visualization: bass = green, treble = red.

### 3. Blue to Red 🎨
```
Bar Index:  0    8    16   24   32
Color:      Blue   Cyan  Green Yellow Red
            🟦 → 🩵 → 🟩 → 🟡 → 🟥
```
Cool to warm color transition.

### 4. Monochrome 🔵
```
All bars use the same hue, varying only in brightness:
Low magnitude:  ◽ (dim)
High magnitude: 🟦 (bright)
```

### 5. Custom 🎨
```
You choose the base color (hue, saturation, brightness).
Bars vary slightly in hue for depth.
```

## Band Count Examples

### 16 Bars (Low Detail)
```
┌──────────────────────────────────┐
│ ▂▃▅▇▆▅▃▂▁▂▃▅▆▅▃▂                 │
└──────────────────────────────────┘
Pros: Lower CPU usage, cleaner look
Cons: Less frequency detail
```

### 32 Bars (Default, Balanced)
```
┌──────────────────────────────────┐
│ ▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃ │
└──────────────────────────────────┘
Pros: Good detail, good performance
Cons: None (recommended)
```

### 64 Bars (High Detail)
```
┌──────────────────────────────────┐
│ ▁▂▂▃▃▄▄▅▅▆▆▇▇▆▆▅▅▄▄▃▃▂▂▁▁▂▂▃▃▄▄▅ │
└──────────────────────────────────┘
Pros: Maximum frequency detail
Cons: Higher CPU usage, busier look
```

## Usage Workflow

### Basic Setup
```
1. Launch App
   ↓
2. Grant Permissions (screen recording)
   ↓
3. Audio visualization appears in menu bar
   ↓
4. Works with default settings (32 bars, green-to-red)
```

### Customizing Colors
```
1. Right-click menu bar → Settings
   ↓
2. Select a color scheme
   ↓
3. Colors update immediately
   ↓
4. Close settings (auto-saved)
```

### Adjusting Detail Level
```
1. Open Settings
   ↓
2. Move "Number of Spectrum Bars" slider
   ↓
3. Watch visualization update in real-time
   ↓
4. Find balance between detail and performance
```

### Creating Custom Color
```
1. Open Settings
   ↓
2. Select "Custom" color scheme
   ↓
3. Adjust Hue slider (pick base color)
   ↓
4. Adjust Saturation (color intensity)
   ↓
5. Adjust Brightness (overall lightness)
   ↓
6. Preview circle shows current color
   ↓
7. Settings saved automatically
```

## Performance Guide

### Recommended Settings by Use Case

#### Battery Saver
- Band Count: 16-20
- Color Scheme: Any (negligible impact)
- CPU Usage: ~2%

#### Balanced (Default)
- Band Count: 28-32
- Color Scheme: Green to Red
- CPU Usage: ~3-4%

#### High Detail
- Band Count: 44-52
- Color Scheme: Any
- CPU Usage: ~5-6%

#### Maximum Quality
- Band Count: 64
- Color Scheme: Rainbow or Custom
- CPU Usage: ~7-8%

## Technical Details

### Settings Storage
```
Settings Location:
~/Library/Preferences/com.yixi.YMusicSpectrogram.plist

Stored Values:
- spectrumBandCount (Int, 8-64)
- spectrumColorScheme (String)
- baseColorHue (Double, 0-1)
- baseColorSaturation (Double, 0-1)
- baseColorBrightness (Double, 0-1)
```

### Update Mechanism
```
User Action
    ↓
SettingsManager (@Published property)
    ↓
SwiftUI Automatic Update
    ↓
SpectrumAnalyzer / SpectrumVisualizerView
    ↓
Visual Update in Menu Bar
```

### Thread Safety
All settings updates are dispatched to the main thread:
- `updateBandCount()` uses `DispatchQueue.main.async`
- `@Published` properties automatically update on main thread
- No risk of UI updates from background threads

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘,       | Open Settings |
| ⌘Q       | Quit App |
| ⌘W       | Close Settings Window |

## Tips & Tricks

### Tip 1: Find Your Perfect Look
Try each color scheme to see which you prefer. Rainbow and Custom offer the most visual variety.

### Tip 2: Match Your Workflow
- **Focus mode**: Lower bar count (16-24), monochrome
- **Music production**: Higher bar count (48-64), green-to-red
- **Casual listening**: Default (32 bars, any color scheme)

### Tip 3: Custom Colors
For a cohesive desktop:
1. Pick a color from your wallpaper
2. Set Custom color scheme
3. Match hue to wallpaper
4. Adjust saturation/brightness to taste

### Tip 4: Quick Toggle
The settings window can stay open while you work. Changes apply instantly, so you can experiment freely.

## Troubleshooting

### Settings Won't Save
1. Check macOS System Settings → Privacy & Security
2. Ensure app has necessary permissions
3. Try resetting: Delete `~/Library/Preferences/com.yixi.YMusicSpectrogram.plist`

### Performance Issues
1. Lower band count to 16-24
2. Close other heavy applications
3. Check Activity Monitor for CPU usage

### Colors Look Wrong
1. Verify correct color scheme is selected
2. For custom colors, check HSB sliders aren't at extremes
3. Try switching to a preset scheme first

### Settings Window Won't Open
1. Try keyboard shortcut ⌘,
2. Check if window is hidden behind others
3. Restart the application

## Examples

### Example 1: Minimal Setup
```
Settings:
- Band Count: 16
- Color Scheme: Monochrome
- Hue: 0.0 (red)
- Saturation: 0.7
- Brightness: 0.8

Result: Clean, simple red bars. Perfect for focus.
```

### Example 2: Maximum Detail
```
Settings:
- Band Count: 64
- Color Scheme: Rainbow

Result: Highly detailed spectrum with full color range.
Perfect for music production or analysis.
```

### Example 3: Balanced Custom
```
Settings:
- Band Count: 32
- Color Scheme: Custom
- Hue: 0.55 (blue)
- Saturation: 0.85
- Brightness: 0.90

Result: Beautiful blue-themed visualization with good detail.
Perfect for matching a blue desktop theme.
```

## Conclusion

The settings system provides extensive customization while maintaining simplicity. All settings are persistent and changes apply immediately. Experiment to find what works best for your workflow and aesthetic preferences!

For more technical details, see:
- `SETTINGS_GUIDE.md` - Comprehensive technical guide
- `IMPLEMENTATION_SUMMARY.md` - Implementation details
- `ARCHITECTURE.md` - System architecture
