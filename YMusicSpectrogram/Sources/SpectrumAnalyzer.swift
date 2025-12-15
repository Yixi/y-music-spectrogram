//
//  SpectrumAnalyzer.swift
//  YMusicSpectrogram
//
//  Performs FFT analysis on audio samples using the Accelerate framework
//

import Accelerate
import Foundation

class SpectrumAnalyzer: ObservableObject {
    // Published property for SwiftUI updates
    @Published var spectrumBands: [Float] = Array(repeating: 0, count: 32)
    
    // FFT Configuration
    private let fftSize: Int = 2048
    private var fftSetup: vDSP_DFT_Setup?
    
    // Buffers for FFT processing
    private var realParts: [Float]
    private var imaginaryParts: [Float]
    private var magnitudes: [Float]
    
    // Windowing function
    private var window: [Float]
    
    // Number of frequency bands to display
    private let numberOfBands = 32
    
    // Smoothing factor for animations
    private let smoothingFactor: Float = 0.7
    
    init() {
        self.realParts = [Float](repeating: 0, count: fftSize)
        self.imaginaryParts = [Float](repeating: 0, count: fftSize)
        self.magnitudes = [Float](repeating: 0, count: fftSize / 2)
        self.window = [Float](repeating: 0, count: fftSize)
        
        // Create FFT setup
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )
        
        // Generate Hann window
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    func processSamples(_ samples: [Float]) {
        guard samples.count >= fftSize else { return }
        
        // Take first fftSize samples
        var inputSamples = Array(samples.prefix(fftSize))
        
        // Apply window function to reduce spectral leakage
        vDSP_vmul(inputSamples, 1, window, 1, &inputSamples, 1, vDSP_Length(fftSize))
        
        // Prepare real and imaginary parts
        realParts = inputSamples
        imaginaryParts = [Float](repeating: 0, count: fftSize)
        
        // Perform FFT
        guard let setup = fftSetup else { return }
        
        vDSP_DFT_Execute(
            setup,
            &realParts,
            &imaginaryParts,
            &realParts,
            &imaginaryParts
        )
        
        // Calculate magnitudes: sqrt(real^2 + imag^2)
        var halfSize = fftSize / 2
        vDSP_zvmags(
            &realParts,
            1,
            &magnitudes,
            1,
            vDSP_Length(halfSize)
        )
        
        // Convert to dB scale and normalize
        var normalizedMagnitudes = magnitudes.map { magnitude -> Float in
            let db = 10 * log10(max(magnitude, 1e-10))
            // Normalize to 0-1 range (assuming -80 to 0 dB range)
            return max(0, min(1, (db + 80) / 80))
        }
        
        // Group frequencies into bands (logarithmic scale for better visualization)
        let newBands = groupIntoFrequencyBands(normalizedMagnitudes)
        
        // Apply smoothing for better visual effect
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for i in 0..<self.numberOfBands {
                self.spectrumBands[i] = self.smoothingFactor * self.spectrumBands[i] + (1 - self.smoothingFactor) * newBands[i]
            }
        }
    }
    
    private func groupIntoFrequencyBands(_ magnitudes: [Float]) -> [Float] {
        var bands = [Float](repeating: 0, count: numberOfBands)
        let magnitudeCount = magnitudes.count
        
        // Use logarithmic grouping for frequency bands
        // This gives more resolution to lower frequencies (bass/mids)
        for i in 0..<numberOfBands {
            let bandPosition = Float(i) / Float(numberOfBands)
            let nextBandPosition = Float(i + 1) / Float(numberOfBands)
            // Logarithmic scale: use exp(log(max) * position) for proper distribution
            let startIndex = Int(exp(log(Float(magnitudeCount)) * bandPosition))
            let endIndex = Int(exp(log(Float(magnitudeCount)) * nextBandPosition))
            
            let clampedStart = min(startIndex, magnitudeCount - 1)
            let clampedEnd = min(endIndex, magnitudeCount)
            
            if clampedStart < clampedEnd {
                let bandSlice = magnitudes[clampedStart..<clampedEnd]
                // Use average of the band
                bands[i] = bandSlice.reduce(0, +) / Float(bandSlice.count)
            }
        }
        
        return bands
    }
}
