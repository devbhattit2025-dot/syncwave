//
//  AudioSharingGuideView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Comprehensive interactive guide explaining Apple's official iOS Audio Sharing for dual Bluetooth headphones.
struct AudioSharingGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: Int = 0
    
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
                    
                    Text("APPLE AUDIO SHARING GUIDE")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1.0)
                    
                    Spacer()
                    
                    // Balancing dummy view
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Explanation Card
                        heroExplanationCard
                        
                        // Interactive Step-by-Step Walkthrough
                        stepsWalkthroughSection
                        
                        // Hardware Compatibility Matrix
                        compatibleDevicesCard
                        
                        // Technical Reality on iOS
                        technicalNoteCard
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
    }
    
    // MARK: - Hero Explanation Card
    private var heroExplanationCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.buttonGradient)
                    .frame(width: 64, height: 64)
                    .neonGlow(color: Theme.accentIndigo, radius: 12)
                
                Image(systemName: "airpodspro")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Native Dual Audio on iPhone 11")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Apple handles dual Bluetooth headphone audio streaming exclusively inside the iOS kernel. Third-party apps cannot override this, but you can effortlessly stream to two devices using Apple's official system feature.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .glassCard(cornerRadius: 24, strokeColor: Theme.accentIndigo.opacity(0.4), padding: 20)
    }
    
    // MARK: - Step-by-Step Walkthrough
    private var stepsWalkthroughSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOW TO ENABLE DUAL AUDIO")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textTertiary)
                .tracking(1.0)
            
            VStack(spacing: 12) {
                StepCard(
                    stepNumber: "1",
                    title: "Open Control Center",
                    description: "Swipe down from the top-right corner of your iPhone 11 screen.",
                    iconName: "hand.draw.fill",
                    accentColor: Theme.accentCyan
                )
                
                StepCard(
                    stepNumber: "2",
                    title: "Tap the AirPlay Icon",
                    description: "In the Now Playing control tile, tap the circular AirPlay / audio route icon.",
                    iconName: "airplayaudio",
                    accentColor: Theme.accentBlue
                )
                
                StepCard(
                    stepNumber: "3",
                    title: "Select 'Share Audio...'",
                    description: "Under your currently connected headphones, tap the 'Share Audio' option.",
                    iconName: "person.2.wave.2.fill",
                    accentColor: Theme.accentPurple
                )
                
                StepCard(
                    stepNumber: "4",
                    title: "Bring Second Headphones Close",
                    description: "Hold the second pair of AirPods (in their open case) or Beats close to your iPhone and follow the on-screen prompt.",
                    iconName: "checkmark.circle.fill",
                    accentColor: Theme.accentGreen
                )
            }
        }
    }
    
    // MARK: - Compatible Devices Card
    private var compatibleDevicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Theme.accentGreen)
                Text("COMPATIBLE HEADPHONES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(1.0)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DeviceBullet(name: "AirPods Pro (1st & 2nd Gen)")
                DeviceBullet(name: "AirPods (1st, 2nd, 3rd & 4th Gen)")
                DeviceBullet(name: "AirPods Max")
                DeviceBullet(name: "Beats Fit Pro / Powerbeats Pro")
                DeviceBullet(name: "Beats Studio Pro / Solo Pro / Solo 4")
                DeviceBullet(name: "Beats Flex / BeatsX")
            }
        }
        .glassCard(cornerRadius: 18, strokeColor: Theme.accentGreen.opacity(0.3), padding: 16)
    }
    
    // MARK: - Technical Note Card
    private var technicalNoteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Theme.accentCyan)
                Text("SyncWave Architectural Standard")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("SyncWave respects Apple's developer guidelines by using only public, App Store and Sideloadly compliant APIs. We do not use private frameworks, DRM hacks, or jailbreak daemons.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
        }
        .glassCard(cornerRadius: 16, padding: 14)
    }
}

// MARK: - Step Card Component
struct StepCard: View {
    let stepNumber: String
    let title: String
    let description: String
    let iconName: String
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text(stepNumber)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                }
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .glassCard(cornerRadius: 16, padding: 12)
    }
}

// MARK: - Device Bullet Component
struct DeviceBullet: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.accentGreen)
            
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
