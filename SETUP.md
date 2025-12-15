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

1. **Microphone Permission**: 
   - A system dialog will appear requesting microphone access
   - Click "OK" to allow audio capture
   - You can manage this later in System Preferences > Security & Privacy > Privacy > Microphone

2. **Menu Bar Display**:
   - Look for the spectrum visualizer in your menu bar (top-right area)
   - The visualizer shows 32 animated bars representing audio frequencies

3. **Controls**:
   - Right-click the menu bar item to access:
     - "Start Capture" - Begin audio capture
     - "Stop Capture" - Pause audio capture  
     - "Quit" - Exit the application

## Capturing System Audio

⚠️ **Important**: The default implementation captures microphone input. To capture system audio (music playback), follow these steps:

### Using BlackHole (Free, Recommended)

1. **Install BlackHole**:
   ```bash
   # Using Homebrew
   brew install blackhole-2ch
   
   # Or download from GitHub
   # https://github.com/ExistentialAudio/BlackHole
   ```

2. **Configure Multi-Output Device**:
   - Open "Audio MIDI Setup" (in Applications > Utilities)
   - Click the "+" button at bottom-left
   - Select "Create Multi-Output Device"
   - Check both your speakers/headphones AND BlackHole 2ch
   - Right-click the Multi-Output Device and select "Use This Device For Sound Output"

3. **Configure Application**:
   - In System Preferences > Sound > Input
   - Select "BlackHole 2ch" as the input device
   - Launch Y Music Spectrogram

4. **Start Capturing**:
   - Play music in any application
   - Right-click the menu bar item and select "Start Capture"
   - You should see the spectrum visualizer responding to your music!

### Using ScreenCaptureKit (macOS 13+, Advanced)

This requires code modifications to use Apple's ScreenCaptureKit API:

- Captures audio from specific applications
- Requires Screen Recording permission
- See `AudioCaptureManager.swift` comments for implementation notes

### Using Loopback (Commercial)

- Purchase and install [Loopback](https://rogueamoeba.com/loopback/) from Rogue Amoeba
- Create a virtual audio device routing system audio to an input
- More flexible but requires a paid license

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
1. Verify microphone permission is granted
   - System Preferences > Security & Privacy > Privacy > Microphone
2. Click "Start Capture" in the menu
3. Check input device in System Preferences > Sound > Input
4. Make some noise near your microphone or play audio

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

**Symptoms**: "Operation not permitted" errors

**Solutions**:
1. Grant microphone access in System Preferences
2. For ScreenCaptureKit: Grant Screen Recording permission
3. Restart the application after granting permissions

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
