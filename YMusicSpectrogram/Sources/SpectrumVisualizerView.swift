//
//  SpectrumVisualizerView.swift
//  YMusicSpectrogram
//
//  SwiftUI view for rendering the spectrum visualization in the menu bar
//

import SwiftUI

struct SpectrumVisualizerView: View {
    @ObservedObject var spectrumAnalyzer: SpectrumAnalyzer
    
    private let barSpacing: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<spectrumAnalyzer.spectrumBands.count, id: \.self) { index in
                    SpectrumBar(
                        magnitude: CGFloat(spectrumAnalyzer.spectrumBands[index]),
                        maxHeight: geometry.size.height,
                        index: index,
                        totalBars: spectrumAnalyzer.spectrumBands.count
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
        }
        .frame(height: 22)
    }
}

struct SpectrumBar: View {
    let magnitude: CGFloat
    let maxHeight: CGFloat
    let index: Int
    let totalBars: Int
    
    private let minHeight: CGFloat = 1.5
    private let cornerRadius: CGFloat = 1.0
    private let settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(barGradient)
                .frame(height: barHeight)
        }
    }
    
    private var barHeight: CGFloat {
        let usableHeight = maxHeight - 2
        let computedHeight = magnitude * usableHeight
        return max(minHeight, min(computedHeight, usableHeight))
    }
    
    private var barGradient: LinearGradient {
        // Create a gradient that goes from bottom color to top color based on magnitude
        let bottomColor = baseColor.opacity(0.8)
        let topColor = peakColor
        
        return LinearGradient(
            gradient: Gradient(colors: [bottomColor, topColor]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private var baseColor: Color {
        // Use color from settings manager
        return settings.getBarColor(index: index, totalBars: totalBars, magnitude: magnitude)
    }
    
    private var peakColor: Color {
        // Use peak color from settings manager
        return settings.getPeakColor(magnitude: magnitude)
    }
}

// Preview provider for development
struct SpectrumVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        let analyzer = SpectrumAnalyzer()
        // Simulate some spectrum data for preview
        analyzer.spectrumBands = (0..<32).map { i in
            Float.random(in: 0...1) * (1.0 - Float(i) / 32.0)
        }
        
        return SpectrumVisualizerView(spectrumAnalyzer: analyzer)
            .frame(width: 150, height: 22)
            .background(Color.black.opacity(0.1))
    }
}
