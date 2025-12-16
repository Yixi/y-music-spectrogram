# Y Music Spectrogram

一个在 macOS 菜单栏显示实时音频频谱可视化的应用程序。

![Menu Bar Spectrogram](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

## 功能特点

- 🎵 **实时音频可视化**：在菜单栏中显示实时频谱分析
- 🎨 **精美动画**：流畅的彩色频率柱状图，性能影响极小
- 🔊 **系统音频捕获**：使用 ScreenCaptureKit 直接捕获所有系统音频输出
- ⚡ **高性能**：利用 Apple Accelerate 框架进行高效的 FFT 处理
- 🎯 **菜单栏集成**：驻留在菜单栏中，保持 Dock 栏整洁

## 架构设计

应用程序由几个核心组件组成：

### 核心组件

1. **AudioCaptureManager**：使用 ScreenCaptureKit 处理系统音频捕获
   - 使用 ScreenCaptureKit API 进行原生系统音频捕获
   - 自动请求屏幕录制权限
   - 实时处理音频缓冲区

2. **SpectrumAnalyzer**：使用 Accelerate 框架执行 FFT 分析
   - 使用 vDSP 进行高效的快速傅里叶变换（4096 采样大小）
   - 将频率分组为 32 个对数频带（20Hz - 20kHz）
   - 应用 Blackman-Harris 窗函数和智能平滑算法以获得更好的视觉效果

3. **SpectrumVisualizerView**：用于渲染频谱的 SwiftUI 视图
   - 显示 32 个动画频率柱
   - 基于频率和强度的动态渐变着色
   - 针对菜单栏显示进行了优化

4. **MenuBarController**：管理状态栏集成
   - 创建和配置菜单栏项目
   - 提供开始/停止控制
   - 集成所有组件

## 构建与运行

### 前置要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

### 使用 Swift Package Manager 构建

```bash
# 克隆仓库
git clone https://github.com/Yixi/y-music-spectrogram.git
cd y-music-spectrogram

# 构建应用程序
swift build -c release

# 运行应用程序
.build/release/YMusicSpectrogram
```

### 使用 Xcode 构建

1. 在 Xcode 中打开项目目录
2. 创建一个新的 macOS App 项目并导入源文件
3. 确保 Info.plist 配置正确
4. 构建并运行 (⌘R)

## 系统音频捕获

✅ **原生系统音频**：本应用使用 **ScreenCaptureKit** 直接捕获所有系统音频输出！

### 工作原理

1. **首次启动**：应用将请求屏幕录制权限
2. **授予权限**：前往 系统设置 > 隐私与安全性 > 屏幕录制
3. **启用应用**：勾选 Y Music Spectrogram 旁边的复选框
4. **重启**：退出并重新启动应用以使权限生效

### 捕获内容

- 所有系统音频输出（音乐、视频、游戏等）
- 无需 BlackHole 等虚拟音频驱动
- 适用于任何播放音频的应用程序
- 原生 macOS 13+ 集成

### 替代方案：BlackHole（可选）

如果您不想授予屏幕录制权限，则需要修改代码以使用麦克风输入并通过 BlackHole 路由音频。当前版本针对 ScreenCaptureKit 进行了优化。

## 使用方法

1. 启动应用程序
2. 出现提示时授予屏幕录制权限（用于系统音频）
3. 频谱可视化器将出现在您的菜单栏中
4. 右键单击菜单栏项目可以：
   - 开始/停止音频捕获
   - 退出应用程序
5. 在 Mac 上播放任何音频即可看到可视化效果！

## 技术细节

### FFT 配置

- **FFT 大小**：4096 采样（高分辨率）
- **采样率**：48 kHz (ScreenCaptureKit)
- **缓冲区大小**：4096 帧
- **频带数量**：32（20Hz - 20kHz 对数分布）
- **窗函数**：Blackman-Harris 窗（更好的信号清晰度）

### 性能

- 使用 Accelerate 框架的 vDSP 进行硬件加速 FFT
- 极低的 CPU 占用率（~2-5%）
- 通过 SwiftUI 实现流畅的 60 FPS 动画

### UI 规格

- **菜单栏宽度**：150 点
- **高度**：22 点（标准菜单栏高度）
- **柱间距**：1.0 点
- **配色方案**：基于频率和强度的动态渐变（绿 -> 黄 -> 红）

## 项目结构

```
y-music-spectrogram/
├── Package.swift
├── README.md
└── YMusicSpectrogram/
    ├── Sources/
    │   ├── YMusicSpectrogramApp.swift      # 应用入口点
    │   ├── MenuBarController.swift          # 菜单栏集成
    │   ├── AudioCaptureManager.swift        # 音频输入处理
    │   ├── SpectrumAnalyzer.swift          # FFT 处理
    │   └── SpectrumVisualizerView.swift    # UI 可视化
    └── Resources/
        └── Info.plist                       # 应用配置
```

## 未来增强

- [ ] ScreenCaptureKit 集成用于原生系统音频捕获
- [ ] 可自定义配色方案
- [ ] 可调节频带数量
- [ ] 峰值保持指示器
- [ ] 音频设备选择
- [ ] 预设可视化样式
- [ ] 导出设置/偏好

## 许可证

MIT License - 随意使用和修改。

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 故障排除

### 未检测到音频输入
- 检查 系统偏好设置 > 安全性与隐私 > 麦克风
- 确保应用拥有麦克风权限
- 对于系统音频，验证 BlackHole 安装和音频 MIDI 设置配置

### 菜单栏项目未显示
- 检查 Info.plist 中 LSUIElement 是否设置为 YES
- 验证应用是否正在运行（检查活动监视器）

### 性能不佳
- 减少 SpectrumAnalyzer 中的频带数量
- 增加平滑因子以减少更新频率

## 致谢

使用 Swift、SwiftUI 和 Apple Accelerate 框架构建 ❤️。