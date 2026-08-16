//
//  Theme.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Central design system for SyncWave featuring futuristic dark glassmorphism.
enum Theme {
    // MARK: - Color Palette
    
    /// Deep cosmic dark backgrounds
    static let backgroundPrimary = Color(hex: "090C10")
    static let backgroundSecondary = Color(hex: "0F141C")
    static let backgroundTertiary = Color(hex: "171E2B")
    
    /// Glass card surfaces
    static let cardBackground = Color(hex: "131A26").opacity(0.75)
    static let cardBackgroundUltra = Color(hex: "182233").opacity(0.85)
    static let cardBorder = Color.white.opacity(0.12)
    static let cardBorderHover = Color.cyan.opacity(0.35)
    
    /// Vibrant neon & accent colors
    static let accentCyan = Color(hex: "06B6D4")
    static let accentBlue = Color(hex: "3B82F6")
    static let accentIndigo = Color(hex: "6366F1")
    static let accentPurple = Color(hex: "8B5CF6")
    static let accentViolet = Color(hex: "A855F7")
    static let accentPink = Color(hex: "EC4899")
    static let accentGreen = Color(hex: "10B981")
    static let accentAmber = Color(hex: "F59E0B")
    static let accentRose = Color(hex: "F43F5E")
    
    /// Neutral text shades
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "94A3B8")
    static let textTertiary = Color(hex: "64748B")
    static let textMuted = Color(hex: "475569")
    
    // MARK: - Gradients
    
    static let neonWaveGradient = LinearGradient(
        colors: [accentCyan, accentBlue, accentPurple, accentViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let syncActiveGradient = LinearGradient(
        colors: [accentCyan, accentGreen],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let syncLimitedGradient = LinearGradient(
        colors: [accentAmber, accentRose],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [backgroundPrimary, backgroundSecondary, backgroundTertiary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGlowGradient = RadialGradient(
        colors: [accentCyan.opacity(0.15), Color.clear],
        center: .center,
        startRadius: 10,
        endRadius: 180
    )
    
    static let buttonGradient = LinearGradient(
        colors: [accentIndigo, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cyanBlueGradient = LinearGradient(
        colors: [accentCyan, accentBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var strokeColor: Color = Theme.cardBorder
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Theme.cardBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 10
    var opacity: Double = 0.5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, strokeColor: Color = Theme.cardBorder, padding: CGFloat = 16) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor, padding: padding))
    }
    
    func neonGlow(color: Color = Theme.accentCyan, radius: CGFloat = 10, opacity: Double = 0.5) -> some View {
        self.modifier(NeonGlowModifier(color: color, radius: radius, opacity: opacity))
    }
    
    func syncBackground() -> some View {
        self.background(
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                // Ambient subtle glow orbs
                GeometryReader { geo in
                    Circle()
                        .fill(Theme.accentIndigo.opacity(0.12))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(x: -80, y: -60)
                    
                    Circle()
                        .fill(Theme.accentCyan.opacity(0.09))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .offset(x: geo.size.width - 160, y: geo.size.height * 0.4)
                }
                .ignoresSafeArea()
            }
        )
    }
}
