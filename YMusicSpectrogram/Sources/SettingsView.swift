//
//  SettingsView.swift
//  YMusicSpectrogram
//
//  Settings window for customizing spectrum visualization
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var spectrumAnalyzer: SpectrumAnalyzer

    var body: some View {
        Form {
            // MARK: - Section 1: Display Settings
            Section("显示设置") {
                // Band count
                HStack {
                    Text("频带数量")
                    Spacer()
                    Text("\(settings.bandCount)")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.bandCount) },
                        set: { newValue in
                            let count = Int(newValue)
                            settings.bandCount = count
                            spectrumAnalyzer.updateBandCount(count)
                        }
                    ),
                    in: 8...64,
                    step: 4
                )

                // Bar spacing
                HStack {
                    Text("柱状图间距")
                    Spacer()
                    Text(String(format: "%.1f pt", settings.barSpacing))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                Slider(value: $settings.barSpacing, in: 0.5...3.0, step: 0.5)

                // Sensitivity
                HStack {
                    Text("灵敏度")
                    Spacer()
                    Text(String(format: "%.1fx", settings.sensitivity))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                Slider(
                    value: Binding(
                        get: { settings.sensitivity },
                        set: { newValue in
                            settings.sensitivity = newValue
                            spectrumAnalyzer.updateSensitivity(newValue)
                        }
                    ),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }

            // MARK: - Section 2: Color Scheme
            Section("配色方案") {
                Picker("颜色方案", selection: $settings.colorScheme) {
                    ForEach(SettingsManager.ColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }

                // Spectrum preview bar
                SpectrumPreviewBar(settings: settings)
                    .frame(height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Custom color controls (conditional with animation)
                if settings.colorScheme == .custom || settings.colorScheme == .monochrome {
                    VStack(spacing: 12) {
                        HStack {
                            Text("色相")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $settings.baseColorHue, in: 0...1)
                        }

                        HStack {
                            Text("饱和度")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $settings.baseColorSaturation, in: 0...1)
                        }

                        HStack {
                            Text("明度")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $settings.baseColorBrightness, in: 0...1)
                        }

                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(
                                    hue: settings.baseColorHue,
                                    saturation: settings.baseColorSaturation,
                                    brightness: settings.baseColorBrightness
                                ))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: settings.colorScheme)
                }
            }

            // MARK: - Section 3: General
            Section("通用") {
                Toggle("开机自启动", isOn: $settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .frame(width: 480, height: 520)
    }
}

// MARK: - Spectrum Preview Bar

struct SpectrumPreviewBar: View {
    @ObservedObject var settings: SettingsManager

    // Simulated spectrum data: hill shape (higher in the middle)
    private let previewData: [CGFloat] = (0..<16).map { i in
        let x = CGFloat(i) / 15.0
        return 0.3 + 0.7 * sin(x * .pi)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<16, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(settings.getBarColor(index: index, totalBars: 16, magnitude: previewData[index]))
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

// Preview provider for development
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let analyzer = SpectrumAnalyzer()
        SettingsView(spectrumAnalyzer: analyzer)
    }
}
