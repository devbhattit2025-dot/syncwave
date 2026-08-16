//
//  AudioRouteManager.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

/// Discovers, classifies, and monitors active audio routes, ports, and hardware output limits on iOS.
final class AudioRouteManager: ObservableObject {
    static let shared = AudioRouteManager()
    
    private let sessionManager = AudioSessionManager.shared
    
    @Published private(set) var currentRouteInfo: AudioRouteInfo = AudioRouteInfo()
    @Published private(set) var currentSyncStatus: SyncStatus = .noDevice
    @Published private(set) var connectedOutputs: [AudioDevice] = []
    @Published private(set) var connectedInputs: [AudioDevice] = []
    
    private init() {
        setupRouteObserver()
        refreshRoutes(reasonDescription: "Startup Initialization")
    }
    
    private func setupRouteObserver() {
        sessionManager.onRouteChanged = { [weak self] reason, route in
            self?.handleRouteChange(reason: reason, route: route)
        }
    }
    
    /// Scans the active AVAudioSession route and updates all published models
    func refreshRoutes(reasonDescription: String = "Manual Refresh") {
        let route = sessionManager.currentRoute
        let sampleRate = sessionManager.hardwareSampleRate
        let latency = sessionManager.outputLatency
        
        let outputDevices = route.outputs.map { port in
            AudioDevice(
                port: port,
                isOutput: true,
                isActive: true,
                sessionSampleRate: sampleRate,
                sessionLatency: latency
            )
        }
        
        let inputDevices = route.inputs.map { port in
            AudioDevice(
                port: port,
                isOutput: false,
                isActive: true,
                sessionSampleRate: sampleRate,
                sessionLatency: sessionManager.inputLatency
            )
        }
        
        var availableInputDevices: [AudioDevice] = []
        if let available = sessionManager.availableInputs {
            availableInputDevices = available.map { port in
                AudioDevice(
                    port: port,
                    isOutput: false,
                    isActive: route.inputs.contains(where: { $0.uid == port.uid }),
                    sessionSampleRate: sampleRate,
                    sessionLatency: sessionManager.inputLatency
                )
            }
        }
        
        let info = AudioRouteInfo(
            outputs: outputDevices,
            inputs: inputDevices,
            availableInputs: availableInputDevices,
            category: sessionManager.currentCategoryName,
            mode: "AVAudioSessionModeDefault",
            hardwareSampleRate: sampleRate,
            ioBufferDuration: sessionManager.ioBufferDuration,
            outputLatency: latency,
            inputLatency: sessionManager.inputLatency,
            isMultiRouteEnabled: sessionManager.isMultiRouteActive,
            multiRouteSupportedByHardware: outputDevices.contains(where: { $0.supportsMultiRoute }),
            lastChangeReason: reasonDescription,
            lastUpdated: Date()
        )
        
        self.currentRouteInfo = info
        self.connectedOutputs = outputDevices
        self.connectedInputs = inputDevices
        self.currentSyncStatus = determineSyncStatus(from: info)
    }
    
    private func handleRouteChange(reason: AVAudioSession.RouteChangeReason, route: AVAudioSessionRouteDescription) {
        let reasonStr: String
        switch reason {
        case .newDeviceAvailable:
            reasonStr = "New Audio Device Connected"
            HapticManager.success()
        case .oldDeviceUnavailable:
            reasonStr = "Audio Device Disconnected"
            HapticManager.warning()
        case .categoryChange:
            reasonStr = "Audio Session Category Changed"
        case .override:
            reasonStr = "Audio Output Route Overridden"
        case .wakeFromSleep:
            reasonStr = "Device Woke from Sleep"
        case .noSuitableRouteForCategory:
            reasonStr = "No Suitable Route Found for Category"
        case .routeConfigurationChange:
            reasonStr = "Route Configuration Changed"
        case .unknown:
            fallthrough
        @unknown default:
            reasonStr = "Route Changed (System Event)"
        }
        
        refreshRoutes(reasonDescription: reasonStr)
    }
    
    /// Evaluates the honest synchronization status based on public iOS capabilities
    private func determineSyncStatus(from info: AudioRouteInfo) -> SyncStatus {
        let outputs = info.outputs
        
        if outputs.isEmpty {
            return .noDevice
        }
        
        let hasBluetooth = outputs.contains(where: { $0.isBluetooth })
        let hasAirPlay = outputs.contains(where: { $0.portType == .airPlay })
        let hasSpeaker = outputs.contains(where: { $0.portType == .builtInSpeaker || $0.portType == .builtInReceiver })
        
        if info.isMultiRouteEnabled && outputs.count > 1 {
            return .multiRouteHardwareActive
        }
        
        if hasBluetooth {
            // iOS routes only 1 active Bluetooth A2DP stream for third party apps
            return .singleRouteStandard
        } else if hasAirPlay {
            return .active
        } else if hasSpeaker {
            return .noDevice
        } else {
            return .active
        }
    }
}
