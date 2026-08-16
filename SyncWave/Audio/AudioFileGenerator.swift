//
//  AudioFileGenerator.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import Foundation
import AVFoundation
import SwiftUI

/// Generates high-quality standalone PCM stereo WAV demo tracks procedurally on launch.
final class AudioFileGenerator {
    static let shared = AudioFileGenerator()
    
    private init() {}
    
    /// Generates bundled demo tracks if they don't already exist on disk
    func prepareDemoTracks() -> [Track] {
        var tracks: [Track] = []
        
        let demoConfigs: [(id: String, title: String, artist: String, bpm: Double, genre: String, colors: [Color])] = [
            ("demo_neon_horizon", "Neon Horizon", "SyncWave Synth Lab", 124.0, "Synthwave", [Theme.accentCyan, Theme.accentBlue]),
            ("demo_cyber_pulse", "Cyber Pulse", "Digital Drift", 110.0, "Electro Bass", [Theme.accentPurple, Theme.accentIndigo]),
            ("demo_quantum_echo", "Quantum Echo", "Stellar Array", 86.0, "Ambient Lo-Fi", [Theme.accentViolet, Theme.accentPink])
        ]
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        
        for (index, config) in demoConfigs.enumerated() {
            let fileURL = documentsDir.appendingPathComponent("\(config.id).wav")
            
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                generateProceduralWav(to: fileURL, index: index, bpm: config.bpm)
            }
            
            let track = Track(
                title: config.title,
                artist: config.artist,
                album: "SyncWave High-Precision Audio",
                duration: 32.0, // 32 seconds loopable track
                fileURL: fileURL,
                isLocalDemo: true,
                artworkSystemName: index == 0 ? "waveform.path.ecg" : (index == 1 ? "bolt.horizontal.circle.fill" : "sparkles"),
                accentGradient: config.colors,
                waveformSamples: Track.generateDefaultWaveform(count: 50),
                formatDescription: "Stereo 44.1kHz • 16-bit PCM WAV"
            )
            tracks.append(track)
        }
        
        return tracks
    }
    
    /// Generates a valid RIFF 16-bit 44.1kHz Stereo WAV file
    private func generateProceduralWav(to url: URL, index: Int, bpm: Double) {
        let sampleRate: Double = 44100.0
        let duration: Double = 32.0 // 32 seconds
        let totalFrames = Int(sampleRate * duration)
        let numChannels: Int = 2
        let bytesPerSample: Int = 2
        let byteRate = Int(sampleRate) * numChannels * bytesPerSample
        let blockAlign = numChannels * bytesPerSample
        let dataSize = totalFrames * blockAlign
        let fileSize = 36 + dataSize
        
        var data = Data()
        data.reserveCapacity(fileSize + 8)
        
        // 1. RIFF Header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        
        // 2. fmt Sub-chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // Subchunk1Size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // AudioFormat: PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // BitsPerSample
        
        // 3. data Sub-chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        
        // Musical scales (MIDI to Hz)
        // Neon Horizon (A minor / F / C / G chords)
        let chordNotes: [[Double]] = [
            [220.0, 261.63, 329.63, 440.0],  // Am
            [174.61, 220.0, 261.63, 349.23],  // F
            [130.81, 164.81, 196.0, 261.63],  // C
            [196.0, 246.94, 293.66, 392.0]   // G
        ]
        
        let beatDuration = 60.0 / bpm
        let chordDuration = beatDuration * 4.0
        
        var bassPhase: Double = 0
        var leadPhase: Double = 0
        
        for frame in 0..<totalFrames {
            let t = Double(frame) / sampleRate
            let currentChordIndex = Int(t / chordDuration) % chordNotes.count
            let chord = chordNotes[currentChordIndex]
            
            // Beat position
            let beatPos = fmod(t, beatDuration) / beatDuration
            let beatIndex = Int(t / beatDuration)
            
            var sampleL: Double = 0
            var sampleR: Double = 0
            
            if index == 0 {
                // Synthwave (Neon Horizon)
                // Chords with warm saw/sine mix
                for (i, note) in chord.enumerated() {
                    let detune = (i % 2 == 0) ? 1.002 : 0.998
                    let osc = sin(2.0 * .pi * note * t) * 0.15 + (asin(sin(2.0 * .pi * note * detune * t)) / (.pi / 2.0)) * 0.1
                    sampleL += osc
                    sampleR += osc * ((i % 2 == 0) ? 1.1 : 0.9)
                }
                
                // Bass (punchy saw with decay)
                let bassNote = chord[0] * 0.5
                let bassEnv = max(0.0, 1.0 - beatPos * 1.5)
                bassPhase += 2.0 * .pi * bassNote / sampleRate
                let bassOsc = sin(bassPhase) * 0.3 * bassEnv
                sampleL += bassOsc
                sampleR += bassOsc
                
                // Kick Drum on beats 0, 2 (4-on-the-floor feel)
                if beatIndex % 1 == 0 {
                    let kickEnv = max(0.0, 1.0 - beatPos * 4.0)
                    let kickFreq = 140.0 * exp(-beatPos * 15.0) + 45.0
                    let kick = sin(2.0 * .pi * kickFreq * beatPos * beatDuration) * 0.45 * kickEnv
                    sampleL += kick
                    sampleR += kick
                }
                
                // Snare/Clap on beats 1, 3
                if beatIndex % 2 == 1 && beatPos < 0.3 {
                    let snareEnv = max(0.0, 1.0 - beatPos / 0.3)
                    let noise = Double.random(in: -1.0...1.0) * 0.22 * snareEnv
                    sampleL += noise
                    sampleR += noise
                }
                
                // Arpeggiated Lead
                let arpIndex = Int(t / (beatDuration / 4.0)) % chord.count
                let arpFreq = chord[arpIndex] * 2.0
                leadPhase += 2.0 * .pi * arpFreq / sampleRate
                let leadEnv = max(0.0, 1.0 - fmod(t, beatDuration / 4.0) / (beatDuration / 4.0))
                let leadOsc = sin(leadPhase) * 0.18 * leadEnv
                sampleL += leadOsc * 0.8
                sampleR += leadOsc * 1.2
                
            } else if index == 1 {
                // Cyber Pulse (Electro)
                let bassFreq = chord[0] * 0.5
                let filterMod = (sin(2.0 * .pi * (1.0 / 4.0) * t) + 1.0) * 0.5
                bassPhase += 2.0 * .pi * bassFreq / sampleRate
                let bass = sin(bassPhase) * 0.4 + sin(bassPhase * 2.0) * 0.2 * filterMod
                
                // Hihat every 1/8 note
                let hatPos = fmod(t, beatDuration / 2.0) / (beatDuration / 2.0)
                let hat = (hatPos < 0.1) ? Double.random(in: -1.0...1.0) * 0.15 * (1.0 - hatPos / 0.1) : 0
                
                sampleL = bass + hat
                sampleR = bass + hat * 0.8
                
            } else {
                // Quantum Echo (Ambient Lo-Fi)
                for (i, note) in chord.enumerated() {
                    let tremolo = (sin(2.0 * .pi * 3.0 * t) + 1.0) * 0.5 * 0.2 + 0.8
                    let osc = sin(2.0 * .pi * note * t) * 0.2 * tremolo
                    sampleL += osc * (i % 2 == 0 ? 1.0 : 0.7)
                    sampleR += osc * (i % 2 == 0 ? 0.7 : 1.0)
                }
                // Gentle vinyl crackle
                if Double.random(in: 0...100) > 99.2 {
                    let crackle = Double.random(in: -0.08...0.08)
                    sampleL += crackle
                    sampleR += crackle
                }
            }
            
            // Soft clipping / limiter
            sampleL = max(-0.95, min(0.95, sampleL * 0.75))
            sampleR = max(-0.95, min(0.95, sampleR * 0.75))
            
            let intSampleL = Int16(sampleL * 32767.0)
            let intSampleR = Int16(sampleR * 32767.0)
            
            withUnsafeBytes(of: intSampleL.littleEndian) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: intSampleR.littleEndian) { data.append(contentsOf: $0) }
        }
        
        try? data.write(to: url, options: .atomic)
    }
}
