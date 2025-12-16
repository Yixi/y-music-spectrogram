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
    @Published var spectrumBands: [Float]
    
    // FFT Configuration - larger size for better frequency resolution
    private let fftSize: Int = 4096
    private var fftSetup: vDSP_DFT_Setup?
    
    // Buffers for FFT processing
    private var realParts: [Float]
    private var imaginaryParts: [Float]
    private var magnitudes: [Float]
    
    // Input buffer to accumulate samples
    private var inputBuffer: [Float] = []
    private let maxBufferSize: Int = 8192
    
    // Windowing function
    private var window: [Float]
    
    // Number of frequency bands to display (now configurable)
    private var numberOfBands = 32
    
    // Smoothing parameters - separate for attack and release
    private let attackFactor: Float = 0.7   // Fast attack (higher = faster response to increases)
    private let releaseFactor: Float = 0.85 // Slower release (higher = slower decay)
    
    // dB range for normalization - tighter range for more visible dynamics
    private let dbFloor: Float = -50
    private let dbCeiling: Float = -10
    
    // Reference level for normalization (adjusts sensitivity)
    private let referenceLevel: Float = 1e-6
    
    // Peak tracking for auto-gain
    private var peakLevel: Float = 0.001
    private let peakDecay: Float = 0.9995  // Very slow decay for peak tracking
    
    // Pre-computed frequency band boundaries
    private var bandBoundaries: [(start: Int, end: Int)] = []
    
    // Sample rate (will be updated when processing)
    private var sampleRate: Float = 48000.0
    
    init() {
        // Load band count from settings
        let initialBandCount = SettingsManager.shared.bandCount
        self.numberOfBands = initialBandCount
        self.spectrumBands = Array(repeating: 0, count: initialBandCount)
        
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
        
        // Generate Blackman-Harris window (better sidelobe suppression than Hann)
        vDSP_blkman_window(&window, vDSP_Length(fftSize), 0)
        
        // Pre-compute frequency band boundaries
        computeBandBoundaries()
    }
    
    // Update band count dynamically
    func updateBandCount(_ count: Int) {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.numberOfBands = count
            self.spectrumBands = Array(repeating: 0, count: count)
            self.computeBandBoundaries()
        }
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    private func computeBandBoundaries() {
        // Frequency ranges optimized for music visualization
        // Bass: 20-250Hz, Mids: 250-2000Hz, Highs: 2000-20000Hz
        let minFreq: Float = 20.0
        let maxFreq: Float = 20000.0
        
        let nyquist = sampleRate / 2.0
        let binCount = fftSize / 2
        let freqPerBin = nyquist / Float(binCount)
        
        bandBoundaries = []
        
        for i in 0..<numberOfBands {
            // Logarithmic frequency distribution
            let ratio = Float(i) / Float(numberOfBands)
            let nextRatio = Float(i + 1) / Float(numberOfBands)
            
            // Map to frequency using log scale
            let startFreq = minFreq * pow(maxFreq / minFreq, ratio)
            let endFreq = minFreq * pow(maxFreq / minFreq, nextRatio)
            
            // Convert to FFT bin indices
            var startBin = Int(startFreq / freqPerBin)
            var endBin = Int(endFreq / freqPerBin)
            
            // Clamp to valid range
            startBin = max(1, min(startBin, binCount - 1))
            endBin = max(startBin + 1, min(endBin, binCount))
            
            bandBoundaries.append((start: startBin, end: endBin))
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
            return
        }
        
        // Take the latest fftSize samples for analysis
        let startIndex = inputBuffer.count - fftSize
        var inputSamples = Array(inputBuffer[startIndex..<inputBuffer.count])
        
        // Calculate RMS of input for auto-gain
        var rms: Float = 0
        vDSP_rmsqv(inputSamples, 1, &rms, vDSP_Length(fftSize))
        
        // Skip if input is essentially silent
        if rms < 1e-8 {
            // Decay all bands when silent
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for i in 0..<self.numberOfBands {
                    self.spectrumBands[i] *= 0.9
                }
            }
            return
        }
        
        // Update peak level for auto-gain (with slow decay)
        peakLevel = max(peakLevel * peakDecay, rms)
        
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
        
        // Take square root to get actual magnitudes (vDSP_zvmags returns squared values)
        var sqrtMagnitudes = [Float](repeating: 0, count: halfSize)
        var count = Int32(halfSize)
        vvsqrtf(&sqrtMagnitudes, magnitudes, &count)
        
        // Normalize by FFT size
        var normalizedMags = [Float](repeating: 0, count: halfSize)
        var scale: Float = 2.0 / Float(fftSize)
        vDSP_vsmul(sqrtMagnitudes, 1, &scale, &normalizedMags, 1, vDSP_Length(halfSize))
        
        // Group frequencies into bands using pre-computed boundaries
        let newBands = groupIntoFrequencyBands(normalizedMags)
        
        // Apply smoothing with separate attack/release for natural response
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for i in 0..<self.numberOfBands {
                let current = self.spectrumBands[i]
                let target = newBands[i]
                
                if target > current {
                    // Attack: fast response to increasing levels
                    self.spectrumBands[i] = current + (target - current) * self.attackFactor
                } else {
                    // Release: slower decay for smoother visuals
                    self.spectrumBands[i] = current + (target - current) * (1.0 - self.releaseFactor)
                }
            }
        }
    }
    
    private func groupIntoFrequencyBands(_ magnitudes: [Float]) -> [Float] {
        var bands = [Float](repeating: 0, count: numberOfBands)
        
        for i in 0..<numberOfBands {
            let boundary = bandBoundaries[i]
            let startIdx = boundary.start
            let endIdx = min(boundary.end, magnitudes.count)
            
            guard startIdx < endIdx else { continue }
            
            // Calculate average magnitude for this band
            var sum: Float = 0
            var maxVal: Float = 0
            
            for j in startIdx..<endIdx {
                let mag = magnitudes[j]
                sum += mag
                maxVal = max(maxVal, mag)
            }
            
            let count = Float(endIdx - startIdx)
            // Use weighted combination of average and peak for better visualization
            let avgMag = sum / count
            let combinedMag = avgMag * 0.4 + maxVal * 0.6
            
            // Convert to dB scale with auto-gain normalization
            let autoGain = 1.0 / max(peakLevel * 10.0, 0.001)
            let scaledMag = combinedMag * autoGain
            
            // Convert to dB
            let db = 20.0 * log10(max(scaledMag, referenceLevel))
            
            // Normalize to 0-1 range
            let dbRange = dbCeiling - dbFloor
            var normalized = (db - dbFloor) / dbRange
            
            // Apply soft compression for better visual distribution
            normalized = pow(max(0, min(1, normalized)), 0.7)
            
            // Apply frequency-dependent boost (bass needs more boost typically)
            let freqBoost: Float
            if i < 4 {
                freqBoost = 1.3  // Bass boost
            } else if i < 12 {
                freqBoost = 1.1  // Low-mid boost
            } else {
                freqBoost = 1.0  // Flat for highs
            }
            
            bands[i] = min(1.0, normalized * freqBoost)
        }
        
        return bands
    }
}
