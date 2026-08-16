//
//  HomeView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI
import UniformTypeIdentifiers

/// Main dashboard view featuring the dynamic visualizer, synchronization status, device overview, and player card.
struct HomeView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var showingPlayerSheet: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Header
                headerSection
                
                // MARK: - Synchronization & Route Status Card
                syncStatusCard
                
                // MARK: - Real-Time Audio Visualizer
                AudioVisualizerView(audioManager: audioManager)
                
                // MARK: - Now Playing Mini Card
                nowPlayingCard
                
                // MARK: - Detected Device Cards
                deviceSummarySection
                
                // MARK: - Apple Audio Sharing Callout
                audioSharingCalloutCard
                
                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .syncBackground()
        .sheet(isPresented: $showingPlayerSheet) {
            FullPlayerView(audioManager: audioManager)
        }
        .sheet(isPresented: $audioManager.showingAudioSharingGuide) {
            AudioSharingGuideView()
        }
        .fileImporter(
            isPresented: $audioManager.isFilePickerPresented,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff, UTType(filenameExtension: "m4a") ?? .audio, UTType(filenameExtension: "flac") ?? .audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    audioManager.importTrack(from: url)
                }
            case .failure(let error):
                print("File import failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("SYNCWAVE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.textPrimary, Theme.accentCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Circle()
                        .fill(Theme.accentCyan)
                        .frame(width: 6, height: 6)
                        .neonGlow(color: Theme.accentCyan, radius: 4)
                }
                
                Text("Synchronized Audio")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            // Bluetooth Connection Status Pill
            GlowingBadge(
                title: audioManager.routeInfo.hasBluetoothOutput ? "Bluetooth Connected" : "Internal Output",
                icon: audioManager.routeInfo.hasBluetoothOutput ? "headphones" : "iphone",
                color: audioManager.routeInfo.hasBluetoothOutput ? Theme.accentGreen : Theme.accentBlue,
                isPulsing: audioManager.isPlaying
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sync Status Card
    private var syncStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: audioManager.syncStatus.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(audioManager.syncStatus.badgeColor)
                    
                    Text(audioManager.syncStatus.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text(audioManager.routeInfo.hardwareSampleRate.formattedSampleRateKhz)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
            }
            
            Text(audioManager.syncStatus.subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
            
            // If limited by iOS, provide quick guide link
            if audioManager.syncStatus.isLimited {
                Button(action: {
                    audioManager.showingAudioSharingGuide = true
                    HapticManager.lightImpact()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Learn why iOS limits multi-Bluetooth routing")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Theme.accentAmber)
                    .padding(.top, 4)
                }
            }
        }
        .glassCard(
            cornerRadius: 18,
            strokeColor: audioManager.syncStatus.badgeColor.opacity(0.35),
            padding: 16
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Now Playing Card
    private var nowPlayingCard: some View {
        VStack(spacing: 14) {
            if let track = audioManager.currentTrack {
                HStack(spacing: 14) {
                    // Album Artwork
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: track.accentGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .neonGlow(color: track.accentGradient.first ?? Theme.accentCyan, radius: 8, opacity: audioManager.isPlaying ? 0.4 : 0.1)
                        
                        Image(systemName: track.artworkSystemName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Track Title & Artist
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                        
                        Text(track.formatDescription)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.accentCyan)
                    }
                    
                    Spacer()
                    
                    // Mini Play / Pause Button
                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Theme.cyanBlueGradient)
                                .frame(width: 44, height: 44)
                                .neonGlow(color: Theme.accentCyan, radius: audioManager.isPlaying ? 10 : 0)
                            
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: audioManager.isPlaying ? 0 : 1)
                        }
                    }
                }
                
                // Progress Scrubber Bar
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 5)
                            
                            let progress = audioManager.duration > 0 ? audioManager.currentTime / audioManager.duration : 0
                            Capsule()
                                .fill(Theme.cyanBlueGradient)
                                .frame(width: geo.size.width * CGFloat(max(0, min(1, progress))), height: 5)
                        }
                    }
                    .frame(height: 5)
                    
                    HStack {
                        Text(audioManager.currentTime.formattedMinutesSeconds)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.textTertiary)
                        
                        Spacer()
                        
                        Text(audioManager.duration.formattedMinutesSeconds)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                
                // Open Full Player Button
                Button(action: {
                    showingPlayerSheet = true
                    HapticManager.lightImpact()
                }) {
                    HStack {
                        Text("Open Full Player & Latency Lab")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Theme.accentCyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.accentCyan.opacity(0.08))
                    )
                }
            }
        }
        .glassCard(cornerRadius: 20, strokeColor: Theme.cardBorder, padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Device Summary Section
    private var deviceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DETECTED AUDIO ROUTES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(audioManager.routeInfo.outputs.count) Active")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentCyan)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                if audioManager.routeInfo.outputs.isEmpty {
                    HStack {
                        Image(systemName: "speaker.slash.fill")
                            .foregroundColor(Theme.accentAmber)
                        Text("No active audio route detected")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 14)
                } else {
                    ForEach(audioManager.routeInfo.outputs) { device in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(device.isBluetooth ? Theme.accentPurple.opacity(0.25) : Theme.accentCyan.opacity(0.25))
                                    .frame(width: 42, height: 42)
                                
                                Image(systemName: device.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(device.isBluetooth ? Theme.accentPurple : Theme.accentCyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(device.portTypeDescription)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("CONNECTED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.accentGreen)
                                
                                Text(device.latencyMs.formattedLatencyMs)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                        .glassCard(cornerRadius: 14, strokeColor: Theme.cardBorder, padding: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Apple Audio Sharing Callout
    private var audioSharingCalloutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "airpodspro")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Theme.accentCyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dual Audio on iPhone 11")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Official Apple Audio Sharing")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    audioManager.showingAudioSharingGuide = true
                    HapticManager.mediumImpact()
                }) {
                    Text("Open Guide")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.buttonGradient)
                        .clipShape(Capsule())
                }
            }
            
            Text("Want to share audio with two pairs of AirPods or Beats? Learn how iOS routes dual Bluetooth streams natively via Control Center.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
        }
        .glassCard(cornerRadius: 18, strokeColor: Theme.accentIndigo.opacity(0.3), padding: 16)
        .padding(.horizontal, 16)
    }
}
