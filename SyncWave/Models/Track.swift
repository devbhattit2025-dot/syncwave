//
//  Track.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import SwiftUI

/// Model representing an audio track (demo or user imported).
struct Track: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let fileURL: URL?
    let isLocalDemo: Bool
    let artworkSystemName: String
    let accentGradient: [Color]
    let waveformSamples: [Float]
    let formatDescription: String
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String = "SyncWave Lab",
        duration: TimeInterval,
        fileURL: URL?,
        isLocalDemo: Bool = false,
        artworkSystemName: String = "waveform.circle.fill",
        accentGradient: [Color] = [Theme.accentCyan, Theme.accentPurple],
        waveformSamples: [Float] = Track.generateDefaultWaveform(),
        formatDescription: String = "WAV 16-bit 44.1kHz"
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.isLocalDemo = isLocalDemo
        self.artworkSystemName = artworkSystemName
        self.accentGradient = accentGradient
        self.waveformSamples = waveformSamples
        self.formatDescription = formatDescription
    }
    
    static func generateDefaultWaveform(count: Int = 40) -> [Float] {
        return (0..<count).map { i in
            let angle = Double(i) / Double(count) * .pi * 4
            let val = abs(sin(angle) * 0.6 + cos(angle * 2.1) * 0.3) + 0.15
            return Float(max(0.1, min(1.0, val)))
        }
    }
}
