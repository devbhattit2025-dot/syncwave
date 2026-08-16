//
//  GlowingBadge.swift
//  SyncWave
//
//  Created for SyncWave - Synchronized Audio for iOS (iPhone 11)
//

import SwiftUI
import AVKit

/// A futuristic glowing pill badge displaying connection or sync status
struct GlowingBadge: View {
    let title: String
    let icon: String
    let color: Color
    var isPulsing: Bool = false
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? pulseScale : 1.0)
                .opacity(isPulsing ? pulseOpacity : 1.0)
                .onAppear {
                    if isPulsing {
                        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.4
                            pulseOpacity = 1.0
                        }
                    }
                }
            
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 0)
    }
}

/// SwiftUI wrapper for system AVRoutePickerView (AirPlay / Bluetooth system route chooser)
struct AVRoutePickerRepresentable: UIViewRepresentable {
    var tintColor: UIColor = UIColor(red: 0.02, green: 0.71, blue: 0.83, alpha: 1.0)
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = tintColor
        picker.activeTintColor = UIColor(red: 0.54, green: 0.36, blue: 0.96, alpha: 1.0)
        picker.prioritizesVideoDevices = false
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
    }
}
