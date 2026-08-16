//
//  TechnicalLimitationsView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Architectural breakdown explaining why third-party iOS apps cannot arbitrarily hijack or duplicate system audio to multiple Bluetooth devices.
struct TechnicalLimitationsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Dismiss Bar
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
                    
                    Text("iOS AUDIO ARCHITECTURE")
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
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 38))
                                .foregroundColor(Theme.accentAmber)
                                .neonGlow(color: Theme.accentAmber, radius: 10)
                            
                            Text("Technical Reality on iOS")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Public APIs vs. Private System Daemons")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.top, 10)
                        
                        // Limitation 1: System-wide Audio Interception
                        limitationSection(
                            title: "1. No System-Wide Audio Interception",
                            icon: "waveform.badge.magnifyingglass",
                            content: "On iOS, application sandboxing prevents third-party apps from capturing or intercepting audio originating from other apps (such as Apple Music, Spotify, or YouTube). Apps can only process and output audio generated or imported directly inside their own sandbox."
                        )
                        
                        // Limitation 2: Single Bluetooth A2DP Endpoint
                        limitationSection(
                            title: "2. Single Bluetooth A2DP Endpoint",
                            icon: "antenna.radiowaves.left.and.right.slash",
                            content: "Apple's CoreAudio / AVAudioSession public API exposes only a single active Bluetooth A2DP output port to non-system applications. Even if multiple Bluetooth devices are paired in iOS Settings, public routing APIs direct audio to only one device at a time."
                        )
                        
                        // Limitation 3: MultiRoute Boundaries
                        limitationSection(
                            title: "3. AVAudioSession Category MultiRoute",
                            icon: "point.3.connected.trianglepath.dotted",
                            content: "The `AVAudioSessionCategoryMultiRoute` category exists in iOS to allow simultaneous output across distinct physical hardware buses (such as a USB audio interface combined with the built-in headphone jack). Apple's documentation explicitly clarifies that MultiRoute does not permit multiple Bluetooth A2DP output endpoints."
                        )
                        
                        // Limitation 4: Native Apple Audio Sharing
                        limitationSection(
                            title: "4. How Apple Audio Sharing Actually Works",
                            icon: "applelogo",
                            content: "Apple's native 'Audio Sharing' is implemented deep within the SpringBoard system daemon and Bluetooth firmware for Apple H1/H2/W1 chipsets (AirPods & Beats). It is not exposed to developers as a public framework, but is accessible to all users through Control Center."
                        )
                        
                        // What SyncWave Provides
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.accentGreen)
                                Text("What SyncWave Delivers")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                            Text("• High-precision in-app audio engine with custom DSP\n• Real-time FFT spectrum & stereo VU visualizers\n• Live AVAudioSession route change detection & device metrics\n• Precision latency compensation & acoustic sync calibration\n• 100% compliant with public Apple APIs for safe Sideloadly installation")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(4)
                        }
                        .glassCard(cornerRadius: 18, strokeColor: Theme.accentGreen.opacity(0.35), padding: 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func limitationSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Theme.accentCyan)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(3)
        }
        .glassCard(cornerRadius: 16, padding: 14)
    }
}
