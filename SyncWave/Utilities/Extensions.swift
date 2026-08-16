//
//  Extensions.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - TimeInterval Formatting
extension TimeInterval {
    var formattedMinutesSeconds: String {
        guard !self.isNaN && !self.isInfinite && self >= 0 else { return "0:00" }
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Double & Float Formatting
extension Double {
    var formattedLatencyMs: String {
        return String(format: "%.1f ms", self)
    }
    
    var formattedSampleRateKhz: String {
        return String(format: "%.1f kHz", self / 1000.0)
    }
}

extension Float {
    var formattedDecibels: String {
        if self <= 0.0001 { return "-∞ dB" }
        let dB = 20 * log10(self)
        return String(format: "%.1f dB", dB)
    }
}

// MARK: - AVAudioSession Port Helper
extension AVAudioSessionPortDescription {
    var sfSymbolName: String {
        switch self.portType {
        case .bluetoothA2DP:
            if self.portName.localizedCaseInsensitiveContains("airpods") {
                return "airpodspro"
            } else if self.portName.localizedCaseInsensitiveContains("headphone") || self.portName.localizedCaseInsensitiveContains("sony") || self.portName.localizedCaseInsensitiveContains("bose") {
                return "headphones"
            } else {
                return "hifispeaker.fill"
            }
        case .bluetoothHFP, .bluetoothLE:
            return "wave.3.forward"
        case .airPlay:
            return "airplayaudio"
        case .headphones:
            return "headphones"
        case .builtInSpeaker:
            return "speaker.wave.3.fill"
        case .builtInReceiver:
            return "iphone"
        case .usbAudio:
            return "cable.connector"
        case .carAudio:
            return "car.fill"
        case .lineOut, .hdmi:
            return "tv.fill"
        default:
            return "speaker.fill"
        }
    }
    
    var userFriendlyTypeName: String {
        switch self.portType {
        case .bluetoothA2DP:
            return "Bluetooth Audio (A2DP)"
        case .bluetoothHFP:
            return "Bluetooth Handsfree (HFP)"
        case .bluetoothLE:
            return "Bluetooth Low Energy"
        case .airPlay:
            return "AirPlay Stream"
        case .headphones:
            return "Wired Headphones (3.5mm/Lightning)"
        case .builtInSpeaker:
            return "iPhone 11 Built-in Speaker"
        case .builtInReceiver:
            return "iPhone Earpiece Receiver"
        case .usbAudio:
            return "USB Audio Interface / DAC"
        case .carAudio:
            return "CarPlay Audio"
        case .hdmi:
            return "HDMI Output"
        case .lineOut:
            return "Line Out"
        default:
            return self.portType.rawValue
        }
    }
}
