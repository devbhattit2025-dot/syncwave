//
//  DevicesView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI
import AVFoundation

/// Audio Route Manager and device detection view displaying active ports, hardware specs, and iOS routing capabilities.
struct DevicesView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var showingRoutePicker: Bool = false
    @State private var selectedDeviceForDetail: AudioDevice?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Active Hardware Summary Card
                activeRouteSummaryHero
                
                // Honest iOS Limitation Alert Banner
                limitationsBanner
                
                // Detected Output Ports
                outputDevicesList
                
                // Detected Input Ports (Microphone / External)
                inputDevicesList
                
                // Hardware Audio Subsystem Specs
                hardwareMetricsCard
                
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
                Text("AUDIO ROUTES")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Hardware & Route Diagnostics")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                audioManager.routeManager.refreshRoutes(reasonDescription: "User Manual Scan")
                HapticManager.lightImpact()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Scan")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.accentCyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.accentCyan.opacity(0.12)))
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Active Route Hero
    private var activeRouteSummaryHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.cyanBlueGradient)
                        .frame(width: 50, height: 50)
                        .neonGlow(color: Theme.accentCyan, radius: 10)
                    
                    Image(systemName: audioManager.routeInfo.outputs.first?.iconName ?? "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRIMARY ACTIVE OUTPUT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accentCyan)
                        .tracking(1.0)
                    
                    Text(audioManager.routeInfo.primaryOutputName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(audioManager.routeInfo.primaryPortType)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                AVRoutePickerRepresentable()
                    .frame(width: 36, height: 36)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle")
                        .foregroundColor(Theme.textTertiary)
                    Text("Latency:")
                        .foregroundColor(Theme.textSecondary)
                    Text(audioManager.routeInfo.outputLatency.formattedLatencyMs)
                        .foregroundColor(Theme.accentCyan)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .font(.system(size: 12))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .foregroundColor(Theme.textTertiary)
                    Text("Rate:")
                        .foregroundColor(Theme.textSecondary)
                    Text(audioManager.routeInfo.hardwareSampleRate.formattedSampleRateKhz)
                        .foregroundColor(Theme.accentPurple)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .font(.system(size: 12))
            }
        }
        .glassCard(cornerRadius: 20, strokeColor: Theme.accentCyan.opacity(0.35), padding: 18)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Honest Limitations Banner
    private var limitationsBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.accentIndigo)
                Text("Apple iOS Routing Architecture")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("iOS manages Bluetooth A2DP audio routing at the system kernel level. Public third-party APIs can output to only one Bluetooth destination at a time. To stream to two pairs of AirPods/Beats simultaneously, use Apple's native Audio Sharing feature.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
            
            Button(action: {
                audioManager.showingAudioSharingGuide = true
                HapticManager.lightImpact()
            }) {
                HStack(spacing: 4) {
                    Text("Open Audio Sharing Guide")
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(Theme.accentCyan)
            }
        }
        .glassCard(cornerRadius: 16, strokeColor: Theme.accentIndigo.opacity(0.25), padding: 14)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Output Devices List
    private var outputDevicesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DETECTED OUTPUT PORTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(audioManager.routeInfo.outputs.count) Port(s)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(audioManager.routeInfo.outputs) { device in
                    DeviceDetailCard(device: device)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Input Devices List
    private var inputDevicesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AVAILABLE INPUT PORTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(audioManager.routeInfo.inputs.count) Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if audioManager.routeInfo.inputs.isEmpty {
                    HStack {
                        Image(systemName: "mic.slash")
                            .foregroundColor(Theme.textTertiary)
                        Text("No active recording inputs requested (Battery optimized)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 14)
                } else {
                    ForEach(audioManager.routeInfo.inputs) { device in
                        DeviceDetailCard(device: device)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Hardware Metrics Card
    private var hardwareMetricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUDIO ENGINE HARDWARE METRICS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textTertiary)
                .tracking(1.0)
            
            VStack(spacing: 8) {
                MetricRow(title: "Session Category", value: audioManager.routeInfo.category)
                MetricRow(title: "Hardware Sample Rate", value: "\(Int(audioManager.routeInfo.hardwareSampleRate)) Hz")
                MetricRow(title: "IO Buffer Latency", value: audioManager.routeInfo.ioBufferDuration.formattedLatencyMs)
                MetricRow(title: "Output Route Latency", value: audioManager.routeInfo.outputLatency.formattedLatencyMs)
                MetricRow(title: "MultiRoute Category", value: audioManager.sessionManager.isMultiRouteActive ? "Enabled" : "Disabled")
                MetricRow(title: "Last Route Event", value: audioManager.routeInfo.lastChangeReason)
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Device Detail Card Component
struct DeviceDetailCard: View {
    let device: AudioDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(device.isBluetooth ? Theme.accentPurple.opacity(0.2) : Theme.accentCyan.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: device.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(device.isBluetooth ? Theme.accentPurple : Theme.accentCyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(device.portTypeDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.accentGreen.opacity(0.15)))
                    
                    Text("\(device.channelCount) Channels")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            
            Divider().background(Color.white.opacity(0.06))
            
            HStack {
                HStack(spacing: 4) {
                    Text("Port UID:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Text(device.id)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Latency:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Text(device.latencyMs.formattedLatencyMs)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.accentCyan)
                }
            }
        }
        .glassCard(cornerRadius: 16, strokeColor: Theme.cardBorder, padding: 14)
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
