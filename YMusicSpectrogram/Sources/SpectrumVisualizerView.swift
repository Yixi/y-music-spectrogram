//
//  SpectrumVisualizerView.swift
//  YMusicSpectrogram
//
//  SwiftUI view for rendering the spectrum visualization in the menu bar
//

import SwiftUI

struct SpectrumVisualizerView: View {
    @ObservedObject var spectrumAnalyzer: SpectrumAnalyzer
    
    private let barSpacing: CGFloat = 1.5
    private let cornerRadius: CGFloat = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<spectrumAnalyzer.spectrumBands.count, id: \.self) { index in
                    SpectrumBar(
                        magnitude: CGFloat(spectrumAnalyzer.spectrumBands[index]),
                        maxHeight: geometry.size.height
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .frame(height: 22)
    }
}

struct SpectrumBar: View {
    let magnitude: CGFloat
    let maxHeight: CGFloat
    
    private let minHeight: CGFloat = 2
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 1.5)
                .fill(barColor)
                .frame(height: max(minHeight, magnitude * (maxHeight - 4)))
        }
    }
    
    private var barColor: Color {
        // Color gradient based on magnitude
        if magnitude > 0.7 {
            return Color(red: 1.0, green: 0.3, blue: 0.3) // Red for high
        } else if magnitude > 0.4 {
            return Color(red: 1.0, green: 0.8, blue: 0.2) // Yellow for medium
        } else {
            return Color(red: 0.3, green: 0.8, blue: 0.3) // Green for low
        }
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
