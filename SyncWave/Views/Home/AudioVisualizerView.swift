//
//  AudioVisualizerView.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI

/// Futuristic real-time audio visualization rendering FFT frequency bars, neon waveforms, and stereo VU meters.
struct AudioVisualizerView: View {
    @ObservedObject var audioManager: AudioManager
    
    @State private var visualizerMode: VisualizerMode = .spectrum
    @State private var rotationAngle: Double = 0
    
    enum VisualizerMode: String, CaseIterable {
        case spectrum = "Spectrum"
        case circular = "Cyber Orb"
        case waveform = "Waveform"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Mode Selector Pill
            HStack(spacing: 8) {
                ForEach(VisualizerMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            visualizerMode = mode
                        }
                        HapticManager.lightImpact()
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(visualizerMode == mode ? Theme.textPrimary : Theme.textTertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(visualizerMode == mode ? Theme.accentCyan.opacity(0.3) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(visualizerMode == mode ? Theme.accentCyan.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
                
                // Stereo VU Meters
                HStack(spacing: 4) {
                    Text("L")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.textTertiary)
                    VUMeterBar(level: audioManager.isPlaying ? audioManager.leftMeterLevel : 0.05)
                    
                    Text("R")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.textTertiary)
                    VUMeterBar(level: audioManager.isPlaying ? audioManager.rightMeterLevel : 0.05)
                }
            }
            .padding(.horizontal, 16)
            
            // Visualizer Canvas
            ZStack {
                // Background Ambient Glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                
                switch visualizerMode {
                case .spectrum:
                    SpectrumBarsView(bands: audioManager.spectrumBands, isPlaying: audioManager.isPlaying)
                case .circular:
                    CircularOrbView(bands: audioManager.spectrumBands, isPlaying: audioManager.isPlaying)
                case .waveform:
                    NeonWaveformView(bands: audioManager.spectrumBands, isPlaying: audioManager.isPlaying)
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 1. Frequency Spectrum Bars
struct SpectrumBarsView: View {
    let bands: [Float]
    let isPlaying: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<bands.count, id: \.self) { index in
                let value = CGFloat(bands[index])
                let height = max(6.0, value * 130.0)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.accentCyan,
                                Theme.accentIndigo,
                                Theme.accentPurple,
                                Theme.accentPink
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: height)
                    .shadow(color: Theme.accentCyan.opacity(isPlaying ? 0.4 : 0.1), radius: 4, y: 0)
                    .animation(.easeOut(duration: 0.08), value: bands[index])
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .padding(.top, 10)
    }
}

// MARK: - 2. Circular Cyber Orb
struct CircularOrbView: View {
    let bands: [Float]
    let isPlaying: Bool
    
    @State private var spinAngle: Double = 0
    
    var body: some View {
        let avgLevel = CGFloat(bands.reduce(0, +) / Float(max(1, bands.count)))
        let scale = 1.0 + (isPlaying ? avgLevel * 0.4 : 0.0)
        
        ZStack {
            // Pulsing Outer Rings
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Theme.accentCyan.opacity(0.6), Theme.accentPurple.opacity(0.3), Theme.accentPink.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 60 + CGFloat(ring * 32) * scale, height: 60 + CGFloat(ring * 32) * scale)
                    .rotationEffect(.degrees(spinAngle * (ring % 2 == 0 ? 1 : -1)))
                    .blur(radius: isPlaying ? 1 : 0)
            }
            
            // Core Glowing Sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accentCyan, Theme.accentIndigo, Color.black],
                        center: .center,
                        startRadius: 5,
                        endRadius: 45
                    )
                )
                .frame(width: 70 * scale, height: 70 * scale)
                .neonGlow(color: Theme.accentCyan, radius: 16)
            
            // Radial Spoke Particles
            ForEach(0..<16) { i in
                let bandIdx = i % bands.count
                let val = CGFloat(bands[bandIdx])
                
                Capsule()
                    .fill(Theme.accentCyan.opacity(0.8))
                    .frame(width: 3, height: 10 + val * 28)
                    .offset(y: -48 - val * 12)
                    .rotationEffect(.degrees(Double(i) * (360.0 / 16.0) + spinAngle))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        }
    }
}

// MARK: - 3. Neon Continuous Waveform
struct NeonWaveformView: View {
    let bands: [Float]
    let isPlaying: Bool
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                let width = size.width
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))
                
                let step = width / CGFloat(max(1, bands.count - 1))
                for (i, band) in bands.enumerated() {
                    let x = CGFloat(i) * step
                    let amp = CGFloat(band) * (midY - 15)
                    let sign: CGFloat = (i % 2 == 0) ? -1 : 1
                    let y = midY + (isPlaying ? sign * amp : 0)
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        let prevX = CGFloat(i - 1) * step
                        let prevBand = CGFloat(bands[i - 1])
                        let prevY = midY + (isPlaying ? ((i - 1) % 2 == 0 ? -1 : 1) * prevBand * (midY - 15) : 0)
                        let controlX = (prevX + x) / 2
                        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: controlX, y: prevY), control2: CGPoint(x: controlX, y: y))
                    }
                }
                
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Theme.accentCyan, Theme.accentBlue, Theme.accentPurple, Theme.accentPink]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: width, y: 0)
                    ),
                    lineWidth: 3.5
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Stereo VU Meter Bar
struct VUMeterBar: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accentGreen, Theme.accentAmber, Theme.accentRose],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: geo.size.height * CGFloat(max(0.05, min(1.0, level))))
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .frame(width: 5, height: 22)
    }
}
