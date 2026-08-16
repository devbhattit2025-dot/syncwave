//
//  SyncLabView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// High-precision synchronization lab featuring latency calibration, MultiRoute hardware probe, and acoustic sync pulse.
struct SyncLabView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Real-Time Total Latency Gauge
                latencyGaugeCard
                
                // Manual Sync Offset Slider & Metronome
                delayCalibrationCard
                
                // MultiRoute Capability Probe Tester
                multiRouteProbeCard
                
                // Presets & Sync Quick Actions
                syncPresetsCard
                
                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .syncBackground()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SYNC LAB")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Latency Alignment & MultiRoute Diagnostics")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            GlowingBadge(
                title: audioManager.synchronizer.isMetronomeActive ? "Pulse Active" : "Calibrated",
                icon: "metronome.fill",
                color: audioManager.synchronizer.isMetronomeActive ? Theme.accentAmber : Theme.accentCyan,
                isPulsing: audioManager.synchronizer.isMetronomeActive
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Latency Gauge Card
    private var latencyGaugeCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ESTIMATED SIGNAL DELAY")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("CoreAudio Clock")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentCyan)
            }
            
            // Large Hero Metric
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", audioManager.synchronizer.totalEffectiveLatencyMs))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.neonWaveGradient)
                
                Text("ms")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Latency Breakdown Bars
            VStack(spacing: 8) {
                LatencyBarRow(
                    title: "Hardware I/O Buffer",
                    valueMs: audioManager.synchronizer.hardwareBufferLatencyMs,
                    color: Theme.accentCyan
                )
                
                LatencyBarRow(
                    title: "Output Route Driver",
                    valueMs: audioManager.synchronizer.routeOutputLatencyMs,
                    color: Theme.accentPurple
                )
                
                LatencyBarRow(
                    title: "User Compensation Delay",
                    valueMs: audioManager.synchronizer.userDelayOffsetMs,
                    color: Theme.accentPink
                )
            }
        }
        .glassCard(cornerRadius: 20, strokeColor: Theme.accentCyan.opacity(0.3), padding: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Delay Calibration Card
    private var delayCalibrationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MANUAL DELAY COMPENSATION")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.0)
                    
                    Text("Align playback timing with external Bluetooth/AirPlay speakers")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text(String(format: "+%.0f ms", audioManager.synchronizer.userDelayOffsetMs))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentCyan)
            }
            
            Slider(
                value: Binding(
                    get: { audioManager.synchronizer.userDelayOffsetMs },
                    set: { audioManager.synchronizer.userDelayOffsetMs = $0 }
                ),
                in: 0...400,
                step: 1
            )
            .accentColor(Theme.accentIndigo)
            
            HStack(spacing: 12) {
                // Sync Metronome Pulse Button
                Button(action: {
                    audioManager.synchronizer.toggleSyncPulse()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: audioManager.synchronizer.isMetronomeActive ? "stop.fill" : "metronome")
                        Text(audioManager.synchronizer.isMetronomeActive ? "Stop Pulse" : "Acoustic Pulse")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(audioManager.synchronizer.isMetronomeActive ? Theme.accentAmber : Theme.accentIndigo)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Button("Reset (0ms)") {
                    audioManager.synchronizer.resetDelayOffset()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.accentRose)
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - MultiRoute Probe Card
    private var multiRouteProbeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AVAudioSession MULTIROUTE PROBE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.0)
                    
                    Text("Test iOS multi-port hardware capabilities")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text(audioManager.sessionManager.isMultiRouteActive ? "ACTIVE" : "STANDBY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(audioManager.sessionManager.isMultiRouteActive ? Theme.accentGreen : Theme.accentTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            
            Text("Apple's `AVAudioSessionCategoryMultiRoute` allows simultaneous output only to distinct physical ports (e.g. USB DAC + Built-in Headphone Jack). It is technically not permitted for multiple Bluetooth A2DP streams by Apple's public audio subsystem.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
            
            HStack(spacing: 12) {
                Button(action: {
                    audioManager.probeMultiRoute()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.badge.a.fill")
                        Text("Probe MultiRoute")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.buttonGradient)
                    .clipShape(Capsule())
                }
                
                if audioManager.sessionManager.isMultiRouteActive {
                    Button("Revert to Playback") {
                        audioManager.revertToStandardSession()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accentAmber)
                }
            }
            
            if !audioManager.multiRouteProbeLog.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DIAGNOSTIC LOG:")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentCyan)
                    
                    Text(audioManager.multiRouteProbeLog)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4)))
            }
        }
        .glassCard(cornerRadius: 18, strokeColor: Theme.accentPurple.opacity(0.3), padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Presets Card
    private var syncPresetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HARDWARE LATENCY PRESETS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textTertiary)
                .tracking(1.0)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SyncPreset.allCases) { preset in
                    Button(action: {
                        audioManager.synchronizer.applyPreset(preset: preset)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            
                            Text(String(format: "+%.0f ms", preset.delayMs))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.accentCyan)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Latency Bar Row
struct LatencyBarRow: View {
    let title: String
    let valueMs: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Text(valueMs.formattedLatencyMs)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    
                    let ratio = min(1.0, valueMs / 300.0)
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(ratio)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}
