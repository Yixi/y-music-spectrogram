# Build Instructions

This document provides detailed instructions for building and running the Y Music Spectrogram application.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later with Command Line Tools
- Swift 5.9 or later

## Method 1: Swift Package Manager (Recommended for Development)

### Building

```bash
# Navigate to project directory
cd y-music-spectrogram

# Clean previous builds (if any)
swift package clean

# Build in debug mode
swift build

# Build in release mode (optimized)
swift build -c release
```

### Running

```bash
# Run debug build
swift run

# Run release build
.build/release/YMusicSpectrogram
```

### Development

```bash
# Generate Xcode project for development
swift package generate-xcodeproj

# Open in Xcode
open YMusicSpectrogram.xcodeproj
```

## Method 2: Xcode Project

If you prefer to use Xcode directly:

1. **Create New Xcode Project**:
   - Open Xcode
   - File > New > Project
   - Choose "App" under macOS
   - Product Name: "YMusicSpectrogram"
   - Interface: SwiftUI
   - Language: Swift

2. **Import Source Files**:
   - Drag all files from `YMusicSpectrogram/Sources/` into your Xcode project
   - Copy `YMusicSpectrogram/Resources/Info.plist` to your project

3. **Configure Project Settings**:
   - Select your project in the navigator
   - Under "Signing & Capabilities":
     - Enable "Audio Input"
     - Add "App Sandbox" capability
   - Under "Info":
     - Add "Privacy - Microphone Usage Description"

4. **Build and Run**:
   - Select your Mac as the target device
   - Press ⌘R to build and run

## Method 3: Creating a Standalone App Bundle

To create a distributable .app bundle:

```bash
# Build release version
swift build -c release

# Create app bundle structure
mkdir -p YMusicSpectrogram.app/Contents/MacOS
mkdir -p YMusicSpectrogram.app/Contents/Resources

# Copy executable
cp .build/release/YMusicSpectrogram YMusicSpectrogram.app/Contents/MacOS/

# Copy Info.plist
cp YMusicSpectrogram/Resources/Info.plist YMusicSpectrogram.app/Contents/

# Make executable
chmod +x YMusicSpectrogram.app/Contents/MacOS/YMusicSpectrogram

# Run the app
open YMusicSpectrogram.app
```

## Configuration

### Info.plist Setup

Ensure your Info.plist contains these critical keys:

```xml
<key>LSUIElement</key>
<true/>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to capture audio for spectrum visualization.</string>
```

### Entitlements

For sandboxed apps (required for App Store distribution), create an entitlements file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

## Troubleshooting Build Issues

### Issue: "Cannot find 'AVAudioEngine' in scope"

**Solution**: Ensure you're targeting macOS 13.0 or later in your build settings.

```bash
# Check Swift version
swift --version

# Should be 5.9 or later
```

### Issue: "Library not loaded: @rpath/libswiftCore.dylib"

**Solution**: The Swift runtime needs to be embedded in your app bundle.

In Xcode:
- Build Settings > "Always Embed Swift Standard Libraries" > Yes

### Issue: Build fails with SPM

**Solution**: Clean build folder and reset package cache

```bash
swift package clean
swift package reset
rm -rf .build
swift build
```

### Issue: App doesn't appear in menu bar

**Solution**: 
1. Check that Info.plist is properly loaded
2. Verify LSUIElement is set to YES (true)
3. Check Console.app for error messages

## Development Tips

### Live Preview in Xcode

The `SpectrumVisualizerView` includes a preview provider for development:

```swift
// In Xcode, open SpectrumVisualizerView.swift
// Click "Resume" in the preview panel (right side)
// You can see the UI without running the full app
```

### Debugging

To see debug output:

```bash
# Run with debug output
swift run 2>&1 | grep -E "🎤|❌|⏹️|ℹ️"
```

Look for these log markers:
- 🎤 Audio capture started
- ⏹️ Audio capture stopped
- ❌ Errors
- ℹ️ Information

### Testing Without Microphone

To test the UI without audio input, modify `SpectrumAnalyzer`:

```swift
// Add this method for testing
func simulateRandomSpectrum() {
    DispatchQueue.main.async {
        self.spectrumBands = (0..<32).map { _ in Float.random(in: 0...1) }
    }
}
```

## Performance Profiling

To check performance:

```bash
# Build with debug symbols
swift build -c release -Xswiftc -g

# Run with Instruments
instruments -t "Time Profiler" .build/release/YMusicSpectrogram
```

## Code Signing (For Distribution)

### Development Signing

```bash
# Sign the app
codesign --force --deep --sign "Apple Development" YMusicSpectrogram.app
```

### Distribution Signing

```bash
# Sign for distribution
codesign --force --deep --sign "Developer ID Application: Your Name (TEAMID)" YMusicSpectrogram.app

# Verify signature
codesign --verify --verbose YMusicSpectrogram.app
```

## Creating a DMG for Distribution

```bash
# Create DMG
hdiutil create -volname "Y Music Spectrogram" -srcfolder YMusicSpectrogram.app -ov -format UDZO YMusicSpectrogram.dmg
```

## Next Steps

After building successfully:

1. Grant microphone permissions when prompted
2. Check the menu bar for the spectrum visualizer
3. Right-click to access controls
4. For system audio capture, see the main README.md

## Getting Help

If you encounter build issues:

1. Check the Xcode build log
2. Run `swift build --verbose` for detailed output
3. Check Console.app for runtime errors
4. Open an issue on GitHub with:
   - macOS version
   - Xcode version
   - Complete error message
   - Build command used
