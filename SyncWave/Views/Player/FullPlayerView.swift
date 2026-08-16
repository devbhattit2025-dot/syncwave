//
//  FullPlayerView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI
import UniformTypeIdentifiers

/// Full-screen high-precision audio player with interactive scrubber, volume, latency offset calibration, and file import.
struct FullPlayerView: View {
    @ObservedObject var audioManager: AudioManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isDraggingScrubber: Bool = false
    @State private var dragScrubTime: TimeInterval = 0
    @State private var showingQueue: Bool = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation / Dismiss Bar
                topBar
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Album Art Hero
                        albumArtworkHero
                        
                        // Track Metadata & Sync Badge
                        trackMetadataSection
                        
                        // Interactive Waveform & Scrubber
                        scrubberSection
                        
                        // Main Playback Controls
                        playbackControlsSection
                        
                        // Volume Slider & Route Output Pill
                        volumeAndRouteSection
                        
                        // Latency Offset Calibration
                        latencyCalibrationSection
                        
                        // Track Queue / Library
                        playlistSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                HapticManager.lightImpact()
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            
            Spacer()
            
            Text("PRECISION PLAYER")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textTertiary)
                .tracking(1.5)
            
            Spacer()
            
            // Import File Button
            Button(action: {
                audioManager.isFilePickerPresented = true
                HapticManager.lightImpact()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accentCyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Album Artwork Hero
    private var albumArtworkHero: some View {
        ZStack {
            let colors = audioManager.currentTrack?.accentGradient ?? [Theme.accentCyan, Theme.accentPurple]
            
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .neonGlow(color: colors.first ?? Theme.accentCyan, radius: audioManager.isPlaying ? 24 : 8, opacity: 0.4)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
            
            Image(systemName: audioManager.currentTrack?.artworkSystemName ?? "waveform.circle.fill")
                .font(.system(size: 96, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(audioManager.isPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioManager.isPlaying)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Track Metadata
    private var trackMetadataSection: some View {
        VStack(spacing: 6) {
            Text(audioManager.currentTrack?.title ?? "No Track Selected")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(audioManager.currentTrack?.artist ?? "SyncWave High-Precision Audio")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 8) {
                Text(audioManager.currentTrack?.formatDescription ?? "PCM Audio")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.accentCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accentCyan.opacity(0.12)))
                
                Text(audioManager.routeInfo.primaryOutputName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentPurple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accentPurple.opacity(0.12)))
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Scrubber Section
    private var scrubberSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let currentProgress = audioManager.duration > 0 ? (isDraggingScrubber ? dragScrubTime : audioManager.currentTime) / audioManager.duration : 0
                
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)
                    
                    // Filled progress
                    Capsule()
                        .fill(Theme.neonWaveGradient)
                        .frame(width: max(6, geo.size.width * CGFloat(max(0, min(1, currentProgress)))), height: 6)
                    
                    // Scrubber thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: Theme.accentCyan, radius: 6)
                        .offset(x: max(0, min(geo.size.width - 18, geo.size.width * CGFloat(currentProgress) - 9)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingScrubber = true
                            let ratio = max(0, min(1, value.location.x / geo.size.width))
                            dragScrubTime = Double(ratio) * audioManager.duration
                        }
                        .onEnded { value in
                            let ratio = max(0, min(1, value.location.x / geo.size.width))
                            let targetTime = Double(ratio) * audioManager.duration
                            audioManager.seek(to: targetTime)
                            isDraggingScrubber = false
                            HapticManager.lightImpact()
                        }
                )
            }
            .frame(height: 20)
            
            HStack {
                let displayCurrent = isDraggingScrubber ? dragScrubTime : audioManager.currentTime
                Text(displayCurrent.formattedMinutesSeconds)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Text(audioManager.duration.formattedMinutesSeconds)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Playback Controls
    private var playbackControlsSection: some View {
        HStack(spacing: 32) {
            // Previous Track Button
            Button(action: {
                audioManager.playPreviousTrack()
                HapticManager.mediumImpact()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            // Main Play / Pause Button
            Button(action: {
                audioManager.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 72, height: 72)
                        .neonGlow(color: Theme.accentIndigo, radius: 14)
                    
                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: audioManager.isPlaying ? 0 : 2)
                }
            }
            
            // Next Track Button
            Button(action: {
                audioManager.playNextTrack()
                HapticManager.mediumImpact()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Volume & Route Section
    private var volumeAndRouteSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
                
                Slider(value: $audioManager.volume, in: 0...1)
                    .accentColor(Theme.accentCyan)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
            }
            
            // Route Picker Representation
            HStack {
                Image(systemName: "airplayaudio")
                    .foregroundColor(Theme.accentCyan)
                Text("System Audio Output:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                AVRoutePickerRepresentable()
                    .frame(width: 32, height: 32)
            }
        }
        .glassCard(cornerRadius: 16, padding: 14)
    }
    
    // MARK: - Latency Calibration Section
    private var latencyCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(Theme.accentCyan)
                    Text("LATENCY SYNC OFFSET")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.0)
                }
                
                Spacer()
                
                Text(String(format: "+%.0f ms", audioManager.synchronizer.userDelayOffsetMs))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentCyan)
            }
            
            Slider(
                value: Binding(
                    get: { audioManager.synchronizer.userDelayOffsetMs },
                    set: { audioManager.synchronizer.userDelayOffsetMs = $0 }
                ),
                in: 0...300,
                step: 5
            )
            .accentColor(Theme.accentIndigo)
            
            HStack {
                Text("0ms (Direct)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                
                Spacer()
                
                Button("Reset") {
                    audioManager.synchronizer.resetDelayOffset()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.accentAmber)
                
                Spacer()
                
                Text("300ms (Compensated)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .glassCard(cornerRadius: 16, padding: 14)
    }
    
    // MARK: - Track Queue Section
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AUDIO PLAYLIST")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
                
                Spacer()
                
                Button(action: {
                    audioManager.isFilePickerPresented = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                        Text("Import File")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.accentCyan)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(audioManager.playlist) { track in
                    let isSelected = audioManager.currentTrack?.id == track.id
                    
                    Button(action: {
                        audioManager.selectTrack(track, autoPlay: true)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "speaker.wave.3.fill" : track.artworkSystemName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isSelected ? Theme.accentCyan : Theme.textTertiary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Theme.accentCyan : Theme.textPrimary)
                                
                                Text(track.artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(track.duration.formattedMinutesSeconds)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textTertiary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Theme.accentCyan.opacity(0.12) : Color.clear)
                        )
                    }
                }
            }
        }
        .glassCard(cornerRadius: 16, padding: 14)
    }
}
