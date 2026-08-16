//
//  AudioRouteInfo.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation

/// Snapshot representation of current audio routing configuration and hardware metrics.
struct AudioRouteInfo: Equatable {
    var outputs: [AudioDevice] = []
    var inputs: [AudioDevice] = []
    var availableInputs: [AudioDevice] = []
    
    var category: String = "AVAudioSessionCategoryPlayback"
    var mode: String = "AVAudioSessionModeDefault"
    var hardwareSampleRate: Double = 44100.0
    var ioBufferDuration: Double = 0.005
    var outputLatency: Double = 0.012
    var inputLatency: Double = 0.0
    
    var isMultiRouteEnabled: Bool = false
    var multiRouteSupportedByHardware: Bool = false
    var lastChangeReason: String = "Initial Configuration"
    var lastUpdated: Date = Date()
    
    var primaryOutputName: String {
        outputs.first?.name ?? "iPhone Built-in Speaker"
    }
    
    var primaryPortType: String {
        outputs.first?.portTypeDescription ?? "Built-in Speaker"
    }
    
    var hasBluetoothOutput: Bool {
        outputs.contains { $0.isBluetooth }
    }
    
    var hasAirPlayOutput: Bool {
        outputs.contains { $0.portType == .airPlay }
    }
    
    var hasWiredOutput: Bool {
        outputs.contains { $0.portType == .headphones || $0.portType == .usbAudio || $0.portType == .lineOut }
    }
    
    var totalSystemLatencyMs: Double {
        return (outputLatency + ioBufferDuration) * 1000.0
    }
}
