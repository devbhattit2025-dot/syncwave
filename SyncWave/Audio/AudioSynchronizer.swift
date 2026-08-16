//
//  AudioSynchronizer.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import Combine

/// Manages precision clock alignment, latency estimation, and delay compensation calibration.
final class AudioSynchronizer: ObservableObject {
    static let shared = AudioSynchronizer()
    
    private let audioEngine = AudioEngineService.shared
    private let sessionManager = AudioSessionManager.shared
    
    @Published var userDelayOffsetMs: Double = 0.0 {
        didSet {
            audioEngine.applyDelayCompensation(delayMs: userDelayOffsetMs)
        }
    }
    
    @Published private(set) var hardwareBufferLatencyMs: Double = 5.0
    @Published private(set) var routeOutputLatencyMs: Double = 12.0
    @Published private(set) var totalEffectiveLatencyMs: Double = 17.0
    @Published private(set) var isMetronomeActive: Bool = false
    
    private var metronomeTimer: Timer?
    private let clickPlayer = AVAudioPlayerNode()
    
    private init() {
        updateLatencies()
    }
    
    /// Recalculates physical and software latencies from the underlying audio session
    func updateLatencies() {
        self.hardwareBufferLatencyMs = sessionManager.ioBufferDuration * 1000.0
        self.routeOutputLatencyMs = sessionManager.outputLatency * 1000.0
        self.totalEffectiveLatencyMs = hardwareBufferLatencyMs + routeOutputLatencyMs + userDelayOffsetMs
    }
    
    /// Resets delay compensation to zero
    func resetDelayOffset() {
        userDelayOffsetMs = 0.0
        updateLatencies()
        HapticManager.lightImpact()
    }
    
    /// Sets a preset delay compensation based on standard Bluetooth profiles
    func applyPreset(preset: SyncPreset) {
        userDelayOffsetMs = preset.delayMs
        updateLatencies()
        HapticManager.mediumImpact()
    }
    
    // MARK: - Sync Metronome for Audible Latency Calibration
    
    /// Plays an audible sync test pulse to calibrate acoustic alignment across multiple speakers/rooms
    func toggleSyncPulse() {
        if isMetronomeActive {
            stopSyncPulse()
        } else {
            startSyncPulse()
        }
    }
    
    private func startSyncPulse() {
        isMetronomeActive = true
        HapticManager.mediumImpact()
        
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            AudioServicesPlaySystemSound(1057) // Tock click sound
            HapticManager.lightImpact()
        }
    }
    
    private func stopSyncPulse() {
        isMetronomeActive = false
        metronomeTimer?.invalidate()
        metronomeTimer = nil
    }
}

// MARK: - Sync Delay Presets
enum SyncPreset: String, CaseIterable, Identifiable {
    case zero = "Direct (0ms)"
    case airpodsPro = "AirPods Pro (15ms)"
    case bluetoothSpeaker = "BT Speaker (45ms)"
    case airPlay = "AirPlay / TV (120ms)"
    case longRangeBT = "Long-Range BT (220ms)"
    
    var id: String { rawValue }
    
    var delayMs: Double {
        switch self {
        case .zero: return 0.0
        case .airpodsPro: return 15.0
        case .bluetoothSpeaker: return 45.0
        case .airPlay: return 120.0
        case .longRangeBT: return 220.0
        }
    }
}
