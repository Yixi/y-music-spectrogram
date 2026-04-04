# Y Music Spectrogram - UI/UX 设计规范

> 版本: v1.1 | 日期: 2026-04-04 | 作者: Designer
> 
> v1.1 更新: 新增毛玻璃效果方案（十三章）、修复文字对齐规范（四章更新）

---

## 一、设计原则

1. **macOS 原生风格** — 使用系统标准控件（Form、Section、Toggle、Slider、Picker），不自定义花哨组件
2. **亮暗模式自适应** — 全部使用系统语义颜色（`Color.primary`、`Color.secondary`、`Color(.windowBackgroundColor)` 等），不硬编码颜色值
3. **信息层次清晰** — 通过 Section 分组、字体层级、间距控制视觉层次
4. **即时反馈** — 设置变更实时反映到频谱可视化
5. **中文优先** — 所有用户可见文字使用中文

---

## 二、颜色体系

### 2.1 语义颜色（亮暗模式自适应）

| 用途 | SwiftUI 颜色 | 说明 |
|------|-------------|------|
| 主文字 | `Color.primary` | 标题、正文 |
| 辅助文字 | `Color.secondary` | 描述、提示 |
| 强调色 | `Color.accentColor` | 控件高亮、链接（系统蓝） |
| 窗口背景 | 系统自动（Form 默认） | 不需手动设置 |
| 分组背景 | 系统自动（Section 默认） | Form + Section 自带分组背景 |
| 分隔线 | `Divider()` 系统默认 | 自动适配 |

### 2.2 频谱配色方案

保持现有 5 种颜色方案，颜色值不变：

| 方案 | 说明 | HSB 范围 |
|------|------|---------|
| 彩虹 | 全光谱渐变 | H: 0.0→1.0, S: 0.8, B: 0.9 |
| 绿→红 | 低频绿高频红 | H: 0.35→0.0, S: 0.8, B: 0.9 |
| 蓝→红 | 低频蓝高频红 | H: 0.6→0.0, S: 0.8, B: 0.9 |
| 单色 | 单色明度渐变 | H: 用户自定, S: 用户自定, B: 0.5→1.0 |
| 自定义 | 用户自定底色 | H/S/B: 用户自定, H 偏移 ±0.05 |

### 2.3 配色方案中文映射

```swift
// ColorScheme rawValue 改为中文显示
// 内部枚举值保持英文，显示名称用 displayName 计算属性
enum ColorScheme: String, CaseIterable {
    case rainbow = "Rainbow"
    case greenToRed = "Green to Red"
    case blueToRed = "Blue to Red"
    case monochrome = "Monochrome"
    case custom = "Custom"
    
    var displayName: String {
        switch self {
        case .rainbow: return "彩虹"
        case .greenToRed: return "绿→红"
        case .blueToRed: return "蓝→红"
        case .monochrome: return "单色"
        case .custom: return "自定义"
        }
    }
}
```

---

## 三、字体规范

| 层级 | SwiftUI Font | 使用场景 |
|------|-------------|---------|
| 窗口标题 | `.title2` | 关于窗口应用名 |
| Section 标题 | 系统自动（Section header） | 设置窗口分组标题 |
| 正文标签 | `.body`（系统默认） | 设置项标签 |
| 数值显示 | `.body.monospacedDigit()` | 滑块当前值 |
| 辅助说明 | `.caption` + `Color.secondary` | 设置项描述 |
| 版本号 | `.caption` + `Color.secondary` | 关于窗口版本 |

---

## 四、设置窗口设计（P0-1）

### 4.1 窗口属性

```swift
// 窗口配置
窗口标题: "频谱设置"
窗口尺寸: NSRect(x: 0, y: 0, width: 480, height: 520)
styleMask: [.titled, .closable, .miniaturizable]
居中显示: window.center()
isReleasedWhenClosed: false
```

### 4.2 整体布局

使用 SwiftUI `Form` 作为根容器，内含三个 `Section`：

```
┌─────────────────────────────────────────┐
│  频谱设置                          [关闭] │
├─────────────────────────────────────────┤
│                                         │
│  显示设置                                │
│  ┌─────────────────────────────────────┐│
│  │ 频带数量          ◯━━━━━━━━━● 32   ││
│  │ 柱状图间距        ◯━━━●━━━━━  1.5  ││
│  │ 灵敏度            ◯━━━━━●━━━  1.0x ││
│  └─────────────────────────────────────┘│
│                                         │
│  配色方案                                │
│  ┌─────────────────────────────────────┐│
│  │ 颜色方案    [彩虹|绿→红|蓝→红|...]  ││
│  │                                     ││
│  │ ┌─ 频谱预览 ───────────────────┐    ││
│  │ │  ▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐▌    │    ││
│  │ └──────────────────────────────┘    ││
│  │                                     ││
│  │ （自定义颜色区域 - 条件显示）          ││
│  │   色相      ◯━━━━●━━━━━  ●          ││
│  │   饱和度    ◯━━━━━━━●━━             ││
│  │   明度      ◯━━━━━━━━●━             ││
│  └─────────────────────────────────────┘│
│                                         │
│  通用                                    │
│  ┌─────────────────────────────────────┐│
│  │ 开机自启动                    [开关] ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

### 4.3 Section 1: 显示设置

> **v1.1 修复**: 数值显示宽度统一为 50pt，解决不同设置项数值列不对齐的问题。

```swift
Section("显示设置") {
    // 频带数量
    HStack {
        Text("频带数量")
        Spacer()
        Text("\(settings.bandCount)")
            .foregroundColor(.secondary)
            .monospacedDigit()
            .frame(width: 50, alignment: .trailing)  // 统一 50pt
    }
    Slider(
        value: Binding(get: { Double(settings.bandCount) },
                       set: { settings.bandCount = Int($0); spectrumAnalyzer.updateBandCount(Int($0)) }),
        in: 8...64,
        step: 4
    )
    
    // 柱状图间距
    HStack {
        Text("柱状图间距")
        Spacer()
        Text(String(format: "%.1f pt", settings.barSpacing))
            .foregroundColor(.secondary)
            .monospacedDigit()
            .frame(width: 50, alignment: .trailing)  // 统一 50pt
    }
    Slider(value: $settings.barSpacing, in: 0.5...3.0, step: 0.5)
    
    // 灵敏度
    HStack {
        Text("灵敏度")
        Spacer()
        Text(String(format: "%.1fx", settings.sensitivity))
            .foregroundColor(.secondary)
            .monospacedDigit()
            .frame(width: 50, alignment: .trailing)  // 统一 50pt
    }
    Slider(value: $settings.sensitivity, in: 0.5...2.0, step: 0.1)
}
```

**设计参数:**
- 频带数量: 范围 8-64, 步进 4, 默认 32
- 柱状图间距: 范围 0.5-3.0 pt, 步进 0.5, 默认 1.0
- 灵敏度: 范围 0.5x-2.0x, 步进 0.1, 默认 1.0
- **数值显示宽度统一 50pt**（可容纳最宽格式 "3.0 pt"，同时数值列右端对齐）

### 4.4 Section 2: 配色方案

```swift
Section("配色方案") {
    // 颜色方案选择器
    Picker("颜色方案", selection: $settings.colorScheme) {
        ForEach(SettingsManager.ColorScheme.allCases, id: \.self) { scheme in
            Text(scheme.displayName).tag(scheme)
        }
    }
    
    // 频谱预览条
    SpectrumPreviewBar(colorScheme: settings.colorScheme, settings: settings)
        .frame(height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    
    // 自定义颜色区域（条件显示，带动画）
    // v1.1 修复: 标签宽度从 50pt 改为 60pt，确保"饱和度"三字完整显示
    if settings.colorScheme == .custom || settings.colorScheme == .monochrome {
        VStack(spacing: 12) {
            LabeledSlider(label: "色相", value: $settings.baseColorHue, range: 0...1, labelWidth: 60)
            LabeledSlider(label: "饱和度", value: $settings.baseColorSaturation, range: 0...1, labelWidth: 60)
            LabeledSlider(label: "明度", value: $settings.baseColorBrightness, range: 0...1, labelWidth: 60)
            
            // 颜色预览圆点
            HStack {
                Spacer()
                Circle()
                    .fill(Color(hue: settings.baseColorHue,
                                saturation: settings.baseColorSaturation,
                                brightness: settings.baseColorBrightness))
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: settings.colorScheme)
    }
}
```

**频谱预览条（SpectrumPreviewBar）设计:**

```swift
// 静态预览条，模拟频谱效果让用户预览配色
// 使用固定的模拟数据，不需要实时音频
struct SpectrumPreviewBar: View {
    // 模拟频谱数据：中间高两边低的山丘形
    private let previewData: [CGFloat] = (0..<16).map { i in
        let x = CGFloat(i) / 15.0
        return 0.3 + 0.7 * sin(x * .pi)  // 正弦曲线模拟
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<16, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(/* 使用当前配色方案的颜色 */)
                        .frame(height: previewData[index] * geometry.size.height)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .background(Color.primary.opacity(0.05))
    }
}
```

**预览条参数:**
- 高度: 28pt
- 柱数量: 16（固定，仅用于预览）
- 柱间距: 2pt
- 圆角: 外框 6pt, 柱 1.5pt
- 背景: `Color.primary.opacity(0.05)`（亮暗模式自适应）

### 4.5 Section 3: 通用设置

```swift
Section("通用") {
    Toggle("开机自启动", isOn: $settings.launchAtLogin)
}
```

### 4.6 动效参数

| 动效 | 参数 | 说明 |
|------|------|------|
| 自定义颜色区域展开/收起 | `.animation(.easeInOut(duration: 0.2), value: colorScheme)` | 方案切换时平滑过渡 |
| 颜色预览更新 | `.animation(.easeOut(duration: 0.15), value: baseColorHue)` | 拖拽滑块时颜色实时更新 |

---

## 五、菜单栏右键菜单设计（P0-2）

### 5.1 菜单结构

```
┌──────────────────────────────┐
│ 🎛  频谱设置...          ⌘,  │
├──────────────────────────────┤
│ 🟢 停止捕获                  │  ← 捕获中时显示（绿色圆点）
│ 🔴 开始捕获                  │  ← 未捕获时显示（红色圆点）
├──────────────────────────────┤
│ ℹ️  关于 Y Music Spectrogram │
│     退出                 ⌘Q  │
└──────────────────────────────┘
```

### 5.2 菜单项定义

```swift
// 1. 频谱设置
let settingsItem = NSMenuItem(title: "频谱设置...", action: #selector(openSettings), keyEquivalent: ",")
settingsItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "设置")

// 2. 分隔线
menu.addItem(NSMenuItem.separator())

// 3. 捕获控制（根据状态动态切换，只显示一个）
// 捕获中 → 显示「停止捕获」
let stopItem = NSMenuItem(title: "停止捕获", action: #selector(stopCapture), keyEquivalent: "")
stopItem.image = NSImage(systemSymbolName: "stop.circle", accessibilityDescription: "停止")
// 给图标着绿色表示当前正在运行
// stopItem.image 使用带绿色的 SF Symbol 配置:
// let config = NSImage.SymbolConfiguration(paletteColors: [.systemGreen])
// stopItem.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
//     .withSymbolConfiguration(config)
// 附加文字图标方案（更简洁）:

// 未捕获 → 显示「开始捕获」  
let startItem = NSMenuItem(title: "开始捕获", action: #selector(startCapture), keyEquivalent: "")
startItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: "开始")

// 4. 分隔线
menu.addItem(NSMenuItem.separator())

// 5. 关于
let aboutItem = NSMenuItem(title: "关于 Y Music Spectrogram", action: #selector(openAbout), keyEquivalent: "")
aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "关于")

// 6. 退出
let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
```

### 5.3 SF Symbols 使用清单

| 菜单项 | SF Symbol 名称 | 说明 |
|--------|---------------|------|
| 频谱设置 | `slider.horizontal.3` | 设置齿轮 |
| 开始捕获 | `play.circle` | 播放按钮 |
| 停止捕获 | `stop.circle` | 停止按钮 |
| 关于 | `info.circle` | 信息 |
| 退出 | 无图标 | 保持简洁 |

### 5.4 状态切换逻辑

```swift
// MenuBarController 需要维护捕获状态
// 方案: 通过 NSMenu 的 delegate (menuNeedsUpdate) 动态构建菜单项
// 或在每次状态变化时更新菜单项的 isHidden 属性

// 推荐方案: 使用 menuNeedsUpdate 委托
// 每次菜单即将显示时，根据 audioCaptureManager.isCapturing 状态
// 动态显示「开始捕获」或「停止捕获」
```

---

## 六、关于窗口设计（P0-3）

### 6.1 窗口属性

```swift
// 窗口配置
窗口标题: "关于"（或隐藏标题栏文字）
窗口尺寸: NSRect(x: 0, y: 0, width: 300, height: 200)
styleMask: [.titled, .closable]
居中显示: window.center()
isReleasedWhenClosed: false
```

### 6.2 布局设计

```
┌───────────────────────────────┐
│                               │
│         🎵 (48pt 图标)        │
│                               │
│    Y Music Spectrogram        │  ← .title2, .bold
│        版本 1.0.0             │  ← .caption, .secondary
│                               │
│  macOS 菜单栏实时音频频谱可视化  │  ← .caption, .secondary
│                               │
│   Copyright © 2026 Yixi      │  ← .caption, .secondary
│                               │
└───────────────────────────────┘
```

### 6.3 SwiftUI 实现参考

```swift
struct AboutView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // 应用图标
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)  // 使用系统强调色
            
            // 应用名称
            Text("Y Music Spectrogram")
                .font(.title2)
                .fontWeight(.bold)
            
            // 版本号（从 Bundle 读取）
            Text("版本 \(bundleVersion)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 4)
            
            // 描述
            Text("macOS 菜单栏实时音频频谱可视化")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 版权
            Text("Copyright © 2026 Yixi")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(width: 300, height: 200)
    }
    
    private var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
```

### 6.4 设计参数

| 元素 | 参数 |
|------|------|
| 图标尺寸 | 48pt (`.font(.system(size: 48))`) |
| 图标颜色 | `.tint`（系统强调色，自适应亮暗模式）|
| 图标与应用名间距 | 8pt（VStack spacing 默认） |
| 应用名字体 | `.title2` + `.bold` |
| 其他文字字体 | `.caption` + `Color.secondary` |
| 各元素间距 | 8pt（VStack spacing） |
| 描述与版本间额外间距 | 4pt (Spacer) |

---

## 七、错误提示设计（P0-4）

### 7.1 权限被拒绝 — Alert 对话框

**触发时机:** ScreenCaptureKit 权限被用户拒绝时

```swift
// NSAlert 配置
let alert = NSAlert()
alert.alertStyle = .warning
alert.messageText = "需要屏幕录制权限"
alert.informativeText = "Y Music Spectrogram 需要屏幕录制权限来捕获系统音频。\n\n请在「系统设置 → 隐私与安全性 → 屏幕录制」中允许本应用。"
alert.addButton(withTitle: "打开系统设置")
alert.addButton(withTitle: "稍后再说")

// 点击「打开系统设置」时
// NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
```

**文案参数:**
- 图标样式: `.warning`（系统黄色警告三角）
- 标题: "需要屏幕录制权限"
- 正文: 如上，包含操作路径指引
- 主按钮: "打开系统设置"
- 副按钮: "稍后再说"

### 7.2 首次启动权限引导

**触发时机:** 首次启动，权限状态未决定时

```swift
let alert = NSAlert()
alert.alertStyle = .informational
alert.messageText = "音频捕获需要权限"
alert.informativeText = "Y Music Spectrogram 使用屏幕录制权限捕获系统音频进行频谱分析。\n\n授权后即可在菜单栏看到实时音频频谱。"
alert.addButton(withTitle: "好的")
```

**文案参数:**
- 图标样式: `.informational`（系统蓝色信息图标）
- 标题: "音频捕获需要权限"
- 正文: 解释为什么需要权限
- 按钮: "好的"（单按钮，仅告知）

### 7.3 捕获失败 — 菜单栏错误状态

**触发时机:** 音频捕获启动失败

```swift
// 菜单栏显示错误状态图标替代频谱
// SF Symbol: "waveform.badge.exclamationmark"（macOS 14+）
// 兼容方案: "exclamationmark.triangle"（macOS 13+）

// 在 MenuBarController 中：
// 隐藏 SpectrumVisualizerView
// 显示静态错误图标
button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "捕获异常")
```

### 7.4 错误回调设计

```swift
// AudioCaptureManager 新增错误回调
enum CaptureError {
    case permissionDenied      // 权限被拒绝
    case permissionNotDecided  // 权限未决定（首次）
    case captureFailed(Error)  // 捕获启动失败
}

// 回调闭包
var onError: ((CaptureError) -> Void)?

// MenuBarController 处理逻辑:
// .permissionDenied → 弹出 7.1 的 Alert
// .permissionNotDecided → 弹出 7.2 的 Alert
// .captureFailed → 菜单栏显示 7.3 的错误图标
```

---

## 八、频谱可视化（小改）

### 8.1 柱状图间距可配置

```swift
// SpectrumVisualizerView 中
// 将 barSpacing 从固定值改为读取设置
private var barSpacing: CGFloat {
    CGFloat(SettingsManager.shared.barSpacing)
}
```

### 8.2 保持现有视觉效果

当前频谱柱状图的渐变效果（底色 → 峰值色）保持不变：
- 底部: `baseColor.opacity(0.8)`
- 顶部: `peakColor`（根据振幅动态变色）
- 最小高度: 1.5pt
- 圆角: 1.0pt

---

## 九、SettingsManager 新增属性

```swift
// 新增 UserDefaults keys
private enum Keys {
    // ... 现有 keys ...
    static let barSpacing = "barSpacing"
    static let sensitivity = "sensitivity"
    static let launchAtLogin = "launchAtLogin"
}

// 新增 Published 属性
@Published var barSpacing: Double {
    didSet { UserDefaults.standard.set(barSpacing, forKey: Keys.barSpacing) }
}
// 默认值: 1.0, 范围: 0.5-3.0, 步进: 0.5

@Published var sensitivity: Double {
    didSet { UserDefaults.standard.set(sensitivity, forKey: Keys.sensitivity) }
}
// 默认值: 1.0, 范围: 0.5-2.0, 步进: 0.1

@Published var launchAtLogin: Bool {
    didSet {
        UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        // 调用 SMAppService.mainApp.register() / unregister()
    }
}
// 默认值: false

// init() 中加载
self.barSpacing = UserDefaults.standard.object(forKey: Keys.barSpacing) as? Double ?? 1.0
self.sensitivity = UserDefaults.standard.object(forKey: Keys.sensitivity) as? Double ?? 1.0
self.launchAtLogin = UserDefaults.standard.object(forKey: Keys.launchAtLogin) as? Bool ?? false
```

---

## 十、尺寸与间距汇总

### 10.1 窗口尺寸

| 窗口 | 宽度 | 高度 |
|------|------|------|
| 设置窗口 | 480pt | 520pt |
| 关于窗口 | 300pt | 200pt |

### 10.2 菜单栏

| 参数 | 值 |
|------|-----|
| 频谱宽度 | 150pt（不变） |
| 频谱高度 | 22pt（标准菜单栏高度） |
| 柱最小高度 | 1.5pt |
| 柱圆角 | 1.0pt |
| 柱间距 | 用户可配置，0.5-3.0pt，默认 1.0pt |
| 水平内边距 | 2pt |
| 垂直内边距 | 1pt |

### 10.3 设置窗口频谱预览条

| 参数 | 值 |
|------|-----|
| 高度 | 28pt |
| 预览柱数量 | 16（固定） |
| 预览柱间距 | 2pt |
| 预览柱圆角 | 1.5pt |
| 外框圆角 | 6pt |
| 背景色 | `Color.primary.opacity(0.05)` |
| 水平内边距 | 4pt |
| 垂直内边距 | 2pt |

### 10.4 关于窗口

| 参数 | 值 |
|------|-----|
| 图标尺寸 | 48pt |
| 元素间距 | 8pt (VStack spacing) |
| 版本与描述间额外间距 | 4pt |

---

## 十一、完整文件变更清单

| 文件 | 设计相关变更 |
|------|-------------|
| `SettingsView.swift` | 重写为 Form + Section 布局，三个分区，中文标签，新增预览条和新设置项 |
| `SettingsManager.swift` | 新增 `barSpacing`/`sensitivity`/`launchAtLogin` 属性，新增 `displayName` 计算属性 |
| `MenuBarController.swift` | 菜单项中文化 + SF Symbols 图标，状态动态切换，新增关于窗口，错误 Alert 处理 |
| `SpectrumVisualizerView.swift` | `barSpacing` 改为读取设置 |
| `AudioCaptureManager.swift` | 新增 `CaptureError` 枚举和 `onError` 回调 |
| `SpectrumAnalyzer.swift` | 灵敏度参数可配置（读取 `sensitivity` 调整 dB 范围）|

---

## 十二、设计 Checklist

- [ ] 设置窗口使用 Form + Section，三区分组
- [ ] 所有用户可见文字为中文
- [ ] 配色方案 Picker 显示中文名称
- [ ] 频谱预览条展示当前配色效果
- [ ] 自定义颜色区域有展开/收起动画
- [ ] 菜单项带 SF Symbols 图标
- [ ] 捕获状态动态切换（开始/停止只显示一个）
- [ ] 关于窗口居中简洁布局
- [ ] 权限拒绝时弹出 Alert 并可跳转系统设置
- [ ] 首次启动权限引导 Alert
- [ ] 亮/暗模式下所有界面显示正常（使用语义颜色）
- [ ] 设置窗口毛玻璃效果（v1.1）
- [ ] 自定义颜色标签宽度 60pt 无截断（v1.1）
- [ ] 数值显示宽度统一 50pt 右对齐（v1.1）

---

## 十三、设置窗口毛玻璃效果（v1.1 新增）

### 13.1 设计目标

为设置窗口添加 macOS 原生毛玻璃（Vibrancy）效果，使窗口背景呈现半透明磨砂质感，与桌面/背后窗口产生景深层次。

### 13.2 技术方案

**推荐方案: SwiftUI `.scrollContentBackground(.hidden)` + `.background(.ultraThinMaterial)`**

这是最简洁的 SwiftUI 原生方案，兼容 macOS 13+：

```swift
// SettingsView.swift 中
Form {
    Section("显示设置") { ... }
    Section("配色方案") { ... }
    Section("通用") { ... }
}
.formStyle(.grouped)
.scrollContentBackground(.hidden)    // 隐藏 Form 默认的不透明背景
.background(.ultraThinMaterial)      // 添加毛玻璃材质
.frame(width: 480, height: 520)
```

**窗口配置（MenuBarController 中）:**

```swift
// 创建设置窗口时，设置窗口背景透明以配合毛玻璃
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
    styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
    backing: .buffered,
    defer: false
)
window.title = "频谱设置"
window.titlebarAppearsTransparent = true   // 标题栏融入毛玻璃
window.backgroundColor = .clear            // 窗口背景透明
window.isMovableByWindowBackground = true  // 允许拖动窗口背景移动
```

### 13.3 材质选择说明

| SwiftUI Material | 视觉效果 | 适用场景 |
|-----------------|---------|---------|
| `.ultraThinMaterial` | 最轻微模糊，高透明度 | **推荐** — 设置窗口，透出桌面但不喧宾夺主 |
| `.thinMaterial` | 轻度模糊 | 备选 — 如果 ultraThin 效果不够明显 |
| `.regularMaterial` | 标准模糊 | 侧边栏风格，较重 |
| `.thickMaterial` | 重度模糊，低透明度 | 不推荐 — 对设置窗口过重 |
| `.ultraThickMaterial` | 近乎不透明 | 不推荐 |

**设计决策:** 选择 `.ultraThinMaterial`，原因：
1. 保持设置内容的可读性（Form 文字不会被背景干扰）
2. 提供恰到好处的景深层次感
3. 与 macOS 系统设置窗口风格一致
4. 亮/暗模式下都有良好表现

### 13.4 与 Form 组件的配合

```
┌─ 窗口 ──────────────────────────────────┐
│  titlebar (透明，融入毛玻璃)              │
├─────────────────────────────────────────┤
│ ┌─ .ultraThinMaterial 背景 ───────────┐ │
│ │                                     │ │
│ │  Section 分组卡片                    │ │
│ │  ┌───────────────────────────────┐  │ │
│ │  │ 系统默认 Section 背景          │  │ │
│ │  │ （半透明白/深灰，自适应模式）    │  │ │
│ │  └───────────────────────────────┘  │ │
│ │                                     │ │
│ │  毛玻璃背景在 Section 之间的间隙    │ │
│ │  透出桌面内容                       │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**层次关系（从下到上）:**
1. 桌面/背后窗口内容
2. `.ultraThinMaterial` 毛玻璃层（模糊背后内容）
3. Section 分组卡片（系统默认半透明背景）
4. Form 控件内容（文字、滑块等）

**注意事项:**
- `.scrollContentBackground(.hidden)` 隐藏的是 Form 的整体滚动区域背景，不影响 Section 的分组卡片背景
- Section 卡片保留系统默认样式（亮模式白色半透明、暗模式深灰半透明），在毛玻璃上自然浮起
- 无需手动设置 Section 背景色，系统自动处理

### 13.5 styleMask 变更

新增 `.fullSizeContentView` 使内容区延伸到标题栏下方：

```swift
// 之前:
styleMask: [.titled, .closable, .miniaturizable]

// 之后:
styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]
```

配合 `titlebarAppearsTransparent = true`，标题栏区域也会显示毛玻璃效果，窗口整体更加一体化。

---

## 十四、文字对齐修复方案（v1.1 新增）

### 14.1 问题分析

当前 `SettingsView.swift` 中存在两处对齐问题：

**问题 A: 自定义颜色标签宽度不足**

```swift
// 当前代码 (SettingsView.swift:91-103)
Text("色相").frame(width: 50, alignment: .leading)    // "色相" 2字 ≈ 28pt ✅
Text("饱和度").frame(width: 50, alignment: .leading)  // "饱和度" 3字 ≈ 45pt ⚠️ 临界截断
Text("明度").frame(width: 50, alignment: .leading)    // "明度" 2字 ≈ 28pt ✅
```

中文 `.body` 字体下，每个汉字约 14-17pt 宽。"饱和度"三字在 50pt 宽度下会紧贴边缘甚至截断。

**修复:** 标签宽度改为 **60pt**，为三字标签留出充足空间。

**问题 B: 数值显示宽度不统一**

```swift
// 当前代码中三个数值列宽度不同:
Text("\(settings.bandCount)")           .frame(width: 30)  // "32"
Text(String(format: "%.1f pt", ...))    .frame(width: 50)  // "1.5 pt"
Text(String(format: "%.1fx", ...))      .frame(width: 40)  // "1.0x"
```

虽然各自能容纳内容，但数值列右端不对齐，视觉上参差不齐。

**修复:** 全部统一为 **50pt**。最宽的格式 "3.0 pt" 约需 45pt，50pt 可确保所有格式舒适显示且右端对齐。

### 14.2 修复代码

**SettingsView.swift 需要修改的位置:**

```swift
// 修复 A: 自定义颜色标签宽度 50pt → 60pt
// 第 91 行
Text("色相").frame(width: 60, alignment: .leading)      // 改为 60
// 第 95 行  
Text("饱和度").frame(width: 60, alignment: .leading)    // 改为 60
// 第 99 行
Text("明度").frame(width: 60, alignment: .leading)      // 改为 60

// 修复 B: 数值显示宽度统一为 50pt
// 第 25 行 (频带数量)
.frame(width: 50, alignment: .trailing)                 // 30 → 50
// 第 47 行 (柱状图间距)  
.frame(width: 50, alignment: .trailing)                 // 50 不变
// 第 58 行 (灵敏度)
.frame(width: 50, alignment: .trailing)                 // 40 → 50
```

### 14.3 修复前后对比

```
修复前:                              修复后:
频带数量        32│                  频带数量              32│
柱状图间距  1.5 pt│                  柱状图间距         1.5 pt│
灵敏度       1.0x│                  灵敏度              1.0x│
         ↑ 数值列不对齐                          ↑ 数值列右端整齐对齐

色相    ◯━━━━━━━                    色相      ◯━━━━━━━
饱和度◯━━━━━━━━  ← 截断风险         饱和度    ◯━━━━━━━━  ← 充足空间
明度    ◯━━━━━━━                    明度      ◯━━━━━━━
     ↑ 50pt 紧贴                          ↑ 60pt 舒适
```
