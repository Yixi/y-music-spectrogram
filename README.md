# Y Music Spectrogram

A macOS menu bar application that displays real-time audio spectrum visualization.

![Menu Bar Spectrogram](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

## Features

- 🎵 **Real-time Audio Visualization**: Live spectrum analysis displayed in your menu bar
- 🎨 **Beautiful Animations**: Smooth, color-coded frequency bars with minimal performance impact
- 🔊 **Microphone Input**: Captures audio from your microphone (MVP implementation)
- ⚡ **High Performance**: Uses Apple's Accelerate framework for efficient FFT processing
- 🎯 **Menu Bar Integration**: Lives in your menu bar, keeps your dock clean

## Architecture

The application consists of several key components:

### Core Components

1. **AudioCaptureManager**: Handles audio input capture from the microphone
   - Manages AVAudioEngine and audio permissions
   - Processes audio buffers in real-time
   - Includes notes about system audio capture options

2. **SpectrumAnalyzer**: Performs FFT analysis using the Accelerate framework
   - Uses vDSP for efficient Fast Fourier Transform
   - Groups frequencies into 32 logarithmic bands
   - Applies windowing and smoothing for better visualization

3. **SpectrumVisualizerView**: SwiftUI view for rendering the spectrum
   - Displays 32 animated frequency bars
   - Color-coded based on intensity (green/yellow/red)
   - Optimized for menu bar display

4. **MenuBarController**: Manages the status bar integration
   - Creates and configures the menu bar item
   - Provides start/stop controls
   - Integrates all components

## Building and Running

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build with Swift Package Manager

```bash
# Clone the repository
git clone https://github.com/Yixi/y-music-spectrogram.git
cd y-music-spectrogram

# Build the application
swift build -c release

# Run the application
.build/release/YMusicSpectrogram
```

### Build with Xcode

1. Open the project directory in Xcode
2. Create a new macOS App project and import the source files
3. Make sure Info.plist is properly configured
4. Build and run (⌘R)

## System Audio Capture

⚠️ **Important Note**: This MVP version captures audio from the **microphone** input.

To capture actual system audio (music playback), you have several options:

### Option 1: BlackHole Virtual Audio Driver (Recommended)

1. Install [BlackHole](https://github.com/ExistentialAudio/BlackHole):
   ```bash
   brew install blackhole-2ch
   ```

2. Configure Audio MIDI Setup:
   - Open "Audio MIDI Setup" app
   - Create a Multi-Output Device
   - Select both your speakers and BlackHole
   - Set BlackHole as your input device in the app

### Option 2: ScreenCaptureKit (macOS 13+)

- Requires additional implementation using `SCShareableContent` and `SCStreamConfiguration`
- Needs Screen Recording permission
- Can capture audio from specific apps or system-wide

### Option 3: Loopback (Commercial)

- Professional solution from Rogue Amoeba
- Provides advanced audio routing capabilities

## Usage

1. Launch the application
2. Grant microphone permission when prompted
3. The spectrum visualizer appears in your menu bar
4. Right-click the menu bar item to:
   - Start/Stop audio capture
   - Quit the application

## Technical Details

### FFT Configuration

- **FFT Size**: 2048 samples
- **Sample Rate**: 44.1 kHz
- **Buffer Size**: 4096 frames
- **Frequency Bands**: 32 (logarithmically distributed)
- **Window Function**: Hann window for spectral leakage reduction

### Performance

- Uses Accelerate framework's vDSP for hardware-accelerated FFT
- Minimal CPU usage (~2-5%)
- Smooth 60 FPS animations via SwiftUI

### UI Specifications

- **Menu Bar Width**: 150 points
- **Height**: 22 points (standard menu bar height)
- **Bar Spacing**: 1.5 points
- **Color Scheme**: 
  - Green: Low intensity (0-40%)
  - Yellow: Medium intensity (40-70%)
  - Red: High intensity (70-100%)

## Project Structure

```
y-music-spectrogram/
├── Package.swift
├── README.md
└── YMusicSpectrogram/
    ├── Sources/
    │   ├── YMusicSpectrogramApp.swift      # App entry point
    │   ├── MenuBarController.swift          # Menu bar integration
    │   ├── AudioCaptureManager.swift        # Audio input handling
    │   ├── SpectrumAnalyzer.swift          # FFT processing
    │   └── SpectrumVisualizerView.swift    # UI visualization
    └── Resources/
        └── Info.plist                       # App configuration
```

## Future Enhancements

- [ ] ScreenCaptureKit integration for native system audio capture
- [ ] Customizable color schemes
- [ ] Adjustable number of frequency bands
- [ ] Peak hold indicators
- [ ] Audio device selection
- [ ] Preset visualizer styles
- [ ] Export settings/preferences

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Troubleshooting

### No Audio Input Detected
- Check System Preferences > Security & Privacy > Microphone
- Ensure the app has microphone permission
- For system audio, verify BlackHole installation and Audio MIDI Setup configuration

### Menu Bar Item Not Showing
- Check that LSUIElement is set to YES in Info.plist
- Verify the app is running (check Activity Monitor)

### Poor Performance
- Reduce the number of frequency bands in SpectrumAnalyzer
- Increase the smoothing factor for less frequent updates

## Credits

Built with ❤️ using Swift, SwiftUI, and Apple's Accelerate framework.