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
    
    // Input buffer to accumulate samples
    private var inputBuffer: [Float] = []
    private let maxBufferSize: Int = 4096 * 2 // Prevent buffer from growing too large
    
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
        // Append new samples to buffer
        inputBuffer.append(contentsOf: samples)
        
        // If buffer is too large, trim from the beginning to keep latest samples
        if inputBuffer.count > maxBufferSize {
            inputBuffer.removeFirst(inputBuffer.count - maxBufferSize)
        }
        
        // Check if we have enough samples for FFT
        guard inputBuffer.count >= fftSize else {
            // Debug log for insufficient samples (throttled)
            if Int.random(in: 0...50) == 0 {
                print("⚠️ Buffering samples: \(inputBuffer.count) / \(fftSize)")
            }
            return
        }
        
        // Take the latest fftSize samples for analysis
        let startIndex = inputBuffer.count - fftSize
        var inputSamples = Array(inputBuffer[startIndex..<inputBuffer.count])
        
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
        let halfSize = fftSize / 2
        
        realParts.withUnsafeMutableBufferPointer { realPtr in
            imaginaryParts.withUnsafeMutableBufferPointer { imagPtr in
                guard let realBase = realPtr.baseAddress, let imagBase = imagPtr.baseAddress else { return }
                var splitComplex = DSPSplitComplex(realp: realBase, imagp: imagBase)
                vDSP_zvmags(
                    &splitComplex,
                    1,
                    &magnitudes,
                    1,
                    vDSP_Length(halfSize)
                )
            }
        }
        
        // Convert to dB scale and normalize
        let normalizedMagnitudes = magnitudes.map { magnitude -> Float in
            // vDSP_zvmags returns squared magnitudes, so use 10*log10
            let db = 10 * log10(max(magnitude, 1e-10))
            // Normalize to 0-1 range (assuming -80 to 0 dB range)
            // Adjusted range 2 -100 to 0 dB to capture quieter sounds
            return max(0, min(1, (db + 100) / 100))
        }
        
        // Debug: Print magnitude stats
        if Int.random(in: 0...500) == 0 {
            let maxMag = magnitudes.max() ?? 0
            let maxNorm = normalizedMagnitudes.max() ?? 0
            let maxDB = 10 * log10(max(maxMag, 1e-10))
            // print("📊 FFT Stats: MaxMag=\(String(format: "%.6f", maxMag)), MaxDB=\(String(format: "%.2f", maxDB)), MaxNorm=\(String(format: "%.4f", maxNorm))")
        }
        
        // Group frequencies into bands (logarithmic scale for better visualization)
        let newBands = groupIntoFrequencyBands(normalizedMagnitudes)
        
        // Apply smoothing for better visual effect
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for i in 0..<self.numberOfBands {
                self.spectrumBands[i] = self.smoothingFactor * self.spectrumBands[i] + (1 - self.smoothingFactor) * newBands[i]
            }
            
            // Debug: Print first few bands to verify UI data
            if Int.random(in: 0...100) == 0 {
                let bandsPreview = self.spectrumBands.prefix(5).map { String(format: "%.2f", $0) }.joined(separator: ", ")
                print("📊 UI Bands: [\(bandsPreview)]")
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
