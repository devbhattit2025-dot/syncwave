//
//  MainTabView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Main container view featuring custom futuristic glassmorphic navigation.
struct MainTabView: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var selectedTab: TabItem = .home
    @State private var showingFullPlayer: Bool = false
    
    enum TabItem: String, CaseIterable {
        case home = "Player"
        case routes = "Routes"
        case syncLab = "Sync Lab"
        case settings = "Settings"
        
        var iconName: String {
            switch self {
            case .home: return "waveform.circle.fill"
            case .routes: return "point.3.connected.trianglepath.dotted"
            case .syncLab: return "slider.horizontal.3"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .home:
                    HomeView(audioManager: audioManager)
                case .routes:
                    DevicesView(audioManager: audioManager)
                case .syncLab:
                    SyncLabView(audioManager: audioManager)
                case .settings:
                    SettingsView(audioManager: audioManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Floating Bar Stack (Mini Player + Tab Bar)
            VStack(spacing: 8) {
                // Floating Mini-Player (when not on Home tab or to provide persistent quick access)
                if selectedTab != .home && audioManager.currentTrack != nil {
                    floatingMiniPlayer
                }
                
                // Futuristic Glassmorphic Tab Bar
                customTabBar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerView(audioManager: audioManager)
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    HapticManager.lightImpact()
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Theme.accentCyan.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                    .neonGlow(color: Theme.accentCyan, radius: 8)
                            }
                            
                            Image(systemName: tab.iconName)
                                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Theme.accentCyan : Theme.textTertiary)
                        }
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.cardBackgroundUltra)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Floating Mini Player
    private var floatingMiniPlayer: some View {
        Button(action: {
            showingFullPlayer = true
            HapticManager.lightImpact()
        }) {
            HStack(spacing: 12) {
                // Mini Art
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: audioManager.currentTrack?.accentGradient ?? [Theme.accentCyan, Theme.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: audioManager.currentTrack?.artworkSystemName ?? "waveform")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioManager.currentTrack?.title ?? "")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(audioManager.routeInfo.primaryOutputName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.accentCyan)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Play / Pause
                Button(action: {
                    audioManager.togglePlayPause()
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.cardBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.accentCyan.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
        }
    }
}
