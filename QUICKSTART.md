# Quick Start Guide

Get Y Music Spectrogram running in 5 minutes!

## 1. Prerequisites Check

Before you start, verify you have:
- ✅ macOS 13.0 (Ventura) or later
- ✅ Xcode 15.0 or later (for building)

```bash
# Check macOS version
sw_vers

# Check if Xcode Command Line Tools are installed
xcode-select -p
# If not installed, run: xcode-select --install
```

## 2. Clone and Build

```bash
# Clone the repository
git clone https://github.com/Yixi/y-music-spectrogram.git
cd y-music-spectrogram

# Build the application (release mode for best performance)
swift build -c release

# This will take a minute or two...
```

## 3. Run the Application

```bash
# Run from command line
.build/release/YMusicSpectrogram

# The app will start and appear in your menu bar
# (Look in the top-right corner of your screen)
```

## 4. Grant Permissions

When you first run the app:
1. A dialog will appear asking for **Microphone access**
2. Click **OK** to allow
3. The spectrum visualizer should now appear in your menu bar!

## 5. Start Capturing Audio

1. Right-click the spectrum visualizer in your menu bar
2. Select **"Start Capture"**
3. Make some noise or play music - the bars should start moving!

## What You Should See

In your menu bar, you'll see 32 animated bars:
- 🟢 **Green bars**: Low-intensity audio (quiet sounds, bass)
- 🟡 **Yellow bars**: Medium-intensity audio (normal talking/music)
- 🔴 **Red bars**: High-intensity audio (loud sounds, peaks)

## Capturing System Audio (Music Playback)

By default, the app captures microphone input. To capture actual music playback:

### Option A: Use BlackHole (5 minutes setup)

```bash
# Install BlackHole virtual audio driver
brew install blackhole-2ch

# Configure audio routing
# 1. Open "Audio MIDI Setup" app (in Applications/Utilities)
# 2. Click the + button → "Create Multi-Output Device"
# 3. Check BOTH your speakers AND BlackHole 2ch
# 4. Right-click Multi-Output → "Use This Device For Sound Output"
# 5. In System Preferences → Sound → Input, select "BlackHole 2ch"
# 6. Restart Y Music Spectrogram
```

Now play music in any app - the visualizer will respond to it!

### Option B: Keep Using Microphone

Just play music out loud near your computer's microphone. Works great for testing!

## Controls

Right-click the menu bar item to access:
- **Start Capture** - Begin visualizing audio
- **Stop Capture** - Pause visualization (saves CPU)
- **Quit** - Exit the application

## Troubleshooting

### "No module named AVFoundation" error when building
You're probably not on macOS. This app only builds and runs on macOS.

### App builds but doesn't appear in menu bar
Check Activity Monitor - is "YMusicSpectrogram" running? If yes, try:
```bash
# Kill the running instance
killall YMusicSpectrogram
# Run again
.build/release/YMusicSpectrogram
```

### Bars aren't moving
1. Make sure you clicked "Start Capture" in the menu
2. Verify microphone permission in System Preferences → Security & Privacy → Privacy → Microphone
3. Make some noise or play audio!

### High CPU usage
```bash
# Build in release mode (not debug)
swift build -c release
# Use release binary
.build/release/YMusicSpectrogram
```

## Next Steps

- 📖 Read [SETUP.md](SETUP.md) for detailed configuration
- 🏗️ Read [BUILD.md](BUILD.md) for advanced build options
- 🔧 Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand how it works
- 🎨 Customize colors and bands in the source code!

## Tips

1. **For best performance**: Always use the release build (`swift build -c release`)
2. **To save CPU**: Click "Stop Capture" when not actively using the visualizer
3. **For system audio**: BlackHole is free and works great!
4. **Customization**: All the code is in `YMusicSpectrogram/Sources/` - edit colors, bands, smoothing, etc.

## Building a Standalone App

Want to create a double-clickable .app?

```bash
# Build
swift build -c release

# Create app bundle
mkdir -p YMusicSpectrogram.app/Contents/{MacOS,Resources}
cp .build/release/YMusicSpectrogram YMusicSpectrogram.app/Contents/MacOS/
cp YMusicSpectrogram/Resources/Info.plist YMusicSpectrogram.app/Contents/
chmod +x YMusicSpectrogram.app/Contents/MacOS/YMusicSpectrogram

# Run the app
open YMusicSpectrogram.app

# Move to Applications folder (optional)
mv YMusicSpectrogram.app /Applications/
```

Now you can launch it like any other Mac app!

## One-Liner Install & Run

```bash
git clone https://github.com/Yixi/y-music-spectrogram.git && cd y-music-spectrogram && swift build -c release && .build/release/YMusicSpectrogram
```

Enjoy your visual music experience! 🎵✨

---

**Need help?** Open an issue on GitHub or check the full documentation.
