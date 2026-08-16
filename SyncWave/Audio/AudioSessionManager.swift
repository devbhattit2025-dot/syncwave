//
//  AudioSessionManager.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import Combine

/// Manages AVAudioSession lifecycle, category changes, multiRoute probes, and hardware constraints.
final class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    private let session = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    
    var onRouteChanged: ((AVAudioSessionRouteChangeReason, AVAudioSessionRouteDescription) -> Void)?
    var onInterruption: ((AVAudioSession.InterruptionType) -> Void)?
    
    @Published private(set) var isMultiRouteActive: Bool = false
    @Published private(set) var multiRouteProbeResult: String = "Not Probed"
    @Published private(set) var currentCategoryName: String = "AVAudioSessionCategoryPlayback"
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Session Configuration
    
    /// Activates the primary audio session for low-latency playback with Bluetooth A2DP & AirPlay support
    func configurePlaybackSession(preferredBufferDuration: Double = 0.005, preferredSampleRate: Double = 44100.0) -> Bool {
        do {
            // Category: Playback allows background audio and high quality routing
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetoothA2DP, .allowAirPlay]
            )
            
            try session.setPreferredSampleRate(preferredSampleRate)
            try session.setPreferredIOBufferDuration(preferredBufferDuration)
            try session.setActive(true, options: [])
            
            self.currentCategoryName = "AVAudioSessionCategoryPlayback"
            self.isMultiRouteActive = false
            return true
        } catch {
            print("[AudioSessionManager] Error configuring playback session: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Probes and attempts to enable AVAudioSessionCategoryMultiRoute
    /// MultiRoute allows simultaneous output to distinct physical non-Bluetooth endpoints (e.g. USB Audio + Built-in Headphone jack)
    func probeMultiRouteCategory() -> (success: Bool, message: String) {
        do {
            try session.setCategory(.multiRoute, mode: .default, options: [])
            try session.setActive(true)
            
            self.isMultiRouteActive = true
            self.currentCategoryName = "AVAudioSessionCategoryMultiRoute"
            
            let outputs = session.currentRoute.outputs
            let outputTypes = outputs.map { $0.portType.rawValue }.joined(separator: ", ")
            
            let message = "MultiRoute accepted by iOS. Active outputs (\(outputs.count)): [\(outputTypes)]. Note: iOS does not route multiple Bluetooth A2DP streams simultaneously in third-party apps."
            self.multiRouteProbeResult = message
            return (true, message)
        } catch {
            let errorMsg = "MultiRoute not supported with current device configuration: \(error.localizedDescription). Reverting to standard Playback category."
            self.multiRouteProbeResult = errorMsg
            self.isMultiRouteActive = false
            
            // Gracefully revert back to Playback category
            _ = configurePlaybackSession()
            return (false, errorMsg)
        }
    }
    
    /// Reverts to standard Playback mode if MultiRoute was active
    func revertToStandardPlayback() {
        _ = configurePlaybackSession()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification: notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleInterruption(notification: notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let currentRoute = session.currentRoute
        DispatchQueue.main.async {
            self.onRouteChanged?(reason, currentRoute)
        }
    }
    
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        DispatchQueue.main.async {
            self.onInterruption?(type)
        }
    }
    
    // MARK: - Hardware Metrics
    
    var hardwareSampleRate: Double {
        session.sampleRate
    }
    
    var ioBufferDuration: Double {
        session.ioBufferDuration
    }
    
    var outputLatency: Double {
        session.outputLatency
    }
    
    var inputLatency: Double {
        session.inputLatency
    }
    
    var currentRoute: AVAudioSessionRouteDescription {
        session.currentRoute
    }
    
    var availableInputs: [AVAudioSessionPortDescription]? {
        session.availableInputs
    }
}
