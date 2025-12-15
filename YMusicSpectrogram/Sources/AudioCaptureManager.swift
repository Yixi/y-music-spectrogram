//
//  AudioCaptureManager.swift
//  YMusicSpectrogram
//
//  Manages audio input capture from microphone
//
//  NOTES ON SYSTEM AUDIO CAPTURE:
//  - For capturing actual system audio (music playback), macOS requires special approaches:
//    1. ScreenCaptureKit (macOS 13+): Can capture system audio streams
//    2. Virtual Audio Driver (BlackHole/Loopback): Create a virtual audio device
//    3. Audio MIDI Setup: Configure audio routing manually
//  
//  This MVP implementation uses microphone input as a starting point.
//  To capture system audio, you can:
//  - Install BlackHole (https://github.com/ExistentialAudio/BlackHole)
//  - Use ScreenCaptureKit for macOS 13+ (requires additional permissions)
//  - Configure Audio MIDI Setup to route system output to the input device
//

import AVFoundation
import CoreAudio
import Foundation

class AudioCaptureManager: NSObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let spectrumAnalyzer: SpectrumAnalyzer
    private var isCapturing = false
    
    // Audio format configuration
    private let sampleRate: Double = 44100.0
    private let bufferSize: AVAudioFrameCount = 4096
    
    init(spectrumAnalyzer: SpectrumAnalyzer) {
        self.spectrumAnalyzer = spectrumAnalyzer
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
    }
    
    func startCapture() {
        guard !isCapturing else { return }
        
        // Request microphone permission
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                print("❌ Microphone permission denied")
                return
            }
            
            self?.beginAudioCapture()
        }
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        isCapturing = false
        
        print("⏹️ Audio capture stopped")
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(macOS)
        // Request microphone access
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
        #endif
    }
    
    private func beginAudioCapture() {
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            print("❌ Audio engine not initialized")
            return
        }
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node to receive audio buffers
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isCapturing = true
            print("🎤 Audio capture started (Microphone input)")
            print("ℹ️  To capture system audio, consider using BlackHole or ScreenCaptureKit")
        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        // Get samples from first channel (mono or first channel of stereo)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Send samples to spectrum analyzer
        spectrumAnalyzer.processSamples(samples)
    }
    
    deinit {
        stopCapture()
    }
}
