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

## 4. Grant Screen Recording Permission

When you first run the app:
1. A dialog will appear asking for **Screen Recording** permission
2. Click **Open System Settings**
3. In Privacy & Security > Screen Recording, check the box next to **YMusicSpectrogram**
4. **Quit and restart** the app for the permission to take effect
5. The spectrum visualizer will appear in your menu bar!

**Why Screen Recording?** The app uses ScreenCaptureKit to capture system audio - this requires screen recording permission but doesn't actually record your screen.

## 5. Start Capturing Audio

1. Right-click the spectrum visualizer in your menu bar
2. Select **"Start Capture"**
3. Play any music, video, or audio on your Mac - the bars should start moving!

## What You Should See

In your menu bar, you'll see 32 animated bars:
- 🟢 **Green bars**: Low-intensity audio (quiet sounds, bass)
- 🟡 **Yellow bars**: Medium-intensity audio (normal talking/music)
- 🔴 **Red bars**: High-intensity audio (loud sounds, peaks)

## Capturing System Audio (Music Playback)

✅ **System audio capture works out of the box!** 

The app uses **ScreenCaptureKit** to capture all system audio:
- Play music in Spotify, Apple Music, YouTube, or any app
- The visualizer responds to ALL audio output from your Mac
- No virtual audio drivers needed!
- Works immediately after granting screen recording permission

### If You Prefer Not to Grant Screen Recording Permission

The app will automatically fall back to microphone input:
- Play music out loud near your microphone
- Or optionally install BlackHole for virtual audio routing:

```bash
# Install BlackHole (optional)
brew install blackhole-2ch
# Then configure Audio MIDI Setup to route system audio
```

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
2. Verify Screen Recording permission in System Settings → Privacy & Security → Screen Recording
3. Quit and restart the app after granting permission
4. Play some audio - music, video, system sounds - anything!
5. If still not working, check Console.app for error messages

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
