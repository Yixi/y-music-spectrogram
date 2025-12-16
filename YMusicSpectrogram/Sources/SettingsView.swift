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
        VStack(alignment: .leading, spacing: 20) {
            Text("Spectrum Settings")
                .font(.title)
                .padding(.bottom, 10)
            
            // Band Count Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Spectrum Bars")
                    .font(.headline)
                
                HStack {
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
                    
                    Text("\(settings.bandCount)")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
                
                Text("More bars = more detail (uses more CPU)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Color Scheme Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Scheme")
                    .font(.headline)
                
                Picker("Color Scheme", selection: $settings.colorScheme) {
                    ForEach(SettingsManager.ColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.rawValue).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                
                // Show custom color controls if custom scheme is selected
                if settings.colorScheme == .custom || settings.colorScheme == .monochrome {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Color")
                            .font(.subheadline)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("Hue:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $settings.baseColorHue, in: 0...1)
                            Circle()
                                .fill(Color(hue: settings.baseColorHue, saturation: settings.baseColorSaturation, brightness: settings.baseColorBrightness))
                                .frame(width: 30, height: 30)
                        }
                        
                        HStack {
                            Text("Saturation:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $settings.baseColorSaturation, in: 0...1)
                        }
                        
                        HStack {
                            Text("Brightness:")
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $settings.baseColorBrightness, in: 0...1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Info Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Info")
                    .font(.headline)
                
                Text("Changes are applied immediately")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Settings are saved automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 500, height: 450)
    }
}

// Preview provider for development
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let analyzer = SpectrumAnalyzer()
        SettingsView(spectrumAnalyzer: analyzer)
    }
}
