//
//  SyncStatus.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Detailed synchronization status representing real-time iOS audio engine states and public API constraints.
enum SyncStatus: Equatable {
    case active
    case singleRouteStandard
    case limitedByIOS
    case multiRouteHardwareActive
    case noDevice
    case error(String)
    
    var title: String {
        switch self {
        case .active:
            return "Synchronization: Active"
        case .singleRouteStandard:
            return "Single Route (iOS Standard)"
        case .limitedByIOS:
            return "Synchronization: Limited by iOS"
        case .multiRouteHardwareActive:
            return "MultiRoute Hardware: Active"
        case .noDevice:
            return "Internal Speaker Only"
        case .error:
            return "Audio Session Alert"
        }
    }
    
    var subtitle: String {
        switch self {
        case .active:
            return "High-precision in-app audio engine running with active latency calibration."
        case .singleRouteStandard:
            return "Connected to one external audio output. Playback synchronized via CoreAudio."
        case .limitedByIOS:
            return "iOS currently allows this device configuration to use only one Bluetooth audio output. This app cannot override Apple's system audio-routing restrictions."
        case .multiRouteHardwareActive:
            return "Simultaneous multi-port output enabled across connected USB / Wired hardware routes."
        case .noDevice:
            return "No compatible external audio device detected. Playing through iPhone 11 built-in speaker."
        case .error(let message):
            return message
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .active, .multiRouteHardwareActive:
            return Theme.accentGreen
        case .singleRouteStandard:
            return Theme.accentCyan
        case .limitedByIOS:
            return Theme.accentAmber
        case .noDevice:
            return Theme.accentBlue
        case .error:
            return Theme.accentRose
        }
    }
    
    var iconName: String {
        switch self {
        case .active:
            return "waveform.path.badge.plus"
        case .singleRouteStandard:
            return "headphones"
        case .limitedByIOS:
            return "exclamationmark.triangle.fill"
        case .multiRouteHardwareActive:
            return "point.3.connected.trianglepath.dotted"
        case .noDevice:
            return "speaker.wave.2.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }
    
    var isLimited: Bool {
        if case .limitedByIOS = self { return true }
        return false
    }
}
