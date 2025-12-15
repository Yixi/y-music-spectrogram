//
//  AudioCaptureManager.swift
//  YMusicSpectrogram
//
//  Manages audio capture using ScreenCaptureKit for system audio
//
//  IMPLEMENTATION:
//  - Uses ScreenCaptureKit (macOS 13+) to capture system audio streams
//  - Requires Screen Recording permission in System Settings
//  - Captures audio from all system output without virtual audio drivers
//

import CoreAudio
import CoreMedia
import Foundation
import ScreenCaptureKit

@available(macOS 13.0, *)
class AudioCaptureManager: NSObject {
    private let spectrumAnalyzer: SpectrumAnalyzer
    private var isCapturing = false
    
    // ScreenCaptureKit properties
    private var stream: SCStream?
    private var streamOutput: AudioStreamOutput?
    
    // Audio format configuration
    private let sampleRate: Double = 48000.0 // ScreenCaptureKit uses 48kHz
    
    init(spectrumAnalyzer: SpectrumAnalyzer) {
        self.spectrumAnalyzer = spectrumAnalyzer
        super.init()
    }
    
    func startCapture() {
        guard !isCapturing else { return }
        
        // Try to start ScreenCaptureKit audio capture
        Task {
            do {
                try await startScreenCaptureAudio()
            } catch {
                print("⚠️ ScreenCaptureKit error: \(error.localizedDescription)")
            }
        }
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        // Stop ScreenCaptureKit stream
        if let stream = stream {
            Task {
                do {
                    try await stream.stopCapture()
                    self.stream = nil
                    self.streamOutput = nil
                    print("⏹️ ScreenCaptureKit audio capture stopped")
                } catch {
                    print("⚠️ Error stopping stream: \(error.localizedDescription)")
                }
            }
        }
        
        isCapturing = false
        print("⏹️ Audio capture stopped")
    }
    
    private func startScreenCaptureAudio() async throws {
        // Check if we can get screen recording permission FIRST
        // This triggers the system prompt if not yet determined
        guard await requestScreenRecordingPermission() else {
            // If false, it means either denied OR user hasn't responded yet.
            // Since we can't wait for the response, we have to assume we can't proceed with SCKit right now.
            throw NSError(
                domain: "AudioCaptureManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Screen recording permission not granted"]
            )
        }
        
        // Get available content for screen capture
        let availableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        // Configure stream to capture system audio
        let streamConfig = SCStreamConfiguration()
        streamConfig.capturesAudio = true
        streamConfig.sampleRate = Int(sampleRate)
        streamConfig.channelCount = 2
        
        // Exclude all video to only capture audio
        streamConfig.width = 1
        streamConfig.height = 1
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        streamConfig.queueDepth = 5
        
        // Create a content filter - we'll capture the main display's audio
        let filter: SCContentFilter
        if let display = availableContent.displays.first {
            filter = SCContentFilter(display: display, excludingWindows: [])
        } else {
            throw NSError(
                domain: "AudioCaptureManager",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No display available for capture"]
            )
        }
        
        // Create and configure stream
        stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        
        // Create output handler
        streamOutput = AudioStreamOutput(spectrumAnalyzer: spectrumAnalyzer)
        
        // Add audio output
        try stream?.addStreamOutput(streamOutput!, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))
        
        // Start capture
        try await stream?.startCapture()
        
        isCapturing = true
        print("🎧 System audio capture started (ScreenCaptureKit)")
        print("ℹ️ Capturing all system audio output")
    }
    
    private func requestScreenRecordingPermission() async -> Bool {
        // Check if we already have permission
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        
        // Request permission
        return CGRequestScreenCaptureAccess()
    }
    
    deinit {
        stopCapture()
    }
}

// MARK: - AudioStreamOutput

@available(macOS 13.0, *)
private class AudioStreamOutput: NSObject, SCStreamOutput {
    private let spectrumAnalyzer: SpectrumAnalyzer
    
    init(spectrumAnalyzer: SpectrumAnalyzer) {
        self.spectrumAnalyzer = spectrumAnalyzer
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Only process audio buffers
        guard type == .audio else { return }
        
        // Convert CMSampleBuffer to audio samples
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        guard status == kCMBlockBufferNoErr,
              let data = dataPointer else {
            return
        }
        
        // Get audio format description
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        guard let streamDescription = audioStreamBasicDescription?.pointee else {
            return
        }
        
        // Verify audio format is Float32 PCM (Linear PCM)
        let formatID = streamDescription.mFormatID
        let bitsPerChannel = streamDescription.mBitsPerChannel
        guard formatID == kAudioFormatLinearPCM && bitsPerChannel == 32 else {
            print("⚠️ Unexpected audio format: formatID=\(formatID), bitsPerChannel=\(bitsPerChannel)")
            return
        }
        
        // Convert to Float array for processing
        let channelCount = Int(streamDescription.mChannelsPerFrame)
        let frameCount = length / (MemoryLayout<Float>.size * channelCount)
        
        // Extract samples within the safe memory scope
        var samples = [Float](repeating: 0, count: frameCount)
        data.withMemoryRebound(to: Float.self, capacity: length / MemoryLayout<Float>.size) { floatPointer in
            if channelCount == 1 {
                // Mono audio - direct copy
                for i in 0..<frameCount {
                    samples[i] = floatPointer[i]
                }
            } else if channelCount == 2 {
                // Stereo audio - mix to mono
                for i in 0..<frameCount {
                    samples[i] = (floatPointer[i * 2] + floatPointer[i * 2 + 1]) / 2.0
                }
            }
        }
        
        // Process samples through spectrum analyzer
        spectrumAnalyzer.processSamples(samples)
    }
}
