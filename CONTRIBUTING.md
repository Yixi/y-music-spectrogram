# Contributing to Y Music Spectrogram

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Code Style](#code-style)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Areas for Contribution](#areas-for-contribution)

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the project and community
- Be patient with new contributors

## Getting Started

1. **Fork the Repository**
   ```bash
   # Click "Fork" on GitHub
   # Then clone your fork
   git clone https://github.com/YOUR-USERNAME/y-music-spectrogram.git
   cd y-music-spectrogram
   ```

2. **Set Up Upstream Remote**
   ```bash
   git remote add upstream https://github.com/Yixi/y-music-spectrogram.git
   ```

3. **Verify Your Setup**
   ```bash
   swift build
   ```

## Development Setup

### Requirements

- macOS 13.0+ (required for building/testing)
- Xcode 15.0+
- Swift 5.9+
- Git

### Building

```bash
# Debug build (faster compile, useful for development)
swift build

# Release build (optimized, use for testing performance)
swift build -c release
```

### Running

```bash
# Run debug build
swift run

# Run release build
.build/release/YMusicSpectrogram
```

### Generate Xcode Project (Optional)

```bash
swift package generate-xcodeproj
open YMusicSpectrogram.xcodeproj
```

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `perf/` - Performance improvements

### 2. Make Your Changes

- Keep changes focused and atomic
- Test your changes thoroughly
- Update documentation if needed
- Add comments for complex logic

### 3. Test Locally

```bash
# Build and test
swift build -c release
.build/release/YMusicSpectrogram

# Verify menu bar appearance
# Test with various audio inputs
# Check CPU/memory usage in Activity Monitor
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "Brief description of changes"
```

Commit message guidelines:
- Use present tense ("Add feature" not "Added feature")
- Be descriptive but concise
- Reference issues if applicable (#123)

Examples:
```
Add support for custom color schemes
Fix memory leak in AudioCaptureManager
Update README with BlackHole setup instructions
Refactor FFT processing for better performance
```

## Code Style

### Swift Style Guide

Follow Apple's Swift guidelines:

- **Indentation**: 4 spaces (no tabs)
- **Line Length**: 100-120 characters max
- **Naming**:
  - `lowerCamelCase` for variables, functions, properties
  - `UpperCamelCase` for types, protocols, enums
  - Descriptive names over abbreviations

```swift
// Good
func processSamples(_ samples: [Float]) { ... }
let numberOfBands = 32
class SpectrumAnalyzer { ... }

// Avoid
func pS(_ s: [Float]) { ... }
let n = 32
class SA { ... }
```

- **Spacing**:
  ```swift
  // Good
  if condition {
      doSomething()
  }
  
  let result = calculate(a, b, c)
  
  // Avoid
  if condition{
      doSomething()
  }
  let result=calculate(a,b,c)
  ```

- **Comments**:
  ```swift
  // Single-line for brief explanations
  
  /// Documentation comments for public APIs
  /// - Parameter samples: Audio sample data
  /// - Returns: Processed frequency bands
  func processSamples(_ samples: [Float]) -> [Float] {
      // Implementation details as needed
  }
  ```

### SwiftUI Conventions

```swift
// Good structure
struct MyView: View {
    // MARK: - Properties
    @ObservedObject var analyzer: SpectrumAnalyzer
    private let spacing: CGFloat = 1.5
    
    // MARK: - Body
    var body: some View {
        // View hierarchy
    }
    
    // MARK: - Helpers
    private var someComputed: Value {
        // Computed property
    }
}
```

### File Organization

```swift
//
//  FileName.swift
//  YMusicSpectrogram
//
//  Brief description of file's purpose
//

// MARK: - Imports
import Foundation
import SwiftUI

// MARK: - Main Type
class MyClass {
    // MARK: - Properties
    
    // MARK: - Initialization
    
    // MARK: - Public Methods
    
    // MARK: - Private Methods
}

// MARK: - Extensions
extension MyClass {
    // Grouped related functionality
}
```

## Testing

### Manual Testing Checklist

Before submitting a PR, verify:

- [ ] App builds successfully (`swift build`)
- [ ] App launches and appears in menu bar
- [ ] Microphone permission request works
- [ ] Audio capture starts/stops correctly
- [ ] Spectrum visualization responds to audio
- [ ] Colors change appropriately with intensity
- [ ] Menu items work (Start/Stop/Quit)
- [ ] No memory leaks (run for 5+ minutes, check Activity Monitor)
- [ ] CPU usage is reasonable (<10% average)
- [ ] No crash logs in Console.app

### Testing Audio Capture

```bash
# Test with different inputs:
# 1. Silence (background noise only)
# 2. Speaking/voice
# 3. Music playback (various genres)
# 4. System sounds
# 5. Extended runtime (30+ minutes)
```

### Performance Testing

```bash
# Monitor resource usage
open -a "Activity Monitor"

# Run in release mode
swift build -c release
.build/release/YMusicSpectrogram

# Check:
# - CPU < 10% average
# - Memory < 100MB
# - Energy Impact: Low
```

## Submitting Changes

### 1. Update Your Branch

```bash
# Fetch latest changes
git fetch upstream

# Merge or rebase
git rebase upstream/main
```

### 2. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 3. Create Pull Request

1. Go to GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill out the template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
Describe how you tested the changes

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Tested locally and verified functionality
- [ ] Updated documentation if needed
- [ ] No new warnings or errors
- [ ] Checked for memory leaks
```

### 4. Code Review Process

- Maintainers will review your PR
- Address feedback and requested changes
- Update your PR by pushing to the same branch
- Once approved, maintainers will merge

## Areas for Contribution

### Good First Issues

- Improve documentation
- Add code comments
- Fix typos
- Update README examples
- Create usage examples

### Feature Enhancements

#### Audio Sources
- [ ] ScreenCaptureKit integration for macOS 13+
- [ ] Audio device selection UI
- [ ] BlackHole detection and setup wizard
- [ ] Support for audio file playback

#### Visualization
- [ ] Customizable color schemes
- [ ] Multiple visualizer styles (waveform, circular)
- [ ] Adjustable bar count
- [ ] Peak hold indicators
- [ ] Mirror/symmetrical mode
- [ ] Frequency labels

#### User Interface
- [ ] Settings/preferences window
- [ ] Menulet icon when no audio
- [ ] Tooltips with frequency info
- [ ] Keyboard shortcuts
- [ ] Multiple theme support

#### Performance
- [ ] Metal acceleration for rendering
- [ ] Adaptive quality based on battery
- [ ] Optimized FFT for M-series chips
- [ ] Reduced memory allocation

#### Configuration
- [ ] User preferences persistence
- [ ] Export/import settings
- [ ] Preset configurations
- [ ] Per-app audio routing

### Documentation Improvements

- Expand architecture documentation
- Add video tutorials
- Create troubleshooting guide
- Document FFT algorithm details
- Add performance benchmarks

### Testing

- Unit tests for SpectrumAnalyzer
- Integration tests for audio capture
- UI tests with XCTest
- Performance benchmarking suite
- Memory leak detection tests

## Code Review Guidelines

When reviewing others' code:

- Be constructive and kind
- Ask questions to understand the approach
- Suggest improvements, don't demand them
- Approve if it meets standards, even if you'd do it differently
- Test the changes locally if possible

## Getting Help

- Open an issue for questions
- Check existing issues and PRs
- Read the documentation thoroughly
- Ask in PR comments for specific questions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be:
- Listed in release notes
- Acknowledged in the repository
- Credited for significant contributions

Thank you for contributing to Y Music Spectrogram! 🎵
