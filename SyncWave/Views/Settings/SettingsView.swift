//
//  SettingsView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Settings view providing audio buffer adjustments, sample rate configuration, technical whitepaper, and Sideloadly guide.
struct SettingsView: View {
    @ObservedObject var audioManager: AudioManager
    
    @AppStorage("preferredBufferSize") private var preferredBufferSize: Double = 0.005
    @AppStorage("preferredSampleRate") private var preferredSampleRate: Double = 44100.0
    @AppStorage("autoDetectRoutes") private var autoDetectRoutes: Bool = true
    
    @State private var showingLimitations: Bool = false
    @State private var showingSideloadGuide: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Audio Engine Configuration Card
                audioEngineConfigCard
                
                // Hardware & Category Modes
                audioCategoryCard
                
                // Architecture & Documentation Links
                documentationCard
                
                // Sideloadly & Signing Info
                sideloadingCard
                
                // About SyncWave Card
                aboutCard
                
                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .syncBackground()
        .sheet(isPresented: $showingLimitations) {
            TechnicalLimitationsView()
        }
        .sheet(isPresented: $showingSideloadGuide) {
            SideloadingGuideView()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SETTINGS")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Audio Pipeline & iOS Configuration")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Audio Engine Configuration
    private var audioEngineConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "slider.horizontal.2.square.on.square")
                    .foregroundColor(Theme.accentCyan)
                Text("AUDIO ENGINE BUFFERS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
            }
            
            VStack(spacing: 12) {
                // Buffer Duration Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target I/O Buffer Latency")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Picker("Buffer Duration", selection: $preferredBufferSize) {
                        Text("5 ms (Ultra Low)").tag(0.005)
                        Text("10 ms (Balanced)").tag(0.010)
                        Text("23 ms (Power Efficient)").tag(0.023)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preferredBufferSize) { newValue in
                        _ = audioManager.sessionManager.configurePlaybackSession(preferredBufferDuration: newValue, preferredSampleRate: preferredSampleRate)
                        audioManager.routeManager.refreshRoutes(reasonDescription: "Buffer Changed")
                        HapticManager.selectionChanged()
                    }
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                // Sample Rate Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preferred Audio Sample Rate")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Picker("Sample Rate", selection: $preferredSampleRate) {
                        Text("44.1 kHz (CD Standard)").tag(44100.0)
                        Text("48.0 kHz (Pro Audio)").tag(48000.0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preferredSampleRate) { newValue in
                        _ = audioManager.sessionManager.configurePlaybackSession(preferredBufferDuration: preferredBufferSize, preferredSampleRate: newValue)
                        audioManager.routeManager.refreshRoutes(reasonDescription: "Sample Rate Changed")
                        HapticManager.selectionChanged()
                    }
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Audio Category Card
    private var audioCategoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundColor(Theme.accentPurple)
                Text("SESSION CATEGORY CONTROL")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Session Category")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(audioManager.sessionManager.currentCategoryName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.accentCyan)
                }
                
                Spacer()
                
                Button(action: {
                    if audioManager.sessionManager.isMultiRouteActive {
                        audioManager.revertToStandardSession()
                    } else {
                        audioManager.probeMultiRoute()
                    }
                }) {
                    Text(audioManager.sessionManager.isMultiRouteActive ? "Revert to Playback" : "Test MultiRoute")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(audioManager.sessionManager.isMultiRouteActive ? Theme.accentAmber : Theme.accentPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Documentation Card
    private var documentationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DOCUMENTATION & GUIDES")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textTertiary)
                .tracking(1.0)
            
            VStack(spacing: 8) {
                Button(action: {
                    showingLimitations = true
                    HapticManager.lightImpact()
                }) {
                    SettingsRow(
                        title: "iOS Limitations & Public APIs",
                        subtitle: "Detailed breakdown of Bluetooth routing restrictions",
                        icon: "lock.shield.fill",
                        color: Theme.accentAmber
                    )
                }
                
                Button(action: {
                    audioManager.showingAudioSharingGuide = true
                    HapticManager.lightImpact()
                }) {
                    SettingsRow(
                        title: "Apple Audio Sharing Guide",
                        subtitle: "Native dual headphone streaming walkthrough",
                        icon: "airpodspro",
                        color: Theme.accentCyan
                    )
                }
                
                Button(action: {
                    showingSideloadGuide = true
                    HapticManager.lightImpact()
                }) {
                    SettingsRow(
                        title: "Sideloadly & Xcode Installation",
                        subtitle: "How to build & install on iPhone 11",
                        icon: "shippingbox.fill",
                        color: Theme.accentIndigo
                    )
                }
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Sideloading Card
    private var sideloadingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Theme.accentGreen)
                Text("Sideloadly Compatibility")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("SyncWave uses 100% public Apple APIs with no private entitlements or jailbreak dependencies. It can be signed and installed on any iPhone 11 using a free Apple ID via Sideloadly or Xcode.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
        }
        .glassCard(cornerRadius: 16, strokeColor: Theme.accentGreen.opacity(0.3), padding: 14)
        .padding(.horizontal, 16)
    }
    
    // MARK: - About Card
    private var aboutCard: some View {
        VStack(spacing: 6) {
            Text("SyncWave v1.0")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            Text("High-Precision Synchronized Audio for iPhone 11")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            
            Text("Built with Swift & SwiftUI • CoreAudio DSP")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Sideloading Guide Sheet
struct SideloadingGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        HapticManager.lightImpact()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("INSTALLATION GUIDE")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.0)
                    
                    Spacer()
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Installing via Sideloadly on iPhone 11")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Step 1: Download & Install Sideloadly on your PC/Mac.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentCyan)
                        
                        Text("Step 2: Connect your iPhone 11 via Lightning to USB cable.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentCyan)
                        
                        Text("Step 3: Drag the compiled `SyncWave.ipa` into Sideloadly.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentCyan)
                        
                        Text("Step 4: Enter your Apple ID (used for 7-day free developer signing).")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentCyan)
                        
                        Text("Step 5: Click Start. Once installed on iPhone 11, navigate to Settings > General > VPN & Device Management and trust your developer certificate.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.accentGreen)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
        }
    }
}
