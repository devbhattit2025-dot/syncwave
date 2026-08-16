//
//  AudioDevice.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import SwiftUI

/// Model representing a detected physical or virtual audio port.
struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let portType: AVAudioSession.Port
    let portTypeDescription: String
    let iconName: String
    let isOutput: Bool
    let isInput: Bool
    let isActive: Bool
    let channelCount: Int
    let sampleRate: Double
    let latencyMs: Double
    let supportsMultiRoute: Bool
    let isBluetooth: Bool
    
    init(
        port: AVAudioSessionPortDescription,
        isOutput: Bool = true,
        isActive: Bool = false,
        sessionSampleRate: Double = 44100.0,
        sessionLatency: Double = 0.0
    ) {
        self.id = port.uid.isEmpty ? "\(port.portType.rawValue)_\(port.portName)" : port.uid
        self.name = port.portName
        self.portType = port.portType
        self.portTypeDescription = port.userFriendlyTypeName
        self.iconName = port.sfSymbolName
        self.isOutput = isOutput
        self.isInput = !isOutput
        self.isActive = isActive
        self.channelCount = port.channels?.count ?? 2
        self.sampleRate = sessionSampleRate
        self.latencyMs = sessionLatency * 1000.0
        
        let btPorts: [AVAudioSession.Port] = [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE]
        self.isBluetooth = btPorts.contains(port.portType)
        
        // MultiRoute on iOS only supports USB / HDMI / Wired lineout combinations, not multiple Bluetooth A2DP
        let multiRoutePhysicalPorts: [AVAudioSession.Port] = [.headphones, .usbAudio, .HDMI, .lineOut]
        self.supportsMultiRoute = multiRoutePhysicalPorts.contains(port.portType)
    }
    
    /// Fallback manual initializer for diagnostics/preview
    init(
        id: String = UUID().uuidString,
        name: String,
        portType: AVAudioSession.Port,
        portTypeDescription: String,
        iconName: String,
        isOutput: Bool = true,
        isInput: Bool = false,
        isActive: Bool = true,
        channelCount: Int = 2,
        sampleRate: Double = 48000.0,
        latencyMs: Double = 12.5,
        supportsMultiRoute: Bool = false,
        isBluetooth: Bool = true
    ) {
        self.id = id
        self.name = name
        self.portType = portType
        self.portTypeDescription = portTypeDescription
        self.iconName = iconName
        self.isOutput = isOutput
        self.isInput = isInput
        self.isActive = isActive
        self.channelCount = channelCount
        self.sampleRate = sampleRate
        self.latencyMs = latencyMs
        self.supportsMultiRoute = supportsMultiRoute
        self.isBluetooth = isBluetooth
    }
}
