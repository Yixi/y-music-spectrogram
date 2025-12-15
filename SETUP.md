# Setup Guide for Y Music Spectrogram

This guide will help you set up and run the Y Music Spectrogram application on your macOS system.

## System Requirements

- **Operating System**: macOS 13.0 (Ventura) or later
- **Hardware**: Any Mac with Apple Silicon or Intel processor
- **Development Tools**: Xcode 15.0+ (for building from source)

## Quick Start

### Option 1: Build from Source (Recommended)

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Yixi/y-music-spectrogram.git
   cd y-music-spectrogram
   ```

2. **Build with Swift Package Manager**:
   ```bash
   swift build -c release
   ```

3. **Run the Application**:
   ```bash
   .build/release/YMusicSpectrogram
   ```

4. **Grant Permissions**:
   - When prompted, click "OK" to grant microphone access
   - The app will appear in your menu bar

### Option 2: Build with Xcode

1. **Generate Xcode Project**:
   ```bash
   swift package generate-xcodeproj
   open YMusicSpectrogram.xcodeproj
   ```

2. **Configure Signing**:
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your development team

3. **Build and Run**:
   - Press ⌘R or click the Play button

## First Launch

When you first launch the application:

1. **Screen Recording Permission** (for system audio capture): 
   - A system dialog will appear requesting Screen Recording permission
   - Click "Open System Settings" or go to System Settings > Privacy & Security > Screen Recording
   - Check the box next to "YMusicSpectrogram"
   - **Important**: Quit and restart the app for the permission to take effect
   - This permission allows the app to capture system audio using ScreenCaptureKit

2. **Menu Bar Display**:
   - Look for the spectrum visualizer in your menu bar (top-right area)
   - The visualizer shows 32 animated bars representing audio frequencies

3. **Controls**:
   - Right-click the menu bar item to access:
     - "Start Capture" - Begin audio capture
     - "Stop Capture" - Pause audio capture  
     - "Quit" - Exit the application

4. **Start Capturing**:
   - Play any audio on your Mac (music, videos, games, etc.)
   - The visualizer will respond to ALL system audio output!

## System Audio Capture

✅ **Native System Audio Capture**: This application uses **ScreenCaptureKit** to capture system audio directly!

### How It Works

The app uses Apple's ScreenCaptureKit API (macOS 13+) to capture all system audio:
- **No virtual audio drivers needed** - works out of the box
- **Captures everything** - music, videos, games, notifications, etc.
- **High quality** - 48kHz stereo audio capture
- **Low latency** - real-time visualization

### Grant Screen Recording Permission

1. Launch Y Music Spectrogram
2. When prompted, click "Open System Settings"
3. In Privacy & Security > Screen Recording, enable the app
4. Quit and restart the app
5. Click "Start Capture" and play any audio!

**Note**: The app only captures audio - it never actually records your screen. Screen Recording permission is required by macOS for audio capture APIs.

### Fallback Mode

If you don't grant screen recording permission:
- The app automatically falls back to **microphone input**
- Play audio near your microphone, or
- Optionally use BlackHole for audio routing (see below)

### Alternative: BlackHole (Optional)

If you prefer not to grant screen recording permission, you can use BlackHole:

1. **Install BlackHole**:
   ```bash
   brew install blackhole-2ch
   ```

2. **Configure Audio MIDI Setup**:
   - Open "Audio MIDI Setup" (in Applications > Utilities)
   - Create a Multi-Output Device with your speakers + BlackHole
   - Set it as your sound output
   - App will capture audio via microphone mode

### Using Loopback (Commercial)

- Professional solution from [Rogue Amoeba](https://rogueamoeba.com/loopback/)
- More advanced audio routing capabilities
- Paid software but very flexible

## Troubleshooting

### App Not Appearing in Menu Bar

**Symptoms**: Application launches but no icon appears in menu bar

**Solutions**:
1. Check if LSUIElement is properly set in Info.plist
2. Look in Activity Monitor - ensure app is running
3. Try logging out and back in
4. Check Console.app for error messages

### No Audio Visualization

**Symptoms**: App is running but bars don't move

**Solutions**:
1. Verify Screen Recording permission is granted
   - System Settings > Privacy & Security > Screen Recording
   - Enable YMusicSpectrogram
2. **Quit and restart** the app after granting permission
3. Click "Start Capture" in the menu
4. Play any audio on your Mac (music, videos, etc.)
5. Check Console.app for error messages if still not working

### Build Fails

**Symptoms**: `swift build` fails with errors

**Solutions**:
1. Ensure you're on macOS (won't build on Linux/Windows)
2. Check Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```
3. Update to latest Xcode version
4. Clean build folder:
   ```bash
   swift package clean
   rm -rf .build
   ```

### Permission Denied

**Symptoms**: "Operation not permitted" errors or "Screen recording permission denied"

**Solutions**:
1. Grant Screen Recording permission in System Settings
   - Privacy & Security > Screen Recording
   - Check the box for YMusicSpectrogram
2. Quit and restart the app (permission requires app restart)
3. If you prefer not to grant this permission, the app will fall back to microphone mode
4. For microphone fallback: Grant microphone access if prompted

### High CPU Usage

**Symptoms**: Fan spinning, high CPU usage

**Solutions**:
1. Stop capture when not needed (right-click menu)
2. Adjust FFT size in SpectrumAnalyzer.swift (reduce from 2048 to 1024)
3. Increase smoothing factor for less frequent updates

## Advanced Configuration

### Customizing Visualization

Edit `SpectrumAnalyzer.swift`:

```swift
// Change number of frequency bands
private let numberOfBands = 64  // Default: 32

// Adjust smoothing (0.0 = instant, 1.0 = very smooth)
private let smoothingFactor: Float = 0.85  // Default: 0.7

// Change FFT size (larger = more frequency resolution, more CPU)
private let fftSize: Int = 4096  // Default: 2048
```

### Customizing Colors

Edit `SpectrumVisualizerView.swift`:

```swift
private var barColor: Color {
    // Customize your color scheme
    if magnitude > 0.7 {
        return Color.purple  // Change high intensity color
    } else if magnitude > 0.4 {
        return Color.blue    // Change medium intensity color
    } else {
        return Color.cyan    // Change low intensity color
    }
}
```

### Adjusting Bar Count and Spacing

Edit `SpectrumVisualizerView.swift`:

```swift
private let barSpacing: CGFloat = 2.0  // Default: 1.5
```

## Performance Tips

1. **Reduce Band Count**: Fewer bands = less processing
2. **Increase Buffer Size**: Larger buffers = less frequent updates
3. **Optimize Smoothing**: Higher smoothing = less CPU for animations
4. **Use Release Build**: Always use `-c release` for better performance

## Uninstalling

To completely remove the application:

```bash
# Remove the application
rm -rf /path/to/YMusicSpectrogram.app

# Remove build artifacts
cd /path/to/y-music-spectrogram
swift package clean
rm -rf .build
```

## Getting Help

If you encounter issues:

1. **Check Logs**: Open Console.app and filter for "YMusicSpectrogram"
2. **Verify Setup**: Run through this guide step-by-step
3. **Report Issues**: Open an issue on GitHub with:
   - macOS version (`sw_vers`)
   - Xcode version (`xcodebuild -version`)
   - Complete error message
   - Steps to reproduce

## Next Steps

- Read [BUILD.md](BUILD.md) for detailed build instructions
- Read [README.md](README.md) for technical architecture details
- Customize the visualization to your liking
- Consider contributing improvements!

## Tips for Best Experience

1. **For Music Visualization**:
   - Use BlackHole for system audio capture
   - Set up Multi-Output device to hear audio while capturing
   - Start capture before playing music

2. **For Microphone Input**:
   - Speak or make sounds near your microphone
   - Adjust microphone input level in System Preferences if needed
   - Works great for analyzing voice, instruments, or ambient sound

3. **Performance**:
   - Close the app when not in use (Quit from menu)
   - Use "Stop Capture" to pause processing while keeping app running
   - Build with release configuration for best performance

Enjoy your visual music experience! 🎵🎨
