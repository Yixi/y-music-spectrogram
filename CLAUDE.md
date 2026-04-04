# Y Music Spectrogram - 项目指南

## 项目概述

macOS 菜单栏实时音频频谱可视化应用。使用 ScreenCaptureKit 捕获系统音频，通过 Accelerate 框架的 vDSP 进行 FFT 分析，在菜单栏中以彩色柱状图展示频谱。

## 技术栈

- **语言**: Swift 5.9
- **UI**: SwiftUI + AppKit (NSStatusItem 菜单栏集成)
- **构建系统**: Swift Package Manager (非 Xcode 项目)
- **最低系统要求**: macOS 13.0
- **无外部依赖**

## 构建命令

```bash
# Debug 构建并运行（会自动打包 .app 并启动）
./debug.sh

# Release 构建
swift build -c release

# Release 构建后打包为 .app
swift build -c release && ./bundle.sh

# 运行打包后的应用
open .build/release/YMusicSpectrogram.app
```

注意: 构建脚本 `bundle.sh` / `debug.sh` 会将编译产物包装为 `.app` bundle 并处理 Info.plist 中的变量替换。

## 架构

所有源码位于 `YMusicSpectrogram/Sources/`，共 7 个文件:

| 文件 | 职责 |
|------|------|
| `YMusicSpectrogramApp.swift` | 应用入口 (@main)，AppDelegate 创建 MenuBarController 和 NSStatusItem |
| `MenuBarController.swift` | 菜单栏集成核心，组装音频捕获/分析/可视化管线，管理右键菜单和设置窗口 |
| `AudioCaptureManager.swift` | 使用 ScreenCaptureKit 捕获系统音频，将 Float32 PCM 数据传给 SpectrumAnalyzer |
| `SpectrumAnalyzer.swift` | FFT 分析 (vDSP, 4096 采样)，对数频带分组 (20Hz-20kHz)，自动增益和平滑 |
| `SpectrumVisualizerView.swift` | SwiftUI 视图，渲染频谱柱状图，固定高度 22pt |
| `SettingsManager.swift` | 单例，管理用户偏好 (UserDefaults): 频带数量、颜色方案等 |
| `SettingsView.swift` | 设置窗口 SwiftUI 界面 |

### 数据流

```
ScreenCaptureKit → AudioCaptureManager → SpectrumAnalyzer (@Published) → SpectrumVisualizerView
```

### 关键设计细节

- **ClickThroughHostingView**: 自定义 NSHostingView 子类，`hitTest` 返回 nil 使鼠标事件穿透到底层 NSStatusBarButton，解决 SwiftUI 视图遮挡菜单栏点击的问题
- **线程安全**: `SpectrumAnalyzer` 使用 `NSLock` (configurationLock) 保护频带配置，音频回调在 `.userInteractive` 队列，UI 更新通过 `DispatchQueue.main.async`
- **应用类型**: LSUIElement = true (无 Dock 图标，仅菜单栏)，通过 `NSApp.setActivationPolicy(.accessory)` 设置

## 开发注意事项

- 应用需要**屏幕录制权限**才能捕获系统音频，开发时需在系统设置中授权
- Info.plist 使用 `$(VARIABLE)` 占位符，由构建脚本 sed 替换，不要写入硬编码值
- `SettingsManager` 是全局单例 (`shared`)，`SpectrumAnalyzer` 和 `SpectrumVisualizerView` 则通过 MenuBarController 创建并注入
- 菜单栏宽度固定 150pt，频谱柱高度 22pt（标准菜单栏高度）
- 音频采样率固定 48kHz (ScreenCaptureKit 默认)
