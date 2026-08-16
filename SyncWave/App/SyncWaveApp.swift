//
//  SyncWaveApp.swift
//  SyncWave
//
//  Created for SyncWave - Cross-Platform Synchronized Audio Mesh (iOS & Android)
//

import SwiftUI
import AVFoundation

@main
struct SyncWaveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 10/255, green: 15/255, blue: 30/255)
                    .ignoresSafeArea()
                
                MeshWebView()
                    .ignoresSafeArea()
            }
            .preferredColorScheme(.dark)
            .onAppear {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
                    try session.setActive(true)
                } catch {
                    print("Error setting audio session: \(error)")
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.beginReceivingRemoteControlEvents()
        return true
    }
}
