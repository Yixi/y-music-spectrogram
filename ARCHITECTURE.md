# 架构文档

本文档详细概述了 Y Music Spectrogram 应用程序的架构、设计决策和实现细节。

## 概览

Y Music Spectrogram 是一个 macOS 菜单栏应用程序，提供实时音频频谱可视化。该应用程序遵循模块化架构，关注点分离清晰。

## 高层架构

```
┌─────────────────────────────────────────────────────────────┐
│                     菜单栏 (NSStatusBar)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         SpectrumVisualizerView (SwiftUI)             │  │
│  │  [▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃▅▆▇▆▅▃▂▁▂▃]  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │   MenuBarController      │
              │      (协调层)             │
              └──────────────────────────┘
                     │            │
        ┌────────────┘            └────────────┐
        ▼                                      ▼
┌──────────────────────┐            ┌──────────────────────┐
│ AudioCaptureManager  │            │  SpectrumAnalyzer    │
│      (音频输入)       │───────────▶│     (FFT 处理)       │
│                      │   样本      │                      │
│  - ScreenCaptureKit │            │  - vDSP/Accelerate   │
│  - 系统音频          │            │  - 频带分组           │
│  - 缓冲区处理        │            │  - 平滑处理           │
└──────────────────────┘            └──────────────────────┘
        │                                      │
        ▼                                      ▼
    [系统输出]                          [@Published 数组]
                                               │
                                               ▼
                                    [SwiftUI 视图更新]
```

## 核心组件

### 1. YMusicSpectrogramApp

**文件**: `YMusicSpectrogramApp.swift`

**职责**:
- 应用程序入口点 (`@main`)
- 应用生命周期管理
- AppDelegate 集成
- 隐藏 Dock 图标 (通过 `NSApp.setActivationPolicy(.accessory)`)

**关键特性**:
- 使用 `@NSApplicationDelegateAdaptor` 集成 AppKit 功能
- 实现 `Settings` 场景（为空，因为我们只使用菜单栏）
- 确保应用作为仅菜单栏应用运行（无 Dock 图标）

**设计决策**:
- 基于 SwiftUI 的应用生命周期，适应现代 macOS 开发
- 仍需 AppDelegate 进行 NSStatusBar 管理
- 极简 UI - 一切都在菜单栏中

### 2. AppDelegate

**文件**: `YMusicSpectrogramApp.swift`

**职责**:
- 创建和管理 NSStatusItem
- 初始化 MenuBarController
- 配置状态栏按钮

**关键特性**:
- 设置激活策略为 `.accessory`（仅菜单栏）
- 创建固定宽度的状态栏项目（150 点）
- 将状态栏按钮移交给 MenuBarController

### 3. MenuBarController

**文件**: `MenuBarController.swift`

**职责**:
- 协调所有主要组件
- 管理菜单栏 UI 生命周期
- 处理用户交互（菜单操作）

**管理的组件**:
- AudioCaptureManager（音频输入）
- SpectrumAnalyzer（FFT 处理）
- SpectrumVisualizerView（UI 渲染）

**UI 集成**:
- 使用 `NSHostingView` 将 SwiftUI 嵌入 AppKit
- 创建带有控件的右键上下文菜单
- 管理视图约束和布局

**菜单操作**:
- 开始捕获：开始音频捕获
- 停止捕获：暂停音频捕获
- 退出：终止应用程序

**设计决策**:
- 充当中介者模式
- 拥有所有主要子系统
- 提供 AppKit 和 SwiftUI 之间的清晰分离

### 4. AudioCaptureManager

**文件**: `AudioCaptureManager.swift`

**职责**:
- 使用 ScreenCaptureKit 捕获系统音频
- 请求和管理屏幕录制权限
- 处理来自系统输出的音频缓冲区
- 将样本转发给 SpectrumAnalyzer

**使用的技术**:
- `ScreenCaptureKit`: 原生系统音频捕获（主要）
- `SCStream`: 音频流管理
- `SCStreamOutput`: 音频样本缓冲区处理
- `CMSampleBuffer`: 来自 ScreenCaptureKit 的音频数据

**配置**:
- 采样率: 48 kHz (ScreenCaptureKit)
- 缓冲区大小: 4096 帧
- 格式: Float32 PCM
- 通道: 立体声（混合为单声道进行处理）

**主要音频管线 (ScreenCaptureKit)**:
```
[系统音频] → [SCStream] → [SCStreamOutput] → [CMSampleBuffer]
→ [Float 数组] → [SpectrumAnalyzer]
```

**权限处理**:
- 检查屏幕录制授权 (CGPreflightScreenCaptureAccess)
- 如果需要，请求屏幕录制权限 (CGRequestScreenCaptureAccess)
- 使用 Info.plist 中的 NSScreenCaptureDescription

**设计决策**:
- **ScreenCaptureKit**: 提供无需虚拟驱动的原生系统音频捕获
- **仅音频捕获**: 配置最小视频 (100x100) 以减少开销
- **Async/await 模式**: 用于权限处理的现代 Swift 并发
- **清晰的生命周期**: 正确的流清理和资源管理

**实现细节**:
- `AudioStreamOutput` 类实现 `SCStreamOutput` 协议
- 实时处理 `CMSampleBuffer` 音频数据
- 将 Core Media 音频格式转换为 Float 数组
- 处理单声道和立体声音频（将立体声混合为单声道）
- 用于音频处理的高优先级调度队列

**ScreenCaptureKit 的优势**:
- 无需虚拟音频驱动（BlackHole, Loopback）
- 原生捕获所有系统音频输出
- 适用于任何播放音频的应用程序
- 延迟低于虚拟音频路由
- 原生 macOS 13+ 集成

### 5. SpectrumAnalyzer

**文件**: `SpectrumAnalyzer.swift`

**职责**:
- 对音频样本执行 FFT
- 将频率数据转换为可视频带
- 应用平滑处理以实现动画效果
- 发布频谱数据到 UI

**使用的技术**:
- `Accelerate` 框架（Apple 的 SIMD/DSP 库）
- `vDSP_DFT_Execute`: 硬件加速 FFT
- `vDSP_zvmags`: 幅度计算
- `vDSP_blkman_window`: 窗函数

**FFT 配置**:
- FFT 大小: 4096 样本
- 窗口: Blackman-Harris 窗（更好的旁瓣抑制）
- 输出: 32 个对数频带
- 平滑: 独立的攻击/释放因子

**处理管线**:
```
[样本] → [加窗] → [FFT] → [幅度] → [dB 标度] 
→ [归一化] → [频带分组] → [平滑] → [UI 更新]
```

**频带分组**:
- 使用对数分布（更多低音/中音细节）
- 模仿人类听觉感知
- 32 个频带覆盖 20 Hz - 22 kHz
- 每个频带平均其范围内的频率

**数学细节**:
```swift
// 幅度计算
magnitude = sqrt(real² + imaginary²)

// dB 转换
dB = 10 * log10(magnitude)

// 归一化 (假设 -80 到 0 dB 范围)
normalized = (dB + 80) / 80

// 平滑 (指数移动平均)
smoothed = α * previous + (1 - α) * current
```

**设计决策**:
- 使用 `@Published` 的 `ObservableObject` 实现响应式 UI
- 对数频带实现自然的频率感知
- 平滑处理防止动画抖动
- 主线程更新以保证 UI 安全
- 高效使用 Accelerate 以提高性能

**性能特征**:
- FFT: O(n log n) 复杂度
- 在硬件上执行（CPU/GPU 加速）
- 现代 Mac 上每帧约 1-2ms
- 最小内存分配（重用缓冲区）

### 6. SpectrumVisualizerView

**文件**: `SpectrumVisualizerView.swift`

**职责**:
- 在菜单栏中渲染频谱柱
- 动画化柱高度
- 基于强度应用颜色编码
- 适应菜单栏约束

**UI 结构**:
```swift
GeometryReader
  └─ HStack (带间距的柱)
      └─ ForEach (32 个柱)
          └─ SpectrumBar
              └─ VStack
                  └─ Spacer
                  └─ RoundedRectangle
```

**视觉设计**:
- 宽度: 150 点（菜单栏项目大小）
- 高度: 22 点（标准菜单栏高度）
- 32 个柱，1.5pt 间距
- 圆角（1.5pt 半径）
- 底部对齐的柱

**配色方案**:
- **动态渐变**: 颜色根据频率和强度从绿色变为红色
- **峰值指示**: 高强度峰值使用更亮的颜色
- **基础颜色**: 频率相关的色调（低音较暖，高音较冷）

**动画**:
- 隐式 SwiftUI 动画
- 通过 `@Published` 更新实现平滑过渡
- 60 FPS 目标（SwiftUI 处理计时）
- 独立的攻击/释放平滑防止抖动

**设计决策**:
- SwiftUI 用于声明式、简单的渲染
- 底部对齐实现自然的“上升”效果
- 渐变着色提供丰富的视觉反馈
- 最小高度 (1.5pt) 防止柱消失
- `GeometryReader` 实现响应式尺寸

**性能**:
- 非常轻量（仅 32 个矩形）
- SwiftUI 差异算法优化重绘
- GPU 加速渲染
- 无需自定义绘制代码

## 数据流

### 捕获到显示流程

```
1. 用户操作: "开始捕获"
   └─▶ MenuBarController.startCapture()
       └─▶ AudioCaptureManager.startCapture()

2. 权限检查
   └─▶ requestScreenRecordingPermission()
       └─▶ CGRequestScreenCaptureAccess()

3. 音频流开始
   └─▶ SCStream.startCapture()
       └─▶ 音频回调开始

4. 接收音频缓冲区 (48 kHz 速率)
   └─▶ stream(_:didOutputSampleBuffer:of:)
       └─▶ 提取浮点样本
           └─▶ SpectrumAnalyzer.processSamples()

5. FFT 处理 (每个缓冲区)
   └─▶ 应用加窗
       └─▶ 执行 FFT
           └─▶ 计算幅度
               └─▶ 转换为 dB
                   └─▶ 分组到频带
                       └─▶ 应用平滑

6. UI 更新 (主线程)
   └─▶ @Published spectrumBands 改变
       └─▶ 触发 SwiftUI 视图更新
           └─▶ SpectrumVisualizerView.body 重新评估
               └─▶ 柱高度动画化
                   └─▶ 颜色更新
                       └─▶ 渲染到屏幕
```

### 计时特征

- **音频缓冲区速率**: ~10-20 缓冲区/秒（取决于缓冲区大小）
- **FFT 处理**: 每个缓冲区 ~1-2ms
- **UI 更新速率**: 60 FPS（SwiftUI 适当节流）
- **平滑窗口**: ~70% 旧值, 30% 新值（每次更新）
- **总延迟**: ~50-100ms（几乎察觉不到）

## 线程安全

### 线程使用

1. **主线程**:
   - UI 渲染 (SwiftUI)
   - 菜单交互
   - Published 属性更新

2. **音频线程** (实时，高优先级):
   - 音频缓冲区回调
   - FFT 处理
   - 样本提取

3. **调度队列**:
   - 权限请求 (main)
   - UI 更新 (main via DispatchQueue.main.async)

### 同步

- `@Published` 属性自动调度到主线程
- 音频处理发生在实时线程上
- 无需锁（只读数据流）
- 平滑数组访问是线程安全的（原子操作）

## 内存管理

### 分配策略

- **预分配缓冲区**:
  - FFT 缓冲区（实部/虚部）
  - 幅度数组
  - 窗函数数组
  - 全部在 `init()` 中分配一次

- **最小运行时分配**:
  - 仅用于样本复制的 Swift 数组
  - Published 数组更新（写时复制）
  - SwiftUI 视图差异分配

### 资源清理

- AudioCaptureManager 中的 `deinit` 停止引擎
- SpectrumAnalyzer deinit 中销毁 FFT 设置
- AVAudioEngine 处理自己的清理
- 无需手动内存管理 (ARC)

## 配置和调优

### 性能参数

| 参数 | 位置 | 默认值 | 影响 |
|-----------|----------|---------|--------|
| FFT 大小 | SpectrumAnalyzer | 2048 | 频率分辨率 ↑, CPU ↑ |
| 缓冲区大小 | AudioCaptureManager | 4096 | 延迟 ↑, 稳定性 ↑ |
| 频带数量 | SpectrumAnalyzer | 32 | 视觉细节 ↑, CPU ↑ |
| 平滑 | SpectrumAnalyzer | 0.7 | 平滑度 ↑, 响应性 ↓ |
| 柱间距 | SpectrumVisualizerView | 1.5pt | 视觉清晰度 ↑, 柱数量 ↓ |

### 推荐预设

**低功耗模式**:
- FFT 大小: 1024
- 缓冲区大小: 8192
- 频带数量: 16
- 平滑: 0.85

**高细节模式**:
- FFT 大小: 4096
- 缓冲区大小: 2048
- 频带数量: 64
- 平滑: 0.5

## 使用的设计模式

1. **观察者模式**: 
   - SpectrumAnalyzer 发布数据
   - SwiftUI 视图观察变化

2. **中介者模式**:
   - MenuBarController 协调组件
   - 减少子系统之间的耦合

3. **类单例**:
   - AppDelegate 拥有单个实例
   - 无全局状态，仅单实例树

4. **委托模式**:
   - AppDelegate 用于应用生命周期
   - 标准 Cocoa 模式

## 平台特定注意事项

### macOS 集成

- **NSStatusBar**: 遗留 AppKit API（无 SwiftUI 等效项）
- **NSHostingView**: SwiftUI 和 AppKit 之间的桥梁
- **LSUIElement**: Info.plist 键以隐藏 Dock 图标
- **AVAudioEngine**: macOS 音频捕获系统

### 系统要求

- **macOS 13.0+**: Swift 5.9 特性所需
- **Accelerate 框架**: 在所有 Mac 上可用
- **麦克风权限**: 通过 Info.plist 需要

### 沙盒注意事项

- 需要麦克风授权
- 系统音频捕获需要：
  - 虚拟音频驱动 (BlackHole)，或
  - ScreenCaptureKit API (屏幕录制权限)，或
  - 非沙盒构建

## 未来架构改进

### 计划的增强

1. **ScreenCaptureKit 支持**:
   - 添加 SCStream 用于系统音频
   - 实现特定应用捕获
   - 自动回退到麦克风

2. **设置系统**:
   - 用户偏好存储
   - 可自定义颜色/频带
   - 音频设备选择

3. **多种可视化器**:
   - 可视化器样式的插件架构
   - 波形、频谱图、柱状图等
   - 用户可选模式

4. **性能监控**:
   - CPU 使用率跟踪
   - 自适应质量调整
   - 功耗感知处理

### 代码组织

当前结构:
```
YMusicSpectrogram/
├── Sources/
│   ├── YMusicSpectrogramApp.swift    (入口点)
│   ├── MenuBarController.swift       (协调)
│   ├── AudioCaptureManager.swift     (输入)
│   ├── SpectrumAnalyzer.swift        (处理)
│   └── SpectrumVisualizerView.swift  (UI)
└── Resources/
    └── Info.plist                     (配置)
```

未来结构:
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
│   │   └── AudioSource.swift (协议)
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

## 测试策略

### 单元测试

- SpectrumAnalyzer FFT 正确性
- 频带分组逻辑
- 平滑算法
- 样本数据固定装置

### 集成测试

- 音频捕获启动/关闭
- 权限流程
- 组件协调
- 内存泄漏

### UI 测试

- 菜单栏项目存在
- 菜单交互
- 视觉渲染（快照）
- 动画性能

## 性能基准

Apple Silicon Mac 上的目标指标:

- CPU 使用率: < 5% 平均
- 内存使用率: < 50 MB
- 帧率: 60 FPS UI 更新
- 音频延迟: < 100ms
- 功耗影响: 低（活动监视器中的能量影响）

## 结论

架构优先考虑:
1. **简单性**: 清晰、易懂的代码
2. **性能**: 硬件加速、高效算法
3. **模块化**: 松耦合组件
4. **可维护性**: 标准模式、良好的文档
5. **用户体验**: 流畅动画、低资源使用

该设计为未来的增强提供了坚实的基础，同时保持代码库对贡献者友好。
