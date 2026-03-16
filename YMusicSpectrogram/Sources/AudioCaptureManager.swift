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
//  - Automatically restarts capture after screen lock/unlock
//

import AppKit
import CoreAudio
import CoreMedia
import Foundation
import ScreenCaptureKit

@available(macOS 13.0, *)
class AudioCaptureManager: NSObject {
    private let spectrumAnalyzer: SpectrumAnalyzer
    private var isCapturing = false
    
    // Track if capture was active before screen sleep (to restore on wake)
    private var wasCapturingBeforeSleep = false
    
    // ScreenCaptureKit properties
    private var stream: SCStream?
    private var streamOutput: AudioStreamOutput?
    
    // Audio format configuration
    private let sampleRate: Double = 48000.0 // ScreenCaptureKit uses 48kHz
    
    init(spectrumAnalyzer: SpectrumAnalyzer) {
        self.spectrumAnalyzer = spectrumAnalyzer
        super.init()
        
        // Register for screen sleep/wake notifications to handle lock screen
        setupScreenSleepWakeObservers()
    }
    
    private func setupScreenSleepWakeObservers() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        
        // Observe screen sleep (includes lock screen)
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenDidSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        
        // Observe screen wake (includes unlock)
        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleScreenDidSleep() {
        print("🔒 Screen did sleep - pausing capture")
        wasCapturingBeforeSleep = isCapturing
        if isCapturing {
            stopCaptureInternal()
        }
    }
    
    @objc private func handleScreenDidWake() {
        print("🔓 Screen did wake - checking if capture needs to restart")
        if wasCapturingBeforeSleep {
            // Delay restart slightly to ensure system is fully awake
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                print("🔄 Restarting audio capture after screen wake")
                self.startCapture()
            }
        }
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
        // Reset the sleep tracking flag when user manually stops
        wasCapturingBeforeSleep = false
        stopCaptureInternal()
    }
    
    private func stopCaptureInternal() {
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
        
        print("🖥️ Available displays: \(availableContent.displays.count)")
        for (index, display) in availableContent.displays.enumerated() {
            print("  Display \(index): \(display.width)x\(display.height) ID:\(display.displayID)")
        }
        
        // Configure stream to capture system audio
        let streamConfig = SCStreamConfiguration()
        streamConfig.capturesAudio = true
        streamConfig.sampleRate = Int(sampleRate)
        streamConfig.channelCount = 2
        streamConfig.excludesCurrentProcessAudio = false // Ensure we don't exclude ourselves (though we don't play audio)
        
        // Exclude all video to only capture audio
        streamConfig.width = 100 // Minimum size might be needed for some displays
        streamConfig.height = 100
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        streamConfig.queueDepth = 5
        
        // Create a content filter - we'll capture the main display's audio
        // Using excludingWindows: [] ensures we capture everything on that display
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
        let canRecord = CGPreflightScreenCaptureAccess()
        print("🔍 Preflight screen capture access: \(canRecord)")
        
        if canRecord {
            return true
        }
        
        // Request permission
        print("⚠️ Requesting screen capture access...")
        return CGRequestScreenCaptureAccess()
    }
    
    deinit {
        // Remove notification observers
        NSWorkspace.shared.notificationCenter.removeObserver(self)
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
        let flags = streamDescription.mFormatFlags
        let isFloat = (flags & kAudioFormatFlagIsFloat) != 0
        let isSignedInteger = (flags & kAudioFormatFlagIsSignedInteger) != 0
        
        // Debug print for audio format (throttled to avoid spam)
        if Int.random(in: 0...200) == 0 {
             print("🔊 Audio Format: \(formatID), Bits: \(bitsPerChannel), Channels: \(streamDescription.mChannelsPerFrame), Flags: \(flags), IsFloat: \(isFloat)")
        }
        
        guard formatID == kAudioFormatLinearPCM && bitsPerChannel == 32 && isFloat else {
            if Int.random(in: 0...200) == 0 {
                print("⚠️ Unexpected audio format: formatID=\(formatID), bits=\(bitsPerChannel), isFloat=\(isFloat)")
            }
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
            } else if channelCount >= 2 {
                // Stereo or Multi-channel audio - mix first two channels to mono
                for i in 0..<frameCount {
                    let left = floatPointer[i * channelCount]
                    let right = floatPointer[i * channelCount + 1]
                    samples[i] = (left + right) / 2.0
                }
            }
        }
        
        // Debug: Print first few samples to verify data
        if Int.random(in: 0...500) == 0 {
            let maxSamples = min(5, samples.count)
            let samplePreview = samples.prefix(maxSamples).map { String(format: "%.4f", $0) }.joined(separator: ", ")
            // print("📊 Samples: [\(samplePreview)]")
            
            // Check for silence
            let maxVal = samples.reduce(0) { max($0, abs($1)) }
            if maxVal < 0.0001 {
                print("⚠️ Silence detected (max amplitude: \(maxVal))")
            }
        }
        
        // Process samples through spectrum analyzer
        spectrumAnalyzer.processSamples(samples)
    }
}
