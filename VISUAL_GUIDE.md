# Visual Guide

This document describes what the Y Music Spectrogram application looks like when running.

## Menu Bar Appearance

When the application is running, you'll see the spectrum visualizer in your macOS menu bar:

```
┌────────────────────────────────────────────────────────────────┐
│  🍎   📁   🔍   ...                    [▂▃▅▆▇▆▅▃▂]  🔋  🔊  ⏰ │
└────────────────────────────────────────────────────────────────┘
                                              ↑
                                    Spectrum Visualizer
```

### Detailed View

The visualizer displays 32 vertical bars in approximately 150 points width:

```
     Menu Bar (22pt height)
     ┌─────────────────────────────────────────────┐
     │                                             │
     │    ▂  ▃  ▅  ▆  ▇  ▆  ▅  ▃  ▂  ▁  ▂  ▃  ▅  │
     │    ▂  ▃  ▅  ▆  ▇  ▆  ▅  ▃  ▂  ▁  ▂  ▃  ▅  │ ← Animated bars
     └─────────────────────────────────────────────┘
          ↑                                    ↑
       Lower                              Higher
    frequencies                        frequencies
     (Bass)                             (Treble)
```

## Color Coding

Bars change color based on audio intensity:

### 🟢 Low Intensity (0-40%)
```
┌────┐
│    │ ← Quiet sounds
│    │   Background noise
│    │   Soft music
│ ▂  │   Bass frequencies (often lower intensity)
└────┘
Color: Green (RGB: 0.3, 0.8, 0.3)
```

### 🟡 Medium Intensity (40-70%)
```
┌────┐
│    │
│ ▅  │ ← Normal talking
│ ▅  │   Regular music playback
│ ▅  │   Mid-range frequencies
└────┘
Color: Yellow (RGB: 1.0, 0.8, 0.2)
```

### 🔴 High Intensity (70-100%)
```
┌────┐
│ ▇  │ ← Loud sounds
│ ▇  │   Music peaks/drops
│ ▇  │   Shouting, clapping
│ ▇  │   High-energy frequencies
└────┘
Color: Red (RGB: 1.0, 0.3, 0.3)
```

## Real-Time Animation Examples

### Playing Music (Dance/Electronic)
```
Time: 0ms
[▂▂▃▃▅▅▆▆▇▇▆▆▅▅▃▃▂▂▁▁▂▂▃▃▅▅▆▆▇▇▆▆▅▅]
 └──┘     └─────┘         └─────┘
 Bass     Mids          Treble

Time: 100ms (bass drop)
[▇▇▇▇▇▆▆▅▅▃▃▂▂▂▂▁▁▁▁▁▁▁▁▂▂▃▃▅▅▆▆▇▇]
 └──────┘
Heavy bass

Time: 200ms (vocals)
[▃▃▃▃▃▃▃▅▅▅▅▆▆▆▆▇▇▇▅▅▅▃▃▃▂▂▂▂▂▂▂▂]
         └────────────┘
      Vocal frequencies

Time: 300ms (synth)
[▂▂▂▂▂▂▂▂▂▂▂▃▃▃▃▅▅▅▅▆▆▆▆▇▇▇▇▇▆▆▅▅]
                     └─────────┘
                   High synth notes
```

### Speaking/Voice
```
Normal speech (mostly mid-range frequencies):
[▂▂▂▂▂▃▃▃▅▅▅▆▆▆▇▇▇▆▆▅▅▃▃▃▂▂▂▂▂▂▂▂]
       └──────────────┘
       Voice frequencies (200-3000 Hz)
```

### Silence
```
Background noise only:
[▂▂▁▁▂▂▁▁▂▂▁▁▂▂▁▁▂▂▁▁▂▂▁▁▂▂▁▁▂▂▁▁]
Very minimal, mostly static
```

## Context Menu

Right-clicking the visualizer shows a menu:

```
┌─────────────────────┐
│ ▶ Start Capture     │ ← Begin audio capture
├─────────────────────┤
│ ⏸ Stop Capture      │ ← Pause capture
├─────────────────────┤
│ ⏹ Quit              │ ← Exit application
└─────────────────────┘
```

## Typical User Flows

### First Launch

1. **Before Permission**
   ```
   Menu Bar: [No visualizer yet]
   
   Screen Center:
   ┌──────────────────────────────────────────────┐
   │  "YMusicSpectrogram" would like to           │
   │  access the microphone.                      │
   │                                               │
   │  This app needs access to the microphone to  │
   │  capture audio for spectrum visualization.   │
   │                                               │
   │            [Don't Allow]    [OK]             │
   └──────────────────────────────────────────────┘
   ```

2. **After Permission Granted**
   ```
   Menu Bar: [▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂]
                    ↑
              Visualizer appears (all minimal - no audio yet)
   ```

3. **After Starting Capture**
   ```
   Menu Bar: [▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃]
                    ↑
              Bars animate with audio!
   ```

### Active Music Playback

**Example: Pop Song with Vocals**

```
Intro (instrumental):
[▃▃▃▃▃▅▅▅▅▆▆▆▆▅▅▅▅▃▃▃▃▂▂▂▂▂▂▂▂▂▂▂]

Verse (vocals + light instrumental):
[▂▂▂▂▃▃▃▅▅▅▆▆▆▇▇▇▇▆▆▆▅▅▅▃▃▃▂▂▂▂▂▂]

Chorus (full band + vocals):
[▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▆▆▆▆▅▅▅▅▃▃▃▃▃]

Drop/Breakdown (bass heavy):
[▇▇▇▇▇▇▇▆▆▆▅▅▅▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂]

Bridge (vocals only):
[▂▂▂▂▂▂▃▃▃▅▅▅▆▆▆▇▇▇▆▆▅▅▃▃▂▂▂▂▂▂▂▂]
```

## Screen Position

The visualizer appears in the menu bar, typically positioned:

```
┌─────────────────────────────────────────────────────────────────┐
│  🍎  File  Edit  View  ...     [Visualizer]  🔋 85%  3:45 PM   │
└─────────────────────────────────────────────────────────────────┘
                                       ↑
                           Near the right side, before system icons
```

## Size Specifications

- **Width**: 150 points (approximately 1.5-2 inches)
- **Height**: 22 points (standard menu bar height)
- **Bar Count**: 32 vertical bars
- **Bar Spacing**: 1.5 points between bars
- **Bar Width**: ~3-4 points each (calculated to fit)
- **Corner Radius**: 1.5 points (slightly rounded)

## Animation Characteristics

- **Update Rate**: ~60 FPS (smooth animations)
- **Smoothing**: 70% previous + 30% new value
- **Response Time**: ~50-100ms from audio to visual
- **Color Transitions**: Smooth gradient between intensity levels
- **Bar Movement**: Implicit SwiftUI animation (easeInOut)

## Accessibility

- **High Contrast Mode**: Colors remain distinct
- **Reduced Motion**: Animations still occur (consider adding preference)
- **VoiceOver**: Menu bar item is accessible
- **Menu Navigation**: Keyboard navigable (⌘-click menu bar)

## Performance Indicators

### Normal Operation
```
Activity Monitor:
YMusicSpectrogram
CPU: 2-5%
Memory: 30-50 MB
Energy Impact: Low
```

### High Load (Complex Audio)
```
Activity Monitor:
YMusicSpectrogram  
CPU: 5-10%
Memory: 40-60 MB
Energy Impact: Low to Medium
```

## Comparison with Other Visualizers

### Y Music Spectrogram (This App)
```
[▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃]
- Clean, minimalist
- Color-coded
- Logarithmic frequency distribution
- Menu bar integrated
```

### Typical Spectrogram (Reference)
```
████████████████████████████████
██████████████▓▓▓▓▓▓████████████
██████▓▓▓▓░░░░░░░░░░▓▓▓▓████████
████░░░░░░░░░░░░░░░░░░░░▓▓██████
- Heatmap style
- Horizontal time axis
- Vertical frequency axis
- More detailed but larger
```

## Notes for Users

1. **The visualizer runs continuously** when capture is started, even if no audio is playing
2. **Bars never completely disappear** - minimum height of 2 points for visual consistency
3. **Colors transition smoothly** between intensity levels
4. **Lower frequency bands** (left side) typically show more activity for music with bass
5. **Higher frequency bands** (right side) respond to hi-hats, cymbals, vocals
6. **Smoothing effect** prevents jittery animation but may slightly delay response to sudden changes

## Expected Behavior

### What's Normal
✅ Bars moving in rhythm with music
✅ Lower bars (bass) often taller with bass-heavy music
✅ Smooth color transitions
✅ 2-5% CPU usage
✅ Small delay (~50-100ms) between audio and visual

### What Might Indicate Issues
❌ No movement at all (check "Start Capture", check permissions)
❌ All bars maxed out constantly (volume too high, adjust input level)
❌ Very jerky motion (build in debug mode? use release build)
❌ >20% CPU usage (unexpected, check Activity Monitor)
❌ Visualizer not appearing (check LSUIElement in Info.plist)

## Future Visual Enhancements

Planned improvements:
- [ ] Customizable color schemes
- [ ] Different visualizer styles (waveform, circular, etc.)
- [ ] Peak hold indicators
- [ ] Frequency labels on hover
- [ ] Adjustable bar count
- [ ] Mirror mode (symmetrical display)
- [ ] Multiple window support

---

**Note**: Since this app runs on macOS, actual appearance may vary slightly based on:
- macOS version and appearance (Light/Dark mode)
- Menu bar density (notch on newer MacBooks affects available space)
- Display resolution and scaling
- System-wide accessibility settings
