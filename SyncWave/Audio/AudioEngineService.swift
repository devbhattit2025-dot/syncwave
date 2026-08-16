//
//  AudioEngineService.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import Combine

/// Low-level audio graph engine using AVAudioEngine with real-time bus tapping for FFT visualization.
final class AudioEngineService: ObservableObject {
    static let shared = AudioEngineService()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitchNode = AVAudioUnitTimePitch()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 3)
    private let delayNode = AVAudioUnitDelay()
    
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?
    private var isEngineRunning = false
    
    private let fftCalculator = FFTCalculator(fftSize: 1024, numberOfBands: 24)
    
    // Tap buffer handlers
    var onSpectrumCalculated: (([Float]) -> Void)?
    var onLevelsCalculated: ((Float, Float) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var volume: Float = 1.0 {
        didSet {
            engine.mainMixerNode.outputVolume = volume
        }
    }
    
    private var displayTimer: Timer?
    private var seekFrameOffset: AVAudioFramePosition = 0
    private var audioSampleRate: Double = 44100.0
    private var totalFrames: AVAudioFramePosition = 0
    
    private init() {
        setupAudioGraph()
    }
    
    // MARK: - Audio Graph Setup
    
    private func setupAudioGraph() {
        engine.attach(playerNode)
        engine.attach(timePitchNode)
        engine.attach(delayNode)
        engine.attach(eqNode)
        
        // Delay bypass by default until user applies latency compensation
        delayNode.bypass = true
        delayNode.feedback = 0
        delayNode.lowPassCutoff = 15000
        delayNode.wetDryMix = 100 // full wet for pure delay compensation
        
        // Connect player -> timePitch -> delay -> eq -> mainMixer
        engine.connect(playerNode, to: timePitchNode, format: nil)
        engine.connect(timePitchNode, to: delayNode, format: nil)
        engine.connect(delayNode, to: eqNode, format: nil)
        engine.connect(eqNode, to: engine.mainMixerNode, format: nil)
        
        installBusTap()
    }
    
    private func installBusTap() {
        let mixer = engine.mainMixerNode
        let tapFormat = mixer.outputFormat(forBus: 0)
        
        guard tapFormat.sampleRate > 0 else { return }
        
        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            if self.isPlaying {
                let bands = self.fftCalculator.calculateSpectrum(from: buffer)
                let levels = FFTCalculator.calculateRMS(from: buffer)
                
                DispatchQueue.main.async {
                    self.onSpectrumCalculated?(bands)
                    self.onLevelsCalculated?(levels.left, levels.right)
                }
            } else {
                let decayed = self.fftCalculator.decayBands()
                DispatchQueue.main.async {
                    self.onSpectrumCalculated?(decayed)
                    self.onLevelsCalculated?(0, 0)
                }
            }
        }
    }
    
    // MARK: - Audio Loading & Playback
    
    /// Loads an audio file from a local URL
    func loadFile(url: URL) -> Bool {
        stop()
        
        do {
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            self.audioSampleRate = file.processingFormat.sampleRate
            self.audioChannelCount = file.processingFormat.channelCount
            self.audioLengthSamples = file.length
            self.duration = Double(file.length) / file.processingFormat.sampleRate
            self.currentTime = 0
            self.seekFrameOffset = 0
            
            return true
        } catch {
            print("[AudioEngineService] Failed to load audio file: \(error.localizedDescription)")
            return false
        }
    }
    
    func play() {
        guard audioFile != nil else { return }
        
        if !engine.isRunning {
            do {
                try engine.start()
                isEngineRunning = true
            } catch {
                print("[AudioEngineService] Could not start engine: \(error.localizedDescription)")
                return
            }
        }
        
        if !isPlaying {
            schedulePlayback(from: seekFrameOffset)
            playerNode.play()
            isPlaying = true
            startProgressTimer()
        }
    }
    
    func pause() {
        guard isPlaying else { return }
        playerNode.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
        seekFrameOffset = 0
        stopProgressTimer()
        
        let decayed = fftCalculator.decayBands()
        self.onSpectrumCalculated?(decayed)
        self.onLevelsCalculated?(0, 0)
    }
    
    func seek(to time: TimeInterval) {
        guard audioFile != nil else { return }
        let clampedTime = max(0, min(time, duration))
        let targetFrame = AVAudioFramePosition(clampedTime * audioSampleRate)
        
        let wasPlaying = isPlaying
        playerNode.stop()
        
        seekFrameOffset = targetFrame
        currentTime = clampedTime
        
        if wasPlaying {
            schedulePlayback(from: targetFrame)
            playerNode.play()
            isPlaying = true
            startProgressTimer()
        }
    }
    
    private func schedulePlayback(from startFrame: AVAudioFramePosition) {
        guard let file = audioFile else { return }
        
        let remainingFrames = AVAudioFrameCount(max(0, totalFrames - startFrame))
        guard remainingFrames > 0 else {
            handlePlaybackCompletion()
            return
        }
        
        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: remainingFrames,
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.handlePlaybackCompletion()
            }
        }
    }
    
    private func handlePlaybackCompletion() {
        if isPlaying {
            isPlaying = false
            currentTime = 0
            seekFrameOffset = 0
            stopProgressTimer()
            onPlaybackFinished?()
        }
    }
    
    // MARK: - Progress Tracking
    
    private func startProgressTimer() {
        stopProgressTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            if let nodeTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) {
                let elapsedSeconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                let currentPos = Double(self.seekFrameOffset) / self.audioSampleRate + elapsedSeconds
                self.currentTime = min(self.duration, max(0, currentPos))
            }
        }
    }
    
    private func stopProgressTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    // MARK: - Latency & Sync Delay Calibration
    
    /// Applies software delay compensation in milliseconds to balance physical route latencies
    func applyDelayCompensation(delayMs: Double) {
        if delayMs <= 1.0 {
            delayNode.bypass = true
            delayNode.delayTime = 0
        } else {
            delayNode.bypass = false
            delayNode.delayTime = delayMs / 1000.0
        }
    }
}
