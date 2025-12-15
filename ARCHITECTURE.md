# Architecture Documentation

This document provides a detailed overview of the Y Music Spectrogram application architecture, design decisions, and implementation details.

## Overview

Y Music Spectrogram is a macOS menu bar application that provides real-time audio spectrum visualization. The application follows a modular architecture with clear separation of concerns.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Menu Bar (NSStatusBar)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         SpectrumVisualizerView (SwiftUI)             │  │
│  │  [▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃]  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │   MenuBarController      │
              │  (Coordination Layer)    │
              └──────────────────────────┘
                     │            │
        ┌────────────┘            └────────────┐
        ▼                                      ▼
┌──────────────────────┐            ┌──────────────────────┐
│ AudioCaptureManager  │            │  SpectrumAnalyzer    │
│  (Audio Input)       │───────────▶│  (FFT Processing)    │
│                      │  Samples   │                      │
│  - AVAudioEngine    │            │  - vDSP/Accelerate   │
│  - Mic Permission   │            │  - Band Grouping     │
│  - Buffer Handling  │            │  - Smoothing         │
└──────────────────────┘            └──────────────────────┘
        │                                      │
        ▼                                      ▼
   [Microphone]                         [@Published Array]
                                               │
                                               ▼
                                    [SwiftUI View Updates]
```

## Core Components

### 1. YMusicSpectrogramApp

**File**: `YMusicSpectrogramApp.swift`

**Responsibilities**:
- Application entry point (`@main`)
- App lifecycle management
- AppDelegate integration
- Dock icon hiding (via `NSApp.setActivationPolicy(.accessory)`)

**Key Features**:
- Uses `@NSApplicationDelegateAdaptor` to integrate AppKit functionality
- Implements `Settings` scene (empty, as we only use menu bar)
- Ensures app runs as menu bar-only (no dock icon)

**Design Decisions**:
- SwiftUI-based app lifecycle for modern macOS development
- AppDelegate still needed for NSStatusBar management
- Minimal UI - everything in the menu bar

### 2. AppDelegate

**File**: `YMusicSpectrogramApp.swift`

**Responsibilities**:
- Create and manage NSStatusItem
- Initialize MenuBarController
- Configure status bar button

**Key Features**:
- Sets activation policy to `.accessory` (menu bar only)
- Creates status bar item with fixed width (150 points)
- Hands off status bar button to MenuBarController

### 3. MenuBarController

**File**: `MenuBarController.swift`

**Responsibilities**:
- Coordinate between all major components
- Manage menu bar UI lifecycle
- Handle user interactions (menu actions)

**Components Managed**:
- AudioCaptureManager (audio input)
- SpectrumAnalyzer (FFT processing)
- SpectrumVisualizerView (UI rendering)

**UI Integration**:
- Uses `NSHostingView` to embed SwiftUI in AppKit
- Creates right-click context menu with controls
- Manages view constraints and layout

**Menu Actions**:
- Start Capture: Begins audio capture
- Stop Capture: Pauses audio capture
- Quit: Terminates the application

**Design Decisions**:
- Acts as a mediator pattern
- Owns all major subsystems
- Provides clean separation between AppKit and SwiftUI

### 4. AudioCaptureManager

**File**: `AudioCaptureManager.swift`

**Responsibilities**:
- Capture audio from microphone
- Request and manage audio permissions
- Process audio buffers
- Forward samples to SpectrumAnalyzer

**Technologies Used**:
- `AVAudioEngine`: Core audio capture engine
- `AVAudioInputNode`: Microphone input
- `AVCaptureDevice`: Permission management

**Configuration**:
- Sample Rate: 44.1 kHz (CD quality)
- Buffer Size: 4096 frames
- Format: Float32 PCM

**Audio Pipeline**:
```
[Microphone] → [AVAudioEngine] → [InputNode] → [installTap] 
→ [PCMBuffer] → [Float Array] → [SpectrumAnalyzer]
```

**Permission Handling**:
- Checks authorization status
- Requests access if needed
- Handles denial gracefully
- Uses NSMicrophoneUsageDescription from Info.plist

**Design Decisions**:
- MVP uses microphone (easy to implement, works everywhere)
- Includes extensive comments about system audio capture options
- Clean start/stop lifecycle
- Proper resource cleanup in deinit

**Future Enhancements**:
- ScreenCaptureKit integration for macOS 13+
- BlackHole driver detection and setup guidance
- Audio device selection UI

### 5. SpectrumAnalyzer

**File**: `SpectrumAnalyzer.swift`

**Responsibilities**:
- Perform FFT on audio samples
- Convert frequency data to visual bands
- Apply smoothing for animations
- Publish spectrum data to UI

**Technologies Used**:
- `Accelerate` framework (Apple's SIMD/DSP library)
- `vDSP_DFT_Execute`: Hardware-accelerated FFT
- `vDSP_zvmags`: Magnitude calculation
- `vDSP_hann_window`: Windowing function

**FFT Configuration**:
- FFT Size: 2048 samples
- Window: Hann window (for spectral leakage reduction)
- Output: 32 logarithmic frequency bands
- Smoothing: 70% (exponential moving average)

**Processing Pipeline**:
```
[Samples] → [Windowing] → [FFT] → [Magnitude] → [dB Scale] 
→ [Normalize] → [Band Grouping] → [Smoothing] → [UI Update]
```

**Frequency Band Grouping**:
- Uses logarithmic distribution (more bass/mid detail)
- Mimics human hearing perception
- 32 bands cover 20 Hz - 22 kHz
- Each band averages frequencies within its range

**Mathematical Details**:
```swift
// Magnitude calculation
magnitude = sqrt(real² + imaginary²)

// dB conversion
dB = 10 * log10(magnitude)

// Normalization (assuming -80 to 0 dB range)
normalized = (dB + 80) / 80

// Smoothing (exponential moving average)
smoothed = α * previous + (1 - α) * current
```

**Design Decisions**:
- `ObservableObject` with `@Published` for reactive UI
- Logarithmic bands for natural frequency perception
- Smoothing prevents jittery animations
- Main thread updates for UI safety
- Efficient use of Accelerate for performance

**Performance Characteristics**:
- FFT: O(n log n) complexity
- Executes on hardware (CPU/GPU acceleration)
- ~1-2ms per frame on modern Macs
- Minimal memory allocation (reuses buffers)

### 6. SpectrumVisualizerView

**File**: `SpectrumVisualizerView.swift`

**Responsibilities**:
- Render spectrum bars in menu bar
- Animate bar heights
- Apply color coding based on intensity
- Fit within menu bar constraints

**UI Structure**:
```swift
GeometryReader
  └─ HStack (bars with spacing)
      └─ ForEach (32 bars)
          └─ SpectrumBar
              └─ VStack
                  └─ Spacer
                  └─ RoundedRectangle
```

**Visual Design**:
- Width: 150 points (menu bar item size)
- Height: 22 points (standard menu bar height)
- 32 bars with 1.5pt spacing
- Rounded corners (1.5pt radius)
- Bottom-aligned bars

**Color Scheme**:
- **Green** (0-40%): Low intensity, base frequencies
- **Yellow** (40-70%): Medium intensity, prominent sound
- **Red** (70-100%): High intensity, peaks

**Animation**:
- Implicit SwiftUI animations
- Smooth transitions via `@Published` updates
- 60 FPS target (SwiftUI handles timing)
- Smoothing factor prevents jitter

**Design Decisions**:
- SwiftUI for declarative, simple rendering
- Bottom-aligned for natural "rising" effect
- Color gradient provides visual feedback
- Minimal height (2pt) prevents disappearing bars
- `GeometryReader` for responsive sizing

**Performance**:
- Very lightweight (just 32 rectangles)
- SwiftUI diff algorithm optimizes redraws
- GPU-accelerated rendering
- No custom drawing code needed

## Data Flow

### Capture to Display Flow

```
1. User Action: "Start Capture"
   └─▶ MenuBarController.startCapture()
       └─▶ AudioCaptureManager.startCapture()

2. Permission Check
   └─▶ requestMicrophonePermission()
       └─▶ AVCaptureDevice.requestAccess()

3. Audio Engine Start
   └─▶ inputNode.installTap()
       └─▶ Audio callbacks begin

4. Audio Buffer Received (44.1 kHz rate)
   └─▶ processAudioBuffer()
       └─▶ Extract float samples
           └─▶ SpectrumAnalyzer.processSamples()

5. FFT Processing (every buffer)
   └─▶ Apply windowing
       └─▶ Execute FFT
           └─▶ Calculate magnitudes
               └─▶ Convert to dB
                   └─▶ Group into bands
                       └─▶ Apply smoothing

6. UI Update (main thread)
   └─▶ @Published spectrumBands changed
       └─▶ SwiftUI view update triggered
           └─▶ SpectrumVisualizerView.body re-evaluated
               └─▶ Bar heights animated
                   └─▶ Colors updated
                       └─▶ Rendered to screen
```

### Timing Characteristics

- **Audio Buffer Rate**: ~10-20 buffers/second (depends on buffer size)
- **FFT Processing**: ~1-2ms per buffer
- **UI Update Rate**: 60 FPS (SwiftUI throttles appropriately)
- **Smoothing Window**: ~70% previous, 30% new (per update)
- **Total Latency**: ~50-100ms (barely perceptible)

## Thread Safety

### Thread Usage

1. **Main Thread**:
   - UI rendering (SwiftUI)
   - Menu interactions
   - Published property updates

2. **Audio Thread** (Real-time, High Priority):
   - Audio buffer callbacks
   - FFT processing
   - Sample extraction

3. **Dispatch Queues**:
   - Permission requests (main)
   - UI updates (main via DispatchQueue.main.async)

### Synchronization

- `@Published` properties automatically dispatch to main thread
- Audio processing happens on real-time thread
- No locks needed (read-only data flow)
- Smoothing array access is thread-safe (atomic operations)

## Memory Management

### Allocation Strategy

- **Pre-allocated Buffers**:
  - FFT buffers (real/imaginary parts)
  - Magnitude array
  - Window function array
  - All allocated once in `init()`

- **Minimal Runtime Allocation**:
  - Only Swift arrays for sample copying
  - Published array updates (copy-on-write)
  - SwiftUI view diffing allocations

### Resource Cleanup

- `deinit` in AudioCaptureManager stops engine
- FFT setup destroyed in SpectrumAnalyzer deinit
- AVAudioEngine handles its own cleanup
- No manual memory management needed (ARC)

## Configuration and Tuning

### Performance Knobs

| Parameter | Location | Default | Impact |
|-----------|----------|---------|--------|
| FFT Size | SpectrumAnalyzer | 2048 | Frequency resolution ↑, CPU ↑ |
| Buffer Size | AudioCaptureManager | 4096 | Latency ↑, Stability ↑ |
| Band Count | SpectrumAnalyzer | 32 | Visual detail ↑, CPU ↑ |
| Smoothing | SpectrumAnalyzer | 0.7 | Smoothness ↑, Responsiveness ↓ |
| Bar Spacing | SpectrumVisualizerView | 1.5pt | Visual clarity ↑, Bars ↓ |

### Recommended Presets

**Low Power Mode**:
- FFT Size: 1024
- Buffer Size: 8192
- Band Count: 16
- Smoothing: 0.85

**High Detail Mode**:
- FFT Size: 4096
- Buffer Size: 2048
- Band Count: 64
- Smoothing: 0.5

## Design Patterns Used

1. **Observer Pattern**: 
   - SpectrumAnalyzer publishes data
   - SwiftUI views observe changes

2. **Mediator Pattern**:
   - MenuBarController coordinates components
   - Reduces coupling between subsystems

3. **Singleton-like**:
   - AppDelegate owns single instances
   - No global state, just single instance tree

4. **Delegate Pattern**:
   - AppDelegate for app lifecycle
   - Standard Cocoa pattern

## Platform-Specific Considerations

### macOS Integration

- **NSStatusBar**: Legacy AppKit API (no SwiftUI equivalent)
- **NSHostingView**: Bridge between SwiftUI and AppKit
- **LSUIElement**: Info.plist key to hide dock icon
- **AVAudioEngine**: macOS audio capture system

### System Requirements

- **macOS 13.0+**: Required for Swift 5.9 features
- **Accelerate Framework**: Available on all Macs
- **Microphone Permission**: Required via Info.plist

### Sandboxing Considerations

- Microphone entitlement required
- System audio capture requires:
  - Virtual audio driver (BlackHole), OR
  - ScreenCaptureKit API (screen recording permission), OR
  - Non-sandboxed build

## Future Architecture Improvements

### Planned Enhancements

1. **ScreenCaptureKit Support**:
   - Add SCStream for system audio
   - Implement app-specific capture
   - Automatic fallback to microphone

2. **Settings System**:
   - User preferences storage
   - Customizable colors/bands
   - Audio device selection

3. **Multiple Visualizers**:
   - Plugin architecture for visualizer styles
   - Waveform, spectrogram, bars, etc.
   - User-selectable modes

4. **Performance Monitoring**:
   - CPU usage tracking
   - Adaptive quality adjustment
   - Power-aware processing

### Code Organization

Current structure:
```
YMusicSpectrogram/
├── Sources/
│   ├── YMusicSpectrogramApp.swift    (Entry point)
│   ├── MenuBarController.swift       (Coordination)
│   ├── AudioCaptureManager.swift     (Input)
│   ├── SpectrumAnalyzer.swift        (Processing)
│   └── SpectrumVisualizerView.swift  (UI)
└── Resources/
    └── Info.plist                     (Config)
```

Future structure:
```
YMusicSpectrogram/
├── Sources/
│   ├── App/
│   │   ├── YMusicSpectrogramApp.swift
│   │   └── AppDelegate.swift
│   ├── Controllers/
│   │   └── MenuBarController.swift
│   ├── Audio/
│   │   ├── AudioCaptureManager.swift
│   │   ├── ScreenCaptureAudioSource.swift
│   │   └── AudioSource.swift (protocol)
│   ├── Processing/
│   │   ├── SpectrumAnalyzer.swift
│   │   └── DSPProcessor.swift
│   ├── Views/
│   │   ├── SpectrumVisualizerView.swift
│   │   ├── SettingsView.swift
│   │   └── VisualizerProtocol.swift
│   └── Models/
│       ├── AudioConfig.swift
│       └── VisualizerSettings.swift
└── Resources/
    ├── Info.plist
    └── Assets.xcassets/
```

## Testing Strategy

### Unit Tests

- SpectrumAnalyzer FFT correctness
- Band grouping logic
- Smoothing algorithm
- Sample data fixtures

### Integration Tests

- Audio capture startup/shutdown
- Permission flow
- Component coordination
- Memory leaks

### UI Tests

- Menu bar item presence
- Menu interactions
- Visual rendering (snapshots)
- Animation performance

## Performance Benchmarks

Target metrics on Apple Silicon Mac:

- CPU Usage: < 5% average
- Memory Usage: < 50 MB
- Frame Rate: 60 FPS UI updates
- Audio Latency: < 100ms
- Power Impact: Low (Energy Impact in Activity Monitor)

## Conclusion

The architecture prioritizes:
1. **Simplicity**: Clear, understandable code
2. **Performance**: Hardware acceleration, efficient algorithms
3. **Modularity**: Loosely coupled components
4. **Maintainability**: Standard patterns, good documentation
5. **User Experience**: Smooth animations, low resource usage

This design provides a solid foundation for future enhancements while keeping the codebase accessible to contributors.
